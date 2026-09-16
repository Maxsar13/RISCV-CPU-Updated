`include "definitions.vh"

// data memory arbiter
// round-robin between two cores
// single dmem port
// handles MMIO address detection
module dmem_arbiter (
    input  wire        clk,
    input  wire        rst,

    // core 0 dmem interface
    input  wire        dmem_req_valid_0,
    input  wire        dmem_req_write_0,
    input  wire [31:0] dmem_req_addr_0,
    input  wire [31:0] dmem_req_wdata_0,
    input  wire [3:0]  dmem_req_wstrb_0,
    output wire        dmem_req_ready_0,
    output wire        dmem_resp_valid_0,
    output wire [31:0] dmem_resp_rdata_0,

    // core 1 dmem interface
    input  wire        dmem_req_valid_1,
    input  wire        dmem_req_write_1,
    input  wire [31:0] dmem_req_addr_1,
    input  wire [31:0] dmem_req_wdata_1,
    input  wire [3:0]  dmem_req_wstrb_1,
    output wire        dmem_req_ready_1,
    output wire        dmem_resp_valid_1,
    output wire [31:0] dmem_resp_rdata_1,

    // shared dmem port
    output wire        dmem_req_valid,
    output wire        dmem_req_write,
    output wire [31:0] dmem_req_addr,
    output wire [31:0] dmem_req_wdata,
    output wire [3:0]  dmem_req_wstrb,
    input  wire        dmem_req_ready,
    input  wire        dmem_resp_valid,
    input  wire [31:0] dmem_resp_rdata,

    // MMIO — core ID
    // more peripherals added here later
    output wire [31:0] core_id_rdata_0,
    output wire        core_id_valid_0,
    output wire [31:0] core_id_rdata_1,
    output wire        core_id_valid_1,

    // MMIO — lock unit
    // routes lock accesses at 0xF0000010 to Nana's lock_unit
    output wire        lock_req_0,
    output wire        lock_write_0,
    output wire [31:0] lock_addr_0,
    output wire [31:0] lock_wdata_0,
    input  wire        lock_ready_0,
    input  wire        lock_resp_valid_0,
    input  wire [31:0] lock_rdata_0,

    output wire        lock_req_1,
    output wire        lock_write_1,
    output wire [31:0] lock_addr_1,
    output wire [31:0] lock_wdata_1,
    input  wire        lock_ready_1,
    input  wire        lock_resp_valid_1,
    input  wire [31:0] lock_rdata_1
);

    // MMIO address detection
    // anything with top nibble = 0xF is MMIO
    wire mmio_req_0 = dmem_req_valid_0 && (dmem_req_addr_0[31:8] == 24'hF00000);        //Changed this to 31:8 as we want to differentiate arbiter decoding vs counter macros.
    wire mmio_req_1 = dmem_req_valid_1 && (dmem_req_addr_1[31:8] == 24'hF00000);        //Not a huge deal now but mmio request may be false valid if we access the counters

    // real memory requests (not MMIO)
    wire mem_req_valid_0 = dmem_req_valid_0 && !mmio_req_0;
    wire mem_req_valid_1 = dmem_req_valid_1 && !mmio_req_1;

    //Setting a counter for the bus contention
    logic [31:0] bus_contention_count;
    // round robin priority
    reg rr_priority;

    // grant logic for real memory
    wire grant_0 = mem_req_valid_0 && (!mem_req_valid_1 || !rr_priority);
    wire grant_1 = mem_req_valid_1 && (!mem_req_valid_0 ||  rr_priority);

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

    wire core_id_req_0 = mmio_req_0 && !dmem_req_write_0 &&
                         (dmem_req_addr_0 == 32'hF000_0000);

    wire core_id_req_1 = mmio_req_1 && !dmem_req_write_1 &&
                         (dmem_req_addr_1 == 32'hF000_0000);

    assign core_id_valid_0 = core_id_req_0;
    assign core_id_valid_1 = core_id_req_1;

    assign core_id_rdata_0 = core_id_req_0 ? 32'd0 : 32'b0;
    assign core_id_rdata_1 = core_id_req_1 ? 32'd1 : 32'b0;


    // ---------------------------------------------------------
    // lock MMIO handler
    // 0xF0000010 is reserved for the shared spinlock
    //
    // read  = atomic acquire attempt
    // write = release attempt
    // --------------------------------------------------------- 
	
	wire bus_cont_req_0 = mmio_req_0 && !dmem_req_write_0 && (dmem_req_addr_0 == 32'hF000_0004); 
	wire bus_cont_req_1 = mmio_req_1 && !dmem_req_write_1 && (dmem_req_addr_1 == 32'hF000_0004);
	

    wire lock_req_detect_0 =
        mmio_req_0 &&
        (dmem_req_addr_0 == 32'hF000_0010);

    wire lock_req_detect_1 =
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
		
	//Adding bus_cont_req so it has a read path and software can read it
		
    // lock requests use the ready signal supplied by lock_unit
    assign dmem_req_ready_0 = core_id_req_0     ? 1'b1 :
							  bus_cont_req_0	? 1'b1 :
                              lock_req_detect_0 ? lock_ready_0 :
                              grant_0           ? dmem_req_ready :
                                                  1'b0;

    assign dmem_req_ready_1 = core_id_req_1     ? 1'b1 :  
							  bus_cont_req_1    ? 1'b1 :
                              lock_req_detect_1 ? lock_ready_1 :
                              grant_1           ? dmem_req_ready :
                                                  1'b0;


    // response routing for real memory

    // MMIO responses are selected by their specific address
    assign dmem_resp_valid_0 = core_id_req_0     ? core_id_valid_0 :  
							   bus_cont_req_0    ? 1'b1 :
                               lock_req_detect_0 ? lock_resp_valid_0 :
                               grant_0           ? dmem_resp_valid :
                                                   1'b0;

    assign dmem_resp_valid_1 = core_id_req_1     ? core_id_valid_1 : 
							   bus_cont_req_1    ? 1'b1 :
                               lock_req_detect_1 ? lock_resp_valid_1 :
                               grant_1           ? dmem_resp_valid :
                                                   1'b0;

    assign dmem_resp_rdata_0 = core_id_req_0     ? core_id_rdata_0 : 
							   bus_cont_req_0    ? bus_contention_count :
                               lock_req_detect_0 ? lock_rdata_0 :
                               grant_0           ? dmem_resp_rdata :
                                                   32'b0;

    assign dmem_resp_rdata_1 = core_id_req_1     ? core_id_rdata_1 : 
							   bus_cont_req_1    ? bus_contention_count :
                               lock_req_detect_1 ? lock_rdata_1 :
                               grant_1           ? dmem_resp_rdata :
                                                   32'b0;


    // update round robin after each completed memory transaction
    always @(posedge clk or posedge rst) begin
        if (rst)
            begin
                rr_priority <= 1'b0;
                bus_contention_count <= 32'd0;
            end
        else begin
            if(dmem_req_valid && dmem_req_ready)
                rr_priority <= grant_0 ?1'b1 : 1'b0;
            if(mem_req_valid_0 && mem_req_valid_1)
                bus_contention_count <= bus_contention_count + 32'd1;
        end
    end
endmodule