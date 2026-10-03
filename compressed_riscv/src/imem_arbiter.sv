`include "definitions.vh"

// instruction memory arbiter
// round-robin between two cores
// single imem port
module imem_arbiter (
    input  logic        clk,
    input  logic        rst,

    // core 0 imem interface
    input  logic        imem_req_valid_0,
    input  logic [31:0] imem_req_addr_0,
    output logic        imem_req_ready_0,
    output logic        imem_resp_valid_0,
    output logic [63:0] imem_resp_data_0,

    // core 1 imem interface
    input  logic        imem_req_valid_1,
    input  logic [31:0] imem_req_addr_1,
    output logic        imem_req_ready_1,
    output logic        imem_resp_valid_1,
    output logic [63:0] imem_resp_data_1,

    // shared imem port
    output logic        imem_req_valid,
    output logic [31:0] imem_req_addr,
    input  logic        imem_req_ready,
    input  logic        imem_resp_valid,
    input  logic [63:0] imem_resp_data
);

    // round robin state
    // 0 = core 0 has priority, 1 = core 1 has priority
    reg rr_priority;
    reg response_pending;
    reg response_owner;

    // grant logic
    // if both request, use round robin priority
    // if only one requests, grant that one
    logic grant_0;
    assign grant_0 = imem_req_valid_0 && (!imem_req_valid_1 || !rr_priority);
    logic grant_1;
    assign grant_1 = imem_req_valid_1 && (!imem_req_valid_0 ||  rr_priority);

    // forward selected core's request to memory
    assign imem_req_valid = grant_0 ? imem_req_valid_0 :
                            grant_1 ? imem_req_valid_1 : 1'b0;

    assign imem_req_addr  = grant_0 ? imem_req_addr_0 :
                            grant_1 ? imem_req_addr_1 : 32'b0;

    // ready signals
    // granted core gets memory's ready signal
    // non-granted core gets 0 (stall)
    assign imem_req_ready_0 = grant_0 ? imem_req_ready : 1'b0;
    assign imem_req_ready_1 = grant_1 ? imem_req_ready : 1'b0;

    // BRAM responses are synchronous, so route them to the core that owned
    // the accepted request rather than the core requesting in this cycle.
    assign imem_resp_valid_0 = response_pending && !response_owner ? imem_resp_valid : 1'b0;
    assign imem_resp_valid_1 = response_pending &&  response_owner ? imem_resp_valid : 1'b0;
    assign imem_resp_data_0  = (!response_owner) ? imem_resp_data : 64'b0;
    assign imem_resp_data_1  = ( response_owner) ? imem_resp_data : 64'b0;

    // update round robin priority after each completed transaction
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_priority <= 1'b0;
            response_pending <= 1'b0;
            response_owner <= 1'b0;
        end else begin
            if (!response_pending && imem_req_valid && imem_req_ready) begin
                response_pending <= 1'b1;
                response_owner <= grant_1;
            end else if (response_pending && imem_resp_valid) begin
                rr_priority <= response_owner ? 1'b0 : 1'b1;
                // The memory can accept the next request in the same cycle
                // that it returns the current synchronous response.
                if (imem_req_valid && imem_req_ready) begin
                    response_pending <= 1'b1;
                    response_owner <= grant_1;
                end else begin
                    response_pending <= 1'b0;
                end
            end
        end
    end

endmodule