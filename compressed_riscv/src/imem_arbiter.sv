`include "definitions.vh"

// instruction memory arbiter
// round-robin between two cores
// single imem port
module imem_arbiter (
    input  wire        clk,
    input  wire        rst,

    // core 0 imem interface
    input  wire        imem_req_valid_0,
    input  wire [31:0] imem_req_addr_0,
    output wire        imem_req_ready_0,
    output wire        imem_resp_valid_0,
    output wire [31:0] imem_resp_data_0,

    // core 1 imem interface
    input  wire        imem_req_valid_1,
    input  wire [31:0] imem_req_addr_1,
    output wire        imem_req_ready_1,
    output wire        imem_resp_valid_1,
    output wire [31:0] imem_resp_data_1,

    // shared imem port
    output wire        imem_req_valid,
    output wire [31:0] imem_req_addr,
    input  wire        imem_req_ready,
    input  wire        imem_resp_valid,
    input  wire [31:0] imem_resp_data
);

    // round robin state
    // 0 = core 0 has priority, 1 = core 1 has priority
    reg rr_priority;

    // grant logic
    // if both request, use round robin priority
    // if only one requests, grant that one
    wire grant_0 = imem_req_valid_0 && (!imem_req_valid_1 || !rr_priority);
    wire grant_1 = imem_req_valid_1 && (!imem_req_valid_0 ||  rr_priority);

    // forward selected core's request to memory
    assign imem_req_valid = grant_0 ? imem_req_valid_0 : grant_1 ? imem_req_valid_1 : 1'b0;

    assign imem_req_addr  = grant_0 ? imem_req_addr_0 : grant_1 ? imem_req_addr_1 : 32'b0;

    // ready signals
    // granted core gets memory's ready signal
    // non-granted core gets 0 (stall)
    assign imem_req_ready_0 = grant_0 ? imem_req_ready : 1'b0;
    assign imem_req_ready_1 = grant_1 ? imem_req_ready : 1'b0;

    // response routing
    // only the granted core gets the response
    assign imem_resp_valid_0 = grant_0 ? imem_resp_valid : 1'b0;
    assign imem_resp_valid_1 = grant_1 ? imem_resp_valid : 1'b0;
    assign imem_resp_data_0  = grant_0 ? imem_resp_data  : 32'b0;
    assign imem_resp_data_1  = grant_1 ? imem_resp_data  : 32'b0;

    // update round robin priority after each completed transaction
    always @(posedge clk or posedge rst) begin
        if (rst)
            rr_priority <= 1'b0;
        else if (imem_req_valid && imem_req_ready && imem_resp_valid)
            // flip priority after each completed request
            rr_priority <= grant_0 ? 1'b1 : 1'b0;
    end

endmodule
