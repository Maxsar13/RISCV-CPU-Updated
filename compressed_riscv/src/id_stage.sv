`include "definitions.vh"

module id_stage(
	input logic clk,
	input logic rst,
	input logic valid_in,
	input logic [31:0] instr_in,
	input logic wb_we,
	input logic [4:0] wb_rd,
	input logic [31:0] wb_data,
	
	output logic [4:0] rs1_out, 
	output logic [4:0] rs2_out,
	output logic [4:0] rd_out,
	output logic [2:0] funct3_out,
	output logic [31:0] imm_out,
	output logic [5:0] alu_op_out,
	output logic alu_src_pc_out,
	output logic alu_src_imm_out,
	output logic reg_write_out,
	output logic mem_read_out,
	output logic mem_write_out,
	output logic branch_out,
	output logic jump_out,
	output logic jalr_out,
	output logic [1:0] result_sel_out,
	output logic uses_rs1_out,
	output logic uses_rs2_out,
	output logic illegal_out,
	output logic halt_out,
	output logic [31:0] rs1_data_out,
	output logic [31:0] rs2_data_out
	);
	
	rv32_decoder decoder_inst(
	.valid(valid_in),
	.instr(instr_in),
	.rs1(rs1_out),
	.rs2(rs2_out),
	.rd(rd_out),
	.funct3(funct3_out),
	.imm(imm_out),
	.alu_op(alu_op_out),
	.alu_src_pc(alu_src_pc_out),
	.alu_src_imm(alu_src_imm_out),
	.reg_write(reg_write_out),
	.mem_read(mem_read_out),
	.mem_write(mem_write_out),
	.branch(branch_out),
	.jump(jump_out),
	.jalr(jalr_out),
	.result_sel(result_sel_out),
	.uses_rs1(uses_rs1_out),
	.uses_rs2(uses_rs2_out),
	.illegal(illegal_out),
	.halt(halt_out)
	);
	
	rv32_regfile regfile_inst(
	.clk(clk),
	.rst(rst),
	.rs1(rs1_out),
	.rs2(rs2_out),
	.rd(wb_rd),
	.wb_data(wb_data),
	.we(wb_we),
	.rs1_data(rs1_data_out),
	.rs2_data(rs2_data_out)
	);
endmodule
	