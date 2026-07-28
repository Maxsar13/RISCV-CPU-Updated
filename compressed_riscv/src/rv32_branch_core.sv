`include "definitions.vh"

module rv32_branch_core(
	input logic [2:0] funct3,
	input logic [31:0] a,
	input logic [31:0] b,
	
	output logic taken
	);
	
	always_comb
	begin
		case(funct3)
			`BRANCH_BEQ: taken = (a == b);
			`BRANCH_BNE: taken = (a != b);
			
			`BRANCH_BLT: taken = ($signed(a) < $signed(b));
			`BRANCH_BGE: taken = ($signed(a) > $signed(b));
			
			`BRANCH_BLTU: taken = (a < b);
			`BRANCH_BGEU: taken = (a >= b);
			
			default: taken = 1'b0;
		endcase
	end
endmodule