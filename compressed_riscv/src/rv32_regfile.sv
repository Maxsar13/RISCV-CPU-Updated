module rv32_regfile(	
	input logic clk,
	input logic rst,
	input logic we,
	input logic [4:0] rs1,
	input logic [4:0] rs2,
	input logic [4:0] rd,
	input logic [31:0] wb_data,
	
	output logic [31:0] rs1_data,
	output logic [31:0] rs2_data
	);
	
	reg [31:0] regs [31:0];
	integer i;
	
	assign rs1_data = (rs1 == 5'b0) ? 32'b0 : (we && rd == rs1 && rd != 5'b0) ? wb_data : regs[rs1];
	assign rs2_data = (rs2 == 5'b0) ? 32'b0 : (we && rd == rs2 && rd != 5'b0) ? wb_data : regs[rs2];
	
	always_ff @(posedge clk)
	begin
		if(rst)
			begin
				for(i = 0; i < 32; i = i + 1)
					regs[i] <= 32'b0;
			end
			
		else 
			begin
				if(we && rd != 5'b0)
					begin
						regs[rd] <= wb_data;
					end	
				end
			end
	endmodule
			