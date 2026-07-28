`include "definitions.vh"

module rv32_alu_core(
	input logic [31:0] a,
	input logic [31:0] b,
	input logic [5:0] op,
	
	output logic [31:0] result
	);
	
	always_comb
	begin
		case(op)
			//ALU add and SUB
			`ALU_ADD: result = a + b;	   
			`ALU_SUB: result = a - b;
			//Bitwise operations
			`ALU_AND:   result = a & b;
            `ALU_OR:    result = a | b;
            `ALU_XOR:   result = a ^ b;
            // shifts
            `ALU_SLL:   result = a << b[4:0];
            `ALU_SRL:   result = a >> b[4:0];
            `ALU_SRA:   result = $signed(a) >>> b[4:0];
            // compares
            `ALU_SLT:   result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU:  result = (a < b) ? 32'd1 : 32'd0;
            // LUI path
            `ALU_COPYB: result = b;
            default:    result = 32'd0;
        endcase
    end
endmodule
			
	