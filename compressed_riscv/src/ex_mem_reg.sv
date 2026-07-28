module ex_mem_reg(
	input logic clk,
	input logic rst,
	input logic enable,
	input logic flush,
	input logic valid_in,
	input logic [31:0] pc_in,
	input logic [31:0] alu_result_in,
	input logic [31:0] store_data_in,
	input logic [4:0] rd_in,
	input logic [3:0] funct3_in,
	input logic reg_write_in,
	input logic mem_read_in,
	input logic mem_write_in,
	input logic [1:0] result_sel_in,
	input logic trap_in,
	input logic halt_in,
	
	output logic valid_out,
	output logic [31:0] pc_out,
	output logic [31:0] alu_result_out,
	output logic [31:0] store_data_out,
	output logic [4:0] rd_out,
	output logic [2:0] funct3_out,
	output logic reg_write_out,
	output logic mem_read_out,
	output logic mem_write_out,
	output logic [1:0] result_sel_out,
	output logic trap_out,
	output logic halt_out
	);
	
	task clear_outputs;
	begin
		valid_out <= 1'b0;
		pc_out <= 32'd0;
		alu_result_out <= 32'd0;
		store_data_out <= 32'd0;
		rd_out <= 5'd0;
		funct3_out <= 3'd0;
		reg_write_out <= 1'b0;
		mem_read_out <= 1'b0;
		mem_write_out <= 1'b0;
		result_sel_out <= 2'd0;
		trap_out <= 1'b0;
		halt_out <= 1'b0;
	end
	endtask
	
	always_ff @(posedge clk)
	begin
		if(rst)
			begin
				clear_outputs();
			end
		else if (flush)
			begin
				clear_outputs();
			end
		else if(enable)
			begin
				valid_out <= valid_in;
				pc_out <= pc_in;
				alu_result_out <= alu_result_in;
				store_data_out <= store_data_in;
				rd_out <= rd_in;
				funct3_out <= funct3_in;
				reg_write_out <= reg_write_in;
				mem_read_out <= mem_read_in;
				mem_write_out <= mem_write_in;
				result_sel_out <= result_sel_in;
				trap_out <= trap_in;
				halt_out <= halt_in;
			end
		end
	endmodule
	
	