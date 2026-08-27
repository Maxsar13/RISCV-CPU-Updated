`timescale 1ns/1ps
`include "definitions.vh"
 

// Loads a program image where BOTH cores read the hardware perf counters
// (per-core cycle/instr via 0xFFFFFFxx, system bus-contention via 0xF0000004)
// and store their results to separate memory regions:
//   Core 0 results @ 0x780 (word 640): [id, cycles, instrs, bus_contention]
//   Core 1 results @ 0x7C0 (word 672): [id, cycles, instrs, bus_contention]
//
// To run YOUR compiled C: replace HEXFILE with your compiled program's hex,
// making sure core0 code starts at word 0 and core1 code at word 512, and
// that each core stores its perf results to 0xA00 / 0xA80 respectively.
 
module tb_dual_core_top;
    parameter string HEXFILE = "dual_core_program.hex";
 
    reg clk = 0, rst = 1;
    integer cycle;
 
    wire [31:0] pc_debug_0, pc_debug_1;
    wire        halted_0, halted_1, trap_0, trap_1;
 
    dual_core_top dut (
        .clk(clk), .rst(rst),
        .pc_debug_0(pc_debug_0), .pc_debug_1(pc_debug_1),
        .halted_0(halted_0), .halted_1(halted_1),
        .trap_0(trap_0), .trap_1(trap_1)
    );
 
    // memory result-word accessors (unified mem[] array)
    localparam int C0 = 480;  // 0x780/4
    localparam int C1 = 496;  // 0x7C0/4
 
    always #5 clk = ~clk;
 
    initial $readmemh(HEXFILE, dut.mem.mem);
 
    initial begin
        rst = 1;
        repeat(4) @(posedge clk);
        rst = 0;
        for (cycle = 0; cycle < 5000 && !(halted_0 && halted_1); cycle = cycle + 1)
            @(posedge clk);
        #1;
 
        $display("========================================");
        $display(" Dual-core software perf-counter results");
        $display("========================================");
        $display(" ran %0d cycles | halted_0=%b halted_1=%b", cycle, halted_0, halted_1);
        $display("");
        $display(" CORE 0 (results @ 0x780):");
        $display("   core id        = %0d", dut.mem.mem[C0+0]);
        $display("   measured cycles= %0d", dut.mem.mem[C0+1]);
        $display("   instr count    = %0d", dut.mem.mem[C0+2]);
        $display("   bus contention = %0d", dut.mem.mem[C0+3]);
        $display("");
        $display(" CORE 1 (results @ 0x7C0):");
        $display("   core id        = %0d", dut.mem.mem[C1+0]);
        $display("   measured cycles= %0d", dut.mem.mem[C1+1]);
        $display("   instr count    = %0d", dut.mem.mem[C1+2]);
        $display("   bus contention = %0d", dut.mem.mem[C1+3]);
        $display("========================================");
        $finish;
    end
endmodule