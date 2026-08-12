`include "definitions.vh"

// dual core top level
// two RV32I cores sharing one memory
module dual_core_top #(
    parameter CORE0_RESET_VECTOR = 32'h0000_0000,
    parameter CORE1_RESET_VECTOR = 32'h0000_0800
)(
    input wire clk,
    input wire rst,

    // debug outputs
    output wire [31:0] pc_debug_0,
    output wire [31:0] pc_debug_1,
    output wire        halted_0,
    output wire        halted_1,
    output wire        trap_0,
    output wire        trap_1
);

    // ─── core 0 imem wires ───
    wire        imem_req_valid_0;
    wire [31:0] imem_req_addr_0;
    wire        imem_req_ready_0;
    wire        imem_resp_valid_0;
    wire [31:0] imem_resp_data_0;

    // ─── core 0 dmem wires ───
    wire        dmem_req_valid_0;
    wire        dmem_req_write_0;
    wire [31:0] dmem_req_addr_0;
    wire [31:0] dmem_req_wdata_0;
    wire [3:0]  dmem_req_wstrb_0;
    wire        dmem_req_ready_0;
    wire        dmem_resp_valid_0;
    wire [31:0] dmem_resp_rdata_0;

    // ─── core 1 imem wires ───
    wire        imem_req_valid_1;
    wire [31:0] imem_req_addr_1;
    wire        imem_req_ready_1;
    wire        imem_resp_valid_1;
    wire [31:0] imem_resp_data_1;

    // ─── core 1 dmem wires ───
    wire        dmem_req_valid_1;
    wire        dmem_req_write_1;
    wire [31:0] dmem_req_addr_1;
    wire [31:0] dmem_req_wdata_1;
    wire [3:0]  dmem_req_wstrb_1;
    wire        dmem_req_ready_1;
    wire        dmem_resp_valid_1;
    wire [31:0] dmem_resp_rdata_1;

    // ─── memory wires ───
    wire        imem_req_valid_m;
    wire [31:0] imem_req_addr_m;
    wire        imem_req_ready_m;
    wire        imem_resp_valid_m;
    wire [31:0] imem_resp_data_m;

    wire        dmem_req_valid_m;
    wire        dmem_req_write_m;
    wire [31:0] dmem_req_addr_m;
    wire [31:0] dmem_req_wdata_m;
    wire [3:0]  dmem_req_wstrb_m;
    wire        dmem_req_ready_m;
    wire        dmem_resp_valid_m;
    wire [31:0] dmem_resp_rdata_m;

    // ─── core 0 ───
    cpu_top #(
        .RESET_VECTOR(CORE0_RESET_VECTOR)
    ) core0 (
        .clk             (clk),
        .rst             (rst),
        .imem_req_valid  (imem_req_valid_0),
        .imem_req_addr   (imem_req_addr_0),
        .imem_req_ready  (imem_req_ready_0),
        .imem_resp_valid (imem_resp_valid_0),
        .imem_resp_data  (imem_resp_data_0),
        .dmem_req_valid  (dmem_req_valid_0),
        .dmem_req_write  (dmem_req_write_0),
        .dmem_req_addr   (dmem_req_addr_0),
        .dmem_req_wdata  (dmem_req_wdata_0),
        .dmem_req_wstrb  (dmem_req_wstrb_0),
        .dmem_req_ready  (dmem_req_ready_0),
        .dmem_resp_valid (dmem_resp_valid_0),
        .dmem_resp_rdata (dmem_resp_rdata_0),
        .pc_debug        (pc_debug_0),
        .instr_debug     (),
        .halted          (halted_0),
        .trap            (trap_0),
        .trap_pc         (),
        .retired_debug   ()
    );

    // ─── core 1 ───
    cpu_top #(
        .RESET_VECTOR(CORE1_RESET_VECTOR)
    ) core1 (
        .clk             (clk),
        .rst             (rst),
        .imem_req_valid  (imem_req_valid_1),
        .imem_req_addr   (imem_req_addr_1),
        .imem_req_ready  (imem_req_ready_1),
        .imem_resp_valid (imem_resp_valid_1),
        .imem_resp_data  (imem_resp_data_1),
        .dmem_req_valid  (dmem_req_valid_1),
        .dmem_req_write  (dmem_req_write_1),
        .dmem_req_addr   (dmem_req_addr_1),
        .dmem_req_wdata  (dmem_req_wdata_1),
        .dmem_req_wstrb  (dmem_req_wstrb_1),
        .dmem_req_ready  (dmem_req_ready_1),
        .dmem_resp_valid (dmem_resp_valid_1),
        .dmem_resp_rdata (dmem_resp_rdata_1),
        .pc_debug        (pc_debug_1),
        .instr_debug     (),
        .halted          (halted_1),
        .trap            (trap_1),
        .trap_pc         (),
        .retired_debug   ()
    );

    // ─── imem arbiter ───
    imem_arbiter imem_arb (
        .clk              (clk),
        .rst              (rst),
        .imem_req_valid_0 (imem_req_valid_0),
        .imem_req_addr_0  (imem_req_addr_0),
        .imem_req_ready_0 (imem_req_ready_0),
        .imem_resp_valid_0(imem_resp_valid_0),
        .imem_resp_data_0 (imem_resp_data_0),
        .imem_req_valid_1 (imem_req_valid_1),
        .imem_req_addr_1  (imem_req_addr_1),
        .imem_req_ready_1 (imem_req_ready_1),
        .imem_resp_valid_1(imem_resp_valid_1),
        .imem_resp_data_1 (imem_resp_data_1),
        .imem_req_valid   (imem_req_valid_m),
        .imem_req_addr    (imem_req_addr_m),
        .imem_req_ready   (imem_req_ready_m),
        .imem_resp_valid  (imem_resp_valid_m),
        .imem_resp_data   (imem_resp_data_m)
    );

    // ─── dmem arbiter ───
    wire [31:0] core_id_rdata_0, core_id_rdata_1;
    wire        core_id_valid_0, core_id_valid_1;

    dmem_arbiter dmem_arb (
        .clk              (clk),
        .rst              (rst),
        .dmem_req_valid_0 (dmem_req_valid_0),
        .dmem_req_write_0 (dmem_req_write_0),
        .dmem_req_addr_0  (dmem_req_addr_0),
        .dmem_req_wdata_0 (dmem_req_wdata_0),
        .dmem_req_wstrb_0 (dmem_req_wstrb_0),
        .dmem_req_ready_0 (dmem_req_ready_0),
        .dmem_resp_valid_0(dmem_resp_valid_0),
        .dmem_resp_rdata_0(dmem_resp_rdata_0),
        .dmem_req_valid_1 (dmem_req_valid_1),
        .dmem_req_write_1 (dmem_req_write_1),
        .dmem_req_addr_1  (dmem_req_addr_1),
        .dmem_req_wdata_1 (dmem_req_wdata_1),
        .dmem_req_wstrb_1 (dmem_req_wstrb_1),
        .dmem_req_ready_1 (dmem_req_ready_1),
        .dmem_resp_valid_1(dmem_resp_valid_1),
        .dmem_resp_rdata_1(dmem_resp_rdata_1),
        .dmem_req_valid   (dmem_req_valid_m),
        .dmem_req_write   (dmem_req_write_m),
        .dmem_req_addr    (dmem_req_addr_m),
        .dmem_req_wdata   (dmem_req_wdata_m),
        .dmem_req_wstrb   (dmem_req_wstrb_m),
        .dmem_req_ready   (dmem_req_ready_m),
        .dmem_resp_valid  (dmem_resp_valid_m),
        .dmem_resp_rdata  (dmem_resp_rdata_m),
        .core_id_rdata_0  (core_id_rdata_0),
        .core_id_valid_0  (core_id_valid_0),
        .core_id_rdata_1  (core_id_rdata_1),
        .core_id_valid_1  (core_id_valid_1)
    );

   sim_memory #(
        .WORDS(1024)
    ) mem (
        .clk             (clk),
        .imem_req_valid  (imem_req_valid_m),
        .imem_req_addr   (imem_req_addr_m),
        .imem_req_ready  (imem_req_ready_m),
        .imem_resp_valid (imem_resp_valid_m),
        .imem_resp_data  (imem_resp_data_m),
        .dmem_req_valid  (dmem_req_valid_m),
        .dmem_req_write  (dmem_req_write_m),
        .dmem_req_addr   (dmem_req_addr_m),
        .dmem_req_wdata  (dmem_req_wdata_m),
        .dmem_req_wstrb  (dmem_req_wstrb_m),
        .dmem_req_ready  (dmem_req_ready_m),
        .dmem_resp_valid (dmem_resp_valid_m),
        .dmem_resp_rdata (dmem_resp_rdata_m)
    );

endmodule
