`include "definitions.vh"

module ex_stage(
	input logic valid_in,
	input logic [31:0] pc_in,
	input logic [31:0] rs1_data_in,
	input logic [31:0] rs2_data_in,
	input logic [31:0] imm_in,
	input logic [4:0] rs1_in,
	input logic [4:0] rs2_in,
	input logic [2:0] funct3_in,
	input logic [5:0] alu_op_in,
	input logic alu_src_pc_in,
	input logic alu_src_imm_in,
	input logic mem_read_in,
	input logic mem_write_in,
	input logic branch_in,
	input logic jump_in,
	input logic jalr_in,
	input logic illegal_in,
	input logic halt_in,
	input logic [1:0] forward_a_sel,
	input logic [1:0] forward_b_sel,
	input logic [1:0] forward_store_sel,
	input logic [31:0] ex_mem_forward_value,
	input logic [31:0] wb_forward_value,
	
	output logic [31:0] ex_a_out,
	output logic [31:0] ex_b_out,
	output logic [31:0] alu_result_out,
	output logic [31:0] store_data_out,
	output logic branch_taken_out,
	output logic [31:0] branch_target_out,
	output logic redirect_out,
	output logic trap_out
	);
	
	logic [31:0] ex_a;
	logic [31:0] ex_b;
	logic [31:0] store_data; 
	logic [31:0] alu_result;
	logic branch_taken;
	logic misaligned;
	
	rv32_alu_core alu_inst(
	.a(ex_a),
	.b(ex_b),
	.op(alu_op_in),
	.result(alu_result)
	);
	
	rv32_branch_core branch_inst(
	.funct3(funct3_in),
	.a(ex_a),
	.b(ex_b),
	.taken(branch_taken)
	);
	
	always_comb
	begin
		ex_a = alu_src_pc_in ? pc_in : rs1_data_in;
		ex_b = alu_src_imm_in ? imm_in : rs2_data_in;
		store_data = rs2_data_in;
		
		case(forward_a_sel)
			//Nearest ALU value
			2'b10: ex_a = ex_mem_forward_value;
			//Writeback value
			2'b01: ex_a = wb_forward_value;
			default;
		endcase;
		
		if(!alu_src_imm_in)
			begin
				//RS2 ALU operand
				case(forward_b_sel)
					2'b10: ex_b = ex_mem_forward_value;
					2'b01: ex_b = wb_forward_value;
					default: ;
				endcase
			end
			
			case(forward_store_sel)
				2'b10: store_data = ex_mem_forward_value;
				2'b01: store_data = wb_forward_value;
				default;
			endcase
		end
		
		//target calc
		assign branch_target_out = jalr_in ? ((ex_a + imm_in) & 32'hffff_fffe) : (pc_in + imm_in);
		assign branch_taken_out = branch_taken;
		
		//Flush request
		assign redirect_out = valid_in && !illegal_in && !halt_in && ((branch_in && branch_taken) || jump_in);
		
		//Align check
		assign misaligned = (mem_read_in || mem_write_in) && (((funct3_in == 3'b010) && (alu_result[1:0] != 2'b00)) || (((funct3_in == 3'b001) || (funct3_in == 3'b101)) && alu_result[0]));
		
		//trap request
		assign trap_out = valid_in && (illegal_in || misaligned);
		
		always_comb
		begin
			//Debug taps
			ex_a_out = ex_a;
			ex_b_out = ex_b;
			alu_result_out = alu_result;
			store_data_out = store_data;
		end
	endmodule
			
	