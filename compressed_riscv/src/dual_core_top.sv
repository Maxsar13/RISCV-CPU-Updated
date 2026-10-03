`include "definitions.vh"

// dual core top level
// two RV32I cores sharing one memory
module dual_core_top #(
    parameter CORE0_RESET_VECTOR = 32'h0000_0000,
    parameter CORE1_RESET_VECTOR = 32'h0000_0800
)(
    input logic clk,
    input logic rst,

    // debug outputs
    output logic [31:0] pc_debug_0,
    output logic [31:0] pc_debug_1,
    output logic        halted_0,
    output logic        halted_1,
    output logic        trap_0,
    output logic        trap_1,

    // shared memory interface; simulation testbenches provide tb_memory,
    // while FPGA/system tops provide BRAM-backed memories.
    output logic        imem_req_valid,
    output logic [31:0] imem_req_addr,
    input  logic        imem_req_ready,
    input  logic        imem_resp_valid,
    input  logic [31:0] imem_resp_data,
    output logic        dmem_req_valid,
    output logic        dmem_req_write,
    output logic [31:0] dmem_req_addr,
    output logic [31:0] dmem_req_wdata,
    output logic [3:0]  dmem_req_wstrb,
    input  logic        dmem_req_ready,
    input  logic        dmem_resp_valid,
    input  logic [31:0] dmem_resp_rdata
);

    // --- core 0 imem wires ---
    logic        imem_req_valid_0;
    logic [31:0] imem_req_addr_0;
    logic        imem_req_ready_0;
    logic        imem_resp_valid_0;
    logic [31:0] imem_resp_data_0;

    // --- core 0 dmem wires ---
    logic        dmem_req_valid_0;
    logic        dmem_req_write_0;
    logic [31:0] dmem_req_addr_0;
    logic [31:0] dmem_req_wdata_0;
    logic [3:0]  dmem_req_wstrb_0;
    logic        dmem_req_ready_0;
    logic        dmem_resp_valid_0;
    logic [31:0] dmem_resp_rdata_0;

    // --- core 1 imem wires ---
    logic        imem_req_valid_1;
    logic [31:0] imem_req_addr_1;
    logic        imem_req_ready_1;
    logic        imem_resp_valid_1;
    logic [31:0] imem_resp_data_1;

    // --- core 1 dmem wires ---
    logic        dmem_req_valid_1;
    logic        dmem_req_write_1;
    logic [31:0] dmem_req_addr_1;
    logic [31:0] dmem_req_wdata_1;
    logic [3:0]  dmem_req_wstrb_1;
    logic        dmem_req_ready_1;
    logic        dmem_resp_valid_1;
    logic [31:0] dmem_resp_rdata_1;

    // --- memory wires ---
    logic        imem_req_valid_m;
    logic [31:0] imem_req_addr_m;
    logic        imem_req_ready_m;
    logic        imem_resp_valid_m;
    logic [31:0] imem_resp_data_m;

    logic        dmem_req_valid_m;
    logic        dmem_req_write_m;
    logic [31:0] dmem_req_addr_m;
    logic [31:0] dmem_req_wdata_m;
    logic [3:0]  dmem_req_wstrb_m;
    logic        dmem_req_ready_m;
    logic        dmem_resp_valid_m;
    logic [31:0] dmem_resp_rdata_m;


    // --- lock unit wires ---
    // connects the dmem arbiter MMIO path to the shared lock
    logic        lock_req_0;
    logic        lock_write_0;
    logic [31:0] lock_addr_0;
    logic [31:0] lock_wdata_0;
    logic        lock_ready_0;
    logic        lock_resp_valid_0;
    logic [31:0] lock_rdata_0;

    logic        lock_req_1;
    logic        lock_write_1;
    logic [31:0] lock_addr_1;
    logic [31:0] lock_wdata_1;
    logic        lock_ready_1;
    logic        lock_resp_valid_1;
    logic [31:0] lock_rdata_1;

    // lock status for debug / verification
    logic        lock_locked;
    logic        lock_owner;


    // --- core 0 ---
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

    // --- core 1 ---
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

    // --- imem arbiter ---
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

    // --- dmem arbiter ---
    logic [31:0] core_id_rdata_0, core_id_rdata_1;
    logic        core_id_valid_0, core_id_valid_1;

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
        .core_id_valid_1  (core_id_valid_1),

        // MMIO — lock unit
        .lock_req_0       (lock_req_0),
        .lock_write_0     (lock_write_0),
        .lock_addr_0      (lock_addr_0),
        .lock_wdata_0     (lock_wdata_0),
        .lock_ready_0     (lock_ready_0),
        .lock_resp_valid_0(lock_resp_valid_0),
        .lock_rdata_0     (lock_rdata_0),

        .lock_req_1       (lock_req_1),
        .lock_write_1     (lock_write_1),
        .lock_addr_1      (lock_addr_1),
        .lock_wdata_1     (lock_wdata_1),
        .lock_ready_1     (lock_ready_1),
        .lock_resp_valid_1(lock_resp_valid_1),
        .lock_rdata_1     (lock_rdata_1),
        .lock_locked      (lock_locked),
        .lock_owner       (lock_owner)
    );


    // --- MMIO lock unit ---
    // shared atomic spinlock at 0xF0000010
    lock_unit #(
        .LOCK_ADDR(32'hF000_0010)
    ) lock0 (
        .clk         (clk),
        .rst         (rst),

        .req_0       (lock_req_0),
        .write_0     (lock_write_0),
        .addr_0      (lock_addr_0),
        .wdata_0     (lock_wdata_0),
        .ready_0     (lock_ready_0),
        .resp_valid_0(lock_resp_valid_0),
        .rdata_0     (lock_rdata_0),

        .req_1       (lock_req_1),
        .write_1     (lock_write_1),
        .addr_1      (lock_addr_1),
        .wdata_1     (lock_wdata_1),
        .ready_1     (lock_ready_1),
        .resp_valid_1(lock_resp_valid_1),
        .rdata_1     (lock_rdata_1),

        .locked      (lock_locked),
        .owner       (lock_owner)
    );


    assign imem_req_valid = imem_req_valid_m;
    assign imem_req_addr = imem_req_addr_m;
    assign imem_req_ready_m = imem_req_ready;
    assign imem_resp_valid_m = imem_resp_valid;
    assign imem_resp_data_m = imem_resp_data;

    assign dmem_req_valid = dmem_req_valid_m;
    assign dmem_req_write = dmem_req_write_m;
    assign dmem_req_addr = dmem_req_addr_m;
    assign dmem_req_wdata = dmem_req_wdata_m;
    assign dmem_req_wstrb = dmem_req_wstrb_m;
    assign dmem_req_ready_m = dmem_req_ready;
    assign dmem_resp_valid_m = dmem_resp_valid;
    assign dmem_resp_rdata_m = dmem_resp_rdata;

endmodule