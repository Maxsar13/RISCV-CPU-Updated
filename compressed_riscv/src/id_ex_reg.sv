module id_ex_reg(
	input logic clk, 
	input logic rst,
	input logic enable,
	input logic flush,
	input logic valid_in,
	input logic [31:0] pc_in,
	input logic [31:0] rs1_data_in,
	input logic [31:0] rs2_data_in,
	input logic [31:0] imm_in,
	input logic [4:0] rs1_in,
	input logic [4:0] rs2_in,
	input logic [4:0] rd_in,
	input logic [2:0] funct3_in,
	input logic [5:0] alu_op_in,
	input logic alu_src_pc_in,
	input logic alu_src_imm_in,
	input logic reg_write_in,
	input logic mem_read_in,
	input logic mem_write_in,
	input logic branch_in,
	input logic jump_in, 
	input logic jalr_in,
	input logic [1:0] result_sel_in,
	input logic illegal_in,
	input logic halt_in,
	
	output logic valid_out, 
	output logic [31:0] pc_out,
	output logic [31:0] rs1_data_out,
	output logic [31:0] rs2_data_out,
	output logic [31:0] imm_out,
	output logic [4:0] rs1_out,
	output logic [4:0] rs2_out,
	output logic [4:0] rd_out,
	output logic [2:0] funct3_out,
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
	output logic illegal_out,
	output logic halt_out
	);
	
	task clear_outputs;
	begin
		valid_out <= 1'b0;
		pc_out <= 32'd0;
		rs1_data_out <= 32'd0;
		rs2_data_out <= 32'd0;
		imm_out <= 32'd0;
		rs1_out <= 5'd0;
		rs2_out <= 5'd0;
		rd_out <= 5'd0;
		funct3_out <= 5'd0;
		alu_op_out <= 6'd0;
		alu_src_pc_out <= 1'b0;
		alu_src_imm_out <= 1'b0;
		reg_write_out <= 1'b0;
		mem_read_out <= 1'b0;
		mem_write_out <= 1'b0;
		branch_out <= 1'b0;
		jump_out <= 1'b0;
		jalr_out <= 1'b0;
		result_sel_out <= 2'd0;
		illegal_out <= 1'b0;
		halt_out <= 1'b0;
	end
endtask	

	always_ff @(posedge clk)
	begin
		if(rst)
			begin
				clear_outputs();
			end
		else if(flush)
			begin
				clear_outputs();
			end
		else if (enable)
			begin
				valid_out <= valid_in;
				pc_out <= pc_in;
				rs1_data_out <= rs1_data_in;
				rs2_data_out <= rs2_data_in;
				imm_out <= imm_in;
				rs1_out <= rs1_in;
				rs2_out <= rs2_in;
				rd_out <= rd_in;
				funct3_out <= funct3_in;
				alu_op_out <= alu_op_in;
				alu_src_pc_out <= alu_src_pc_in;
				alu_src_imm_out <= alu_src_imm_in;
				reg_write_out <= reg_write_in;
				mem_read_out <= mem_read_in;
				mem_write_out <= mem_write_in;
				branch_out <= branch_in;
				jump_out <= jump_in;
				jalr_out <= jalr_in;
				result_sel_out <= result_sel_in;
				illegal_out <= illegal_in;
				halt_out <= halt_in;
			end
		end
	endmodule