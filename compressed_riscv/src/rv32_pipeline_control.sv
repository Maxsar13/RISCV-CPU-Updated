`include "definitions.vh"

module rv32_pipeline_control(
	input logic halted,
	input logic memory_stall,
	input logic load_use_stall,
	input logic redirect,
	input logic ex_trap,
	
	output logic fetch_enable,
	output logic if_id_enable,
	output logic if_id_flush,
	output logic id_ex_enable,
	output logic id_ex_flush,
	output logic ex_mem_enable,
	output logic mem_wb_enable
	);
	assign fetch_enable = !halted && !memory_stall && !load_use_stall;
	assign if_id_enable = !memory_stall && !load_use_stall;
	assign if_id_flush = redirect || ex_trap;
	assign id_ex_enable = !memory_stall;
	assign id_ex_flush = redirect || ex_trap || load_use_stall;
	assign ex_mem_enable = !memory_stall;
	assign mem_wb_enable = !memory_stall;
endmodule