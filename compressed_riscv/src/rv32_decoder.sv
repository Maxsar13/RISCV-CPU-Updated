`include "definitions.vh"

module rv32_decoder (
    input  logic        valid,
    input  logic [31:0] instr,
	
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic [2:0]  funct3,
    output logic  [31:0] imm,
    output logic  [5:0]  alu_op,
    output logic         alu_src_pc,
    output logic         alu_src_imm,
    output logic         reg_write,
    output logic         mem_read,
    output logic         mem_write,
    output logic         branch,
    output logic         jump,
    output logic         jalr,
    output logic  [1:0]  result_sel,
    output logic         uses_rs1,
    output logic         uses_rs2,
    output logic         illegal,
    output logic         halt
);	

logic [6:0] opcode;  
assign opcode = instr[6:0];

logic [6:0] funct7;
assign funct7 = instr[31:25];

assign rs1 = instr[19:15];
assign rs2 = instr[24:20];
assign rd = instr[11:7];
assign funct3 = instr[14:12];

always_comb
begin
        // safe defaults
        imm = 32'd0;
        alu_op = `ALU_ADD;
        alu_src_pc = 1'b0;
        alu_src_imm = 1'b0;
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        jalr = 1'b0;
        result_sel = `RES_ALU;
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
        illegal = 1'b0;
        halt = 1'b0;

        if (!valid) begin
            illegal = 1'b0;
        end else begin
            case (opcode)
                // U-type
                `OPCODE_LUI: begin
                    imm = {instr[31:12], 12'd0};
                    alu_src_imm = 1'b1;
                    alu_op = `ALU_COPYB;
                    reg_write = 1'b1;
                end
                `OPCODE_AUIPC: begin
                    imm = {instr[31:12], 12'd0};
                    alu_src_pc = 1'b1;
                    alu_src_imm = 1'b1;
                    reg_write = 1'b1;
                end
                // jump imm
                `OPCODE_JAL: begin
                    imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                    jump = 1'b1;
                    reg_write = 1'b1;
                    result_sel = `RES_PC4;
                end
                // reg jump
                `OPCODE_JALR: begin
                    imm = {{20{instr[31]}}, instr[31:20]};
                    jump = 1'b1;
                    jalr = 1'b1;
                    reg_write = 1'b1;
                    result_sel = `RES_PC4;
                    uses_rs1 = 1'b1;
                    illegal = (funct3 != 3'b000);
                end
                // branch imm
                `OPCODE_BRANCH: begin
                    imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                    branch = 1'b1;
                    uses_rs1 = 1'b1;
                    uses_rs2 = 1'b1;
                end
                // loads
                `OPCODE_LOAD: begin
                    imm = {{20{instr[31]}}, instr[31:20]};
                    alu_src_imm = 1'b1;
                    reg_write = 1'b1;
                    mem_read = 1'b1;
                    result_sel = `RES_MEM;
                    uses_rs1 = 1'b1;
                    illegal = !((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) ||
                                (funct3 == 3'b100) || (funct3 == 3'b101));
                end
                // stores
                `OPCODE_STORE: begin
                    imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                    alu_src_imm = 1'b1;
                    mem_write = 1'b1;
                    uses_rs1 = 1'b1;
                    uses_rs2 = 1'b1;
                    illegal = !((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010));
                end
                // I-type ALU
                `OPCODE_OP_IMM: begin
                    imm = {{20{instr[31]}}, instr[31:20]};
                    alu_src_imm = 1'b1;
                    reg_write = 1'b1;
                    uses_rs1 = 1'b1;
                    case (funct3)
                        3'b000: alu_op = `ALU_ADD;
                        3'b010: alu_op = `ALU_SLT;
                        3'b011: alu_op = `ALU_SLTU;
                        3'b100: alu_op = `ALU_XOR;
                        3'b110: alu_op = `ALU_OR;
                        3'b111: alu_op = `ALU_AND;
                        3'b001: begin
                            // shamt imm
                            alu_op = `ALU_SLL;
                            imm = {27'd0, instr[24:20]};
                            illegal = (funct7 != 7'b0000000);
                        end
                        3'b101: begin
                            // srli/srai
                            alu_op = instr[30] ? `ALU_SRA : `ALU_SRL;
                            imm = {27'd0, instr[24:20]};
                            illegal = !((funct7 == 7'b0000000) || (funct7 == 7'b0100000));
                        end
                        default: illegal = 1'b1;
                    endcase
                end
                // R-type ALU
                `OPCODE_OP: begin
                    reg_write = 1'b1;
                    uses_rs1 = 1'b1;
                    uses_rs2 = 1'b1;
                    case (funct3)
                        3'b000: alu_op = (funct7 == 7'b0100000) ? `ALU_SUB : `ALU_ADD;
                        3'b001: alu_op = `ALU_SLL;
                        3'b010: alu_op = `ALU_SLT;
                        3'b011: alu_op = `ALU_SLTU;
                        3'b100: alu_op = `ALU_XOR;
                        3'b101: alu_op = instr[30] ? `ALU_SRA : `ALU_SRL;
                        3'b110: alu_op = `ALU_OR;
                        3'b111: alu_op = `ALU_AND;
                        default: illegal = 1'b1;
                    endcase
                    // funct7 filter
                    if (!((funct7 == 7'b0000000) || ((funct7 == 7'b0100000) &&
                        ((funct3 == 3'b000) || (funct3 == 3'b101)))))
                        illegal = 1'b1;
                end
                // fence as nop
                `OPCODE_MISC_MEM: begin
                    illegal = (funct3 != 3'b000);
                end
                `OPCODE_SYSTEM: begin
                    // halt-only SYSTEM
                    halt = (instr == 32'h0010_0073) || (instr == 32'h0000_0073);
                    illegal = !halt;
                end
                default: illegal = 1'b1;
            endcase
        end
    end
endmodule