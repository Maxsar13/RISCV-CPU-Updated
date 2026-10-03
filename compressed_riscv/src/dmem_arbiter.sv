`include "definitions.vh"

// data memory arbiter
// round-robin between two cores
// single dmem port
// handles MMIO address detection
module dmem_arbiter (
    input  logic        clk,
    input  logic        rst,

    // core 0 dmem interface
    input  logic        dmem_req_valid_0,
    input  logic        dmem_req_write_0,
    input  logic [31:0] dmem_req_addr_0,
    input  logic [31:0] dmem_req_wdata_0,
    input  logic [3:0]  dmem_req_wstrb_0,
    output logic        dmem_req_ready_0,
    output logic        dmem_resp_valid_0,
    output logic [63:0] dmem_resp_rdata_0,

    // core 1 dmem interface
    input  logic        dmem_req_valid_1,
    input  logic        dmem_req_write_1,
    input  logic [31:0] dmem_req_addr_1,
    input  logic [31:0] dmem_req_wdata_1,
    input  logic [3:0]  dmem_req_wstrb_1,
    output logic        dmem_req_ready_1,
    output logic        dmem_resp_valid_1,
    output logic [63:0] dmem_resp_rdata_1,

    // shared dmem port
    output logic        dmem_req_valid,
    output logic        dmem_req_write,
    output logic [31:0] dmem_req_addr,
    output logic [31:0] dmem_req_wdata,
    output logic [3:0]  dmem_req_wstrb,
    input  logic        dmem_req_ready,
    input  logic        dmem_resp_valid,
    input  logic [63:0] dmem_resp_rdata,

    // MMIO — core ID
    // more peripherals added here later
    output logic [31:0] core_id_rdata_0,
    output logic        core_id_valid_0,
    output logic [31:0] core_id_rdata_1,
    output logic        core_id_valid_1,

    // MMIO — lock unit
    // routes lock accesses at 0xF0000010 to Nana's lock_unit
    output logic        lock_req_0,
    output logic        lock_write_0,
    output logic [31:0] lock_addr_0,
    output logic [31:0] lock_wdata_0,
    input  logic        lock_ready_0,
    input  logic        lock_resp_valid_0,
    input  logic [31:0] lock_rdata_0,

    output logic        lock_req_1,
    output logic        lock_write_1,
    output logic [31:0] lock_addr_1,
    output logic [31:0] lock_wdata_1,
    input  logic        lock_ready_1,
    input  logic        lock_resp_valid_1,
    input  logic [31:0] lock_rdata_1,
    input  logic        lock_locked,
    input  logic        lock_owner
);

    // MMIO address detection
    // anything with top nibble = 0xF00000FF in MMIO is for Arbiters
	logic mmio_req_0;
    assign mmio_req_0 = dmem_req_valid_0 && (dmem_req_addr_0[31:8] == 24'hF00000);        //Changed this to 31:8 as we want to differentiate arbiter decoding vs counter macros.
	logic mmio_req_1;
    assign mmio_req_1 = dmem_req_valid_1 && (dmem_req_addr_1[31:8] == 24'hF00000);        //Not a huge deal now but mmio request may be false valid if we access the counters

    // real memory requests (not MMIO)
	logic mem_req_valid_0;
    assign mem_req_valid_0 = dmem_req_valid_0 && !mmio_req_0;
	logic mem_req_valid_1;
    assign mem_req_valid_1 = dmem_req_valid_1 && !mmio_req_1;

    //Setting a counter for the bus contention
    // round robin priority
    reg rr_priority;
    logic [31:0] bus_contention_count;
    logic mem_response_pending;
    logic mem_response_owner;
    logic mem_response_valid; //holds BRAM response for a cycle so the CPU can consume it
    logic [63:0] mem_response_data;

    // grant logic for real memory
    // if lock is held, only the lock owner gets memory access
    // otherwise use round-robin
	logic grant_0;
    assign grant_0 = lock_locked ? (lock_owner == 1'b0 && mem_req_valid_0 && !mem_response_pending) :
                     (!mem_response_pending && mem_req_valid_0 &&
                      (!mem_req_valid_1 || !rr_priority));
	logic grant_1;
    assign grant_1 = lock_locked ? (lock_owner == 1'b1 && mem_req_valid_1 && !mem_response_pending) :
                     (!mem_response_pending && mem_req_valid_1 &&
                      (!mem_req_valid_0 || rr_priority));

    // forward selected core to memory
    assign dmem_req_valid = grant_0 ? dmem_req_valid_0 :
                            grant_1 ? dmem_req_valid_1 : 1'b0;

    assign dmem_req_write = grant_0 ? dmem_req_write_0 :
                            grant_1 ? dmem_req_write_1 : 1'b0;

    assign dmem_req_addr  = grant_0 ? dmem_req_addr_0 :
                            grant_1 ? dmem_req_addr_1 : 32'b0;

    assign dmem_req_wdata = grant_0 ? dmem_req_wdata_0 :
                            grant_1 ? dmem_req_wdata_1 : 32'b0;

    assign dmem_req_wstrb = grant_0 ? dmem_req_wstrb_0 :
                            grant_1 ? dmem_req_wstrb_1 : 4'b0;


    // ---------------------------------------------------------
    // core ID MMIO handler
    // read 0xF0000000 to get core ID
    // core 0 gets 0, core 1 gets 1
    // ---------------------------------------------------------
	logic core_id_req_0;
    assign core_id_req_0 = mmio_req_0 && !dmem_req_write_0 &&
                         (dmem_req_addr_0 == 32'hF000_0000);

	logic core_id_req_1;
    assign core_id_req_1 = mmio_req_1 && !dmem_req_write_1 &&
                         (dmem_req_addr_1 == 32'hF000_0000);

    logic bus_cont_req_0;
    assign bus_cont_req_0 = mmio_req_0 && !dmem_req_write_0 &&
                            (dmem_req_addr_0 == 32'hF000_0004);
    logic bus_cont_req_1;
    assign bus_cont_req_1 = mmio_req_1 && !dmem_req_write_1 &&
                            (dmem_req_addr_1 == 32'hF000_0004);

    assign core_id_valid_0 = core_id_req_0 || bus_cont_req_0;
    assign core_id_valid_1 = core_id_req_1 || bus_cont_req_1;

    assign core_id_rdata_0 = core_id_req_0 ? 32'd0 : bus_cont_req_0 ? bus_contention_count : 32'b0;
    assign core_id_rdata_1 = core_id_req_1 ? 32'd1 : bus_cont_req_1 ? bus_contention_count : 32'b0;


    // ---------------------------------------------------------
    // lock MMIO handler
    // 0xF0000010 is reserved for the shared spinlock
    //
    // read  = atomic acquire attempt
    // write = release attempt
    // ---------------------------------------------------------

	logic lock_req_detect_0;
    assign lock_req_detect_0 =
        mmio_req_0 &&
        (dmem_req_addr_0 == 32'hF000_0010);

	logic lock_req_detect_1;
    assign lock_req_detect_1 =
        mmio_req_1 &&
        (dmem_req_addr_1 == 32'hF000_0010);

    // Forward Core 0's lock transaction to lock_unit
    assign lock_req_0   = lock_req_detect_0;
    assign lock_write_0 = dmem_req_write_0;
    assign lock_addr_0  = dmem_req_addr_0;
    assign lock_wdata_0 = dmem_req_wdata_0;

    // Forward Core 1's lock transaction to lock_unit
    assign lock_req_1   = lock_req_detect_1;
    assign lock_write_1 = dmem_req_write_1;
    assign lock_addr_1  = dmem_req_addr_1;
    assign lock_wdata_1 = dmem_req_wdata_1;


    // ready signals
    // MMIO requests are handled immediately (ready=1)
    // memory requests get memory's ready signal if granted, 0 if not

    // lock requests use the ready signal supplied by lock_unit
    assign dmem_req_ready_0 = core_id_req_0     ? 1'b1 :
                              bus_cont_req_0    ? 1'b1 :
                              lock_req_detect_0 ? lock_ready_0 :
                              (mem_response_valid && !mem_response_owner) ? 1'b1 :
                              grant_0           ? dmem_req_ready :
                                                  1'b0;

    assign dmem_req_ready_1 = core_id_req_1     ? 1'b1 :
							  bus_cont_req_1    ? 1'b1 :
                              lock_req_detect_1 ? lock_ready_1 :
                              (mem_response_valid && mem_response_owner) ? 1'b1 :
                              grant_1           ? dmem_req_ready :
                                                  1'b0;


    // response routing for real memory

    // MMIO responses are selected by their specific address
    assign dmem_resp_valid_0 = core_id_req_0     ? core_id_valid_0 :
                               bus_cont_req_0    ? 1'b1 :
                               lock_req_detect_0 ? lock_resp_valid_0 :
                               (mem_response_valid && !mem_response_owner) ? 1'b1 :
                                                   1'b0;

    assign dmem_resp_valid_1 = core_id_req_1     ? core_id_valid_1 :
                               bus_cont_req_1    ? 1'b1 :
                               lock_req_detect_1 ? lock_resp_valid_1 :
                               (mem_response_valid && mem_response_owner) ? 1'b1 :
                                                   1'b0;

    assign dmem_resp_rdata_0 = core_id_req_0     ? {2{core_id_rdata_0}} :
                               bus_cont_req_0    ? {2{bus_contention_count}} :
                               lock_req_detect_0 ? {2{lock_rdata_0}} :
                               (mem_response_valid && !mem_response_owner) ? mem_response_data :
                                                   64'b0;

    assign dmem_resp_rdata_1 = core_id_req_1     ? {2{core_id_rdata_1}} :
                               bus_cont_req_1    ? {2{bus_contention_count}} :
                               lock_req_detect_1 ? {2{lock_rdata_1}} :
                               (mem_response_valid && mem_response_owner) ? mem_response_data :
                                                   64'b0;


    // update round robin after each completed memory transaction
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_priority <= 1'b0;
            bus_contention_count <= 32'd0;
            mem_response_pending <= 1'b0;
            mem_response_owner <= 1'b0;
            mem_response_valid <= 1'b0;
            mem_response_data <= 64'd0;
        end
        else begin
            if (mem_response_valid) begin
                mem_response_valid <= 1'b0;
                mem_response_pending <= 1'b0;
            end
            else if (mem_response_pending) begin
                if (dmem_resp_valid) begin
                    mem_response_valid <= 1'b1;
                    mem_response_data <= dmem_resp_rdata;
                end
            end
            else if (dmem_req_valid && dmem_req_ready && !dmem_req_write) begin
                mem_response_pending <= 1'b1;
                mem_response_owner <= grant_1;
            end
            if (dmem_req_valid && dmem_req_ready)
                rr_priority <= grant_0 ? 1'b1 : 1'b0;
            if (mem_req_valid_0 && mem_req_valid_1)
                bus_contention_count <= bus_contention_count + 32'd1;
        end
    end
endmodule