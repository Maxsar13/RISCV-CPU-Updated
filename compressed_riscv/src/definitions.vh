`ifndef DEFINITIONS_VH
`define DEFINITIONS_VH

// shared RV32I constants

// base opcodes
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_JAL      7'b1101111
`define OPCODE_JALR     7'b1100111
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_STORE    7'b0100011
`define OPCODE_OP_IMM   7'b0010011
`define OPCODE_OP       7'b0110011
`define OPCODE_MISC_MEM 7'b0001111
`define OPCODE_SYSTEM   7'b1110011

// old aliases
`define OPCODE_LW       `OPCODE_LOAD
`define OPCODE_SW       `OPCODE_STORE
`define OPCODE_BTYPE    `OPCODE_BRANCH
`define OPCODE_ITYPE    `OPCODE_OP_IMM
`define OPCODE_RTYPE    `OPCODE_OP

// ALU ops
`define ALU_ADD   6'd0
`define ALU_SUB   6'd1
`define ALU_AND   6'd2
`define ALU_OR    6'd3
`define ALU_XOR   6'd4
`define ALU_SLL   6'd5
`define ALU_SRL   6'd6
`define ALU_SRA   6'd7
`define ALU_SLT   6'd8
`define ALU_SLTU  6'd9
`define ALU_COPYB 6'd10

// branch funct3
`define BRANCH_BEQ      3'b000
`define BRANCH_BNE      3'b001
`define BRANCH_BLT      3'b100
`define BRANCH_BGE      3'b101
`define BRANCH_BLTU     3'b110
`define BRANCH_BGEU     3'b111
`define BRANCH_JAL      3'b010

// wb mux
`define RES_ALU 2'd0
`define RES_MEM 2'd1
`define RES_PC4 2'd2 

//Counters
`define COUNTER_BASE 32'hFFFF_FFF0
`define CYCLE_COUNT 32'hFFFF_FFF4
`define STALL_COUNT 32'hFFFF_FFF8
`define INSTR_COUNT 32'hFFFF_FFFC

`endif