module dmem_bram #(
    parameter WORDS = 16384,
    parameter ADDR_WIDTH = $clog2(WORDS),
    parameter INIT_FILE = ""
)(
    input  logic        clk,
    input  logic        dmem_req_valid,
    input  logic        dmem_req_write,
    input  logic [31:0] dmem_req_addr,
    input  logic [31:0] dmem_req_wdata,
    input  logic [3:0]  dmem_req_wstrb,
    output logic        dmem_req_ready,
    output reg         dmem_resp_valid,
    output reg  [31:0] dmem_resp_rdata
);
    logic [ADDR_WIDTH-1:0] addr;
    assign addr = dmem_req_addr[ADDR_WIDTH+1:2];

    (* ram_style = "block" *) reg [31:0] mem [0:WORDS-1];

    assign dmem_req_ready = 1'b1;

    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    always_ff @(posedge clk) begin
        dmem_resp_valid <= dmem_req_valid && !dmem_req_write;

        if (dmem_req_valid && dmem_req_write) begin
            if (dmem_req_wstrb[0]) mem[addr][7:0]   <= dmem_req_wdata[7:0];
            if (dmem_req_wstrb[1]) mem[addr][15:8]  <= dmem_req_wdata[15:8];
            if (dmem_req_wstrb[2]) mem[addr][23:16] <= dmem_req_wdata[23:16];
            if (dmem_req_wstrb[3]) mem[addr][31:24] <= dmem_req_wdata[31:24];
        end

        if (dmem_req_valid && !dmem_req_write)
            dmem_resp_rdata <= mem[addr];
    end
endmodule