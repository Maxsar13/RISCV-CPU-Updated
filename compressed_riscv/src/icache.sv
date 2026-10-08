// 2-way set-associative L1 instruction cache
// TODO: cache miss behavior not yet implemented
module icache #(
    parameter BYPASS     = 1'b1, //tmp parameter until dmc gets implemented. right now we just bypass bram behavior
    parameter NUM_SETS   = 128,  // 2 ways x 128 sets x 8B/line = 2KB total
    parameter INDEX_BITS = $clog2(NUM_SETS),
    parameter TAG_BITS   = 32 - INDEX_BITS - 3
)(
    input  logic        clk,
    input  logic        rst,

    // CPU-side instruction fetch interface.
    input  logic        cpu_req_valid,
    input  logic [31:0] cpu_req_addr,
    output logic        cpu_req_ready,
    output logic        cpu_resp_valid,
    output logic [31:0] cpu_resp_data,

    // Memory-side 32-bit instruction interface.
    output logic        mem_req_valid,
    output logic [31:0] mem_req_addr,
    input  logic        mem_req_ready,
    input  logic        mem_resp_valid,
    input  logic [31:0] mem_resp_data
);
    logic [INDEX_BITS-1:0] index; //chooses which set
    logic                  word_sel;
    logic [TAG_BITS-1:0]   tag;

    assign index    = cpu_req_addr[INDEX_BITS+2:3];
    assign word_sel = cpu_req_addr[2];
    assign tag      = cpu_req_addr[31:INDEX_BITS+3];
    //cpu_req_addr[1:0] used as offset only needed for dcache

    // one array per way, indexed by set
    (* ram_style = "distributed" *) logic [63:0]         way0_data [0:NUM_SETS-1];
    (* ram_style = "distributed" *) logic [TAG_BITS-1:0] way0_tag  [0:NUM_SETS-1];
    (* ram_style = "distributed" *) logic                way0_valid[0:NUM_SETS-1];

    (* ram_style = "distributed" *) logic [63:0]         way1_data [0:NUM_SETS-1];
    (* ram_style = "distributed" *) logic [TAG_BITS-1:0] way1_tag  [0:NUM_SETS-1];
    (* ram_style = "distributed" *) logic                way1_valid[0:NUM_SETS-1];

    // 1-bit LRU per set: 0 = way0 is the eviction target, 1 = way1 is
    logic lru [0:NUM_SETS-1];

    logic hit0, hit1, hit;
    assign hit0 = way0_valid[index] && (way0_tag[index] == tag);
    assign hit1 = way1_valid[index] && (way1_tag[index] == tag);
    assign hit  = hit0 || hit1;

    logic [63:0] hit_line_data;
    assign hit_line_data = hit0 ? way0_data[index] : way1_data[index];

    // victim for a future miss/fill: whichever way the LRU bit currently points to
    logic victim_way;
    assign victim_way = lru[index];

    logic        hit_resp_valid_q;
    logic [31:0] hit_resp_data_q;

    integer i;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin // all valid and LRU bits reset
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                way0_valid[i] <= 1'b0;
                way1_valid[i] <= 1'b0;
                lru[i]        <= 1'b0;
            end

            hit_resp_valid_q <= 1'b0;
            hit_resp_data_q  <= 32'd0;
        end else begin //TODO: nothing is writing way0/way1 data and tag yet
            hit_resp_valid_q <= !BYPASS && cpu_req_valid && cpu_req_ready;

            if (!BYPASS && cpu_req_valid && cpu_req_ready) begin
                hit_resp_data_q <= word_sel ? hit_line_data[63:32] : hit_line_data[31:0];

                // touched way becomes MRU -> lru bit points at the OTHER way next
                if (hit0)      lru[index] <= 1'b1;
                else if (hit1) lru[index] <= 1'b0;
            end
        end
    end

    generate
        if (BYPASS) begin : gen_bypass
            assign mem_req_valid  = cpu_req_valid;
            assign mem_req_addr   = cpu_req_addr;
            assign cpu_req_ready  = mem_req_ready;
            assign cpu_resp_valid = mem_resp_valid;
            assign cpu_resp_data  = mem_resp_data;
        end else begin : gen_hit_only
            assign mem_req_valid  = 1'b0;
            assign mem_req_addr   = 32'd0;
            assign cpu_req_ready  = hit && !hit_resp_valid_q;
            assign cpu_resp_valid = hit_resp_valid_q;
            assign cpu_resp_data  = hit_resp_data_q;
        end
    endgenerate
endmodule