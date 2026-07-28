`include "definitions.vh"

module if_stage #(
	parameter RESET_VECTOR = 32'h0000_0000)
	(
	input logic clk,
	input logic rst,
	input logic enable,
	input logic redirect,
	input logic [31:0] redirect_target,
	input logic imem_req_ready,
	input logic imem_resp_valid,
	input logic [31:0] imem_resp_data,
	output logic imem_req_valid,
	output logic [31:0] imem_req_addr,
	output logic fetch_valid,
	output logic [31:0] fetch_pc,
	output logic [31:0] fetch_instr,
	output logic [31:0] pc_debug
	);
	
	reg [31:0] pc_q;
	
	//requesting the current program counter
	assign imem_req_valid = enable;
	assign imem_req_addr = pc_q; 
	//Saying the response was accepted
	assign fetch_valid = enable && imem_req_ready && imem_resp_valid;
	
	//IF/ID payload
	assign fetch_pc = pc_q;
	assign fetch_instr = imem_resp_data;
	
	//external view
	assign pc_debug = pc_q;
	
	always @(posedge clk or posedge rst)
		begin
			if(rst)
				begin
					pc_q <= RESET_VECTOR;
				end
			else if (enable)
				begin
					if(redirect)
						pc_q <= redirect_target;
					else if(imem_req_ready && imem_resp_valid)
						pc_q <= pc_q + 32'd4;
				end
			end
		endmodule