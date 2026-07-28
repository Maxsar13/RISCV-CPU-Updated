`include "definitions.vh"

module wb_stage(
	input logic valid_in,
	input logic [31:0] pc_in,
	input logic [31:0] alu_result_in,
	input logic [31:0] mem_data_in,
	input logic [4:0] rd_in,
	input logic reg_write_in,
	input logic [1:0] result_sel_in,
	input logic trap_in,
	input logic halt_in,
	
	output logic [31:0] wb_data_out,
	output logic [4:0] wb_rd_out,
	output logic wb_we_out
	);
	
	assign wb_data_out =  (result_sel_in == `RES_MEM) ? mem_data_in : (result_sel_in == `RES_PC4) ? (pc_in + 32'd4) : alu_result_in;
	
	assign wb_rd_out = rd_in;
	
	assign wb_we_out = valid_in && reg_write_in && !trap_in && !halt_in && (rd_in != 5'd0);
endmodule