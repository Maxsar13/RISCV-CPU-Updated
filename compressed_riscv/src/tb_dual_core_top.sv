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
    parameter string HEXFILE = "dual_core_test.hex";
 
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
    initial begin
        $readmemh(HEXFILE, dut.mem.mem);
        $display("LOADED CHECK: mem[0]=%08h mem[11]=%08h mem[45]=%08h mem[512]=%08h",
            dut.mem.mem[0], dut.mem.mem[11], dut.mem.mem[45], dut.mem.mem[512]);
    end
 
 initial begin
    rst = 1;
    repeat(4) @(posedge clk);
    rst = 0;
    for (cycle = 0; cycle < 5000 && !(halted_0 && halted_1); cycle = cycle + 1) begin
        @(posedge clk);
        if (pc_debug_0 == 32'h000000b0)
            $display("cyc=%0d pc0=%08h | memstall=%b lustall=%b fetch_en=%b resp0=%b iresp=%b",
                cycle, pc_debug_0,
                dut.core0.memory_stall,
                dut.core0.load_use_stall,
                dut.core0.fetch_enable,
                dut.dmem_arb.dmem_resp_valid_0,
                dut.imem_arb.imem_resp_valid_0);
    end
    $display("done: h0=%b h1=%b pc0=%08h", halted_0, halted_1, pc_debug_0);
    $finish;
    end
endmodule