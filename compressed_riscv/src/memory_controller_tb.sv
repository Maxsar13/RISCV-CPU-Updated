`timescale 1ns/1ps


module tb_memory_controller;

    localparam int LATENCY = 3;     // bridge read latency in cycles

    // -------------------------------------------------------------
    // clock / reset
    // -------------------------------------------------------------
    logic clk = 0;
    logic rst = 1;
    always #5 clk = ~clk;

    // -------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------
    logic        i_req_valid = 0;
    logic [31:0] i_req_addr  = 0;
    logic        i_req_ready;
    logic        i_resp_valid;
    logic [63:0] i_resp_data;

    logic        d_req_valid = 0;
    logic        d_req_write = 0;
    logic [31:0] d_req_addr  = 0;
    logic [31:0] d_req_wdata = 0;
    logic [3:0]  d_req_wstrb = 0;
    logic        d_req_ready;
    logic        d_resp_valid;
    logic [63:0] d_resp_data;

    logic        mem_req_ready;
    logic        mem_resp_valid;
    logic [63:0] mem_resp_data;

    logic        mem_req_valid;
    logic        mem_req_write;
    logic [31:0] mem_req_addr;
    logic [31:0] mem_req_wdata;
    logic [3:0]  mem_req_wstrb;

    memory_controller dut (.*);

    // -------------------------------------------------------------
    // Fake bridge
    // -------------------------------------------------------------
    logic [63:0] mem [0:255];        // 256 lines x 64 bits = 2KB
    logic        stall_ready = 0;    // test can hold ready low to model a busy bridge

    typedef enum logic [1:0] {B_IDLE, B_LAT} bstate_t;
    bstate_t bstate = B_IDLE;
    int          lat_cnt;
    logic [7:0]  pend_line;

    int bridge_reads  = 0;
    int bridge_writes = 0;

    // ready only while idle, like the real bridge
    assign mem_req_ready = (bstate == B_IDLE) && !stall_ready;

    always @(posedge clk) begin
        mem_resp_valid <= 1'b0;
        if (rst) begin
            bstate <= B_IDLE;
        end else begin
            case (bstate)
                B_IDLE: if (mem_req_valid && mem_req_ready) begin
                    // the real bridge silently ignores a request while its response is out
                    if (mem_resp_valid)
                        fail("bridge: request arrived while response was out (would be dropped)");
                    if (mem_req_write) begin
                        bridge_writes++;
                        for (int b = 0; b < 4; b++)
                            if (mem_req_wstrb[b]) begin
                                if (mem_req_addr[2])
                                    mem[mem_req_addr[10:3]][32+8*b +: 8] <= mem_req_wdata[8*b +: 8];
                                else
                                    mem[mem_req_addr[10:3]][8*b +: 8]    <= mem_req_wdata[8*b +: 8];
                            end
                    end else begin
                        bridge_reads++;
                        if (mem_req_addr[2:0] != 3'b000)
                            fail($sformatf("read address 0x%08h not line-aligned", mem_req_addr));
                        pend_line <= mem_req_addr[10:3];
                        lat_cnt   <= LATENCY;
                        bstate    <= B_LAT;
                    end
                end
                B_LAT: begin
                    if (lat_cnt == 1) begin
                        mem_resp_valid <= 1'b1;
                        mem_resp_data  <= mem[pend_line];
                        bstate         <= B_IDLE;
                    end
                    lat_cnt <= lat_cnt - 1;
                end
            endcase
        end
    end

    // reference model: what each line *should* hold
    logic [63:0] ref_mem [0:255];

    function automatic logic [63:0] init_line(int i);
        // low word = word index (2i), high word = 2i+1, tagged so it's recognizable
        logic [31:0] lo, hi;
        lo = 32'hC0DE_0000 | 32'(2*i);
        hi = 32'hC0DE_0000 | 32'(2*i+1);
        return {hi, lo};
    endfunction

    // -------------------------------------------------------------
    // Pass/fail bookkeeping
    // -------------------------------------------------------------
    int passes = 0;
    int fails  = 0;

    function automatic void pass(string msg);
        passes++;
        $display("  PASS  %s", msg);
    endfunction

    function automatic void fail(string msg);
        fails++;
        $display("  FAIL  %s  (t=%0t)", msg, $time);
    endfunction

    // -------------------------------------------------------------
    // Monitors (run the whole simulation)
    // -------------------------------------------------------------
    int  i_resp_count = 0;
    int  d_resp_count = 0;
    string grant_log = "";

    always @(posedge clk) if (!rst) begin
        // only one side can ever get a response at a time
        if (i_resp_valid && d_resp_valid)
            fail("i_resp_valid and d_resp_valid high together");

        // only one side can ever be granted at a time
        if (i_req_ready && d_req_ready)
            fail("i_req_ready and d_req_ready high together");

        // after the bridge accepts a read, the MC must drop mem_req_valid
        if (dut.state == 2'd2 && mem_req_valid)
            fail("mem_req_valid still high in READ_DATA");

        if (i_resp_valid) i_resp_count++;
        if (d_resp_valid) d_resp_count++;

        // record which side won each accept, for the round-robin test
        if (i_req_valid && i_req_ready) grant_log = {grant_log, "I"};
        if (d_req_valid && d_req_ready) grant_log = {grant_log, "D"};
    end

    // -------------------------------------------------------------
    // Drivers — behave like the imem / dmem arbiters
    //   drive on negedge, sample on posedge, so there are no races
    //   after the request is accepted, scramble the inputs to prove
    //   the MC latched them and isn't reading the live wires
    // -------------------------------------------------------------
    task automatic imem_read(input logic [31:0] addr, output logic [63:0] data);
        @(negedge clk);
        i_req_valid = 1;
        i_req_addr  = addr;
        do @(posedge clk); while (!i_req_ready);
        @(negedge clk);
        i_req_valid = 0;
        i_req_addr  = 32'hDEAD_DEAD;         // scramble after accept
        do @(posedge clk); while (!i_resp_valid);
        data = i_resp_data;
    endtask

    task automatic dmem_read(input logic [31:0] addr, output logic [63:0] data);
        @(negedge clk);
        d_req_valid = 1;
        d_req_write = 0;
        d_req_addr  = addr;
        do @(posedge clk); while (!d_req_ready);
        @(negedge clk);
        d_req_valid = 0;
        d_req_addr  = 32'hDEAD_DEAD;
        do @(posedge clk); while (!d_resp_valid);
        data = d_resp_data;
    endtask

    task automatic dmem_write(input logic [31:0] addr, input logic [31:0] wdata,
                              input logic [3:0] wstrb);
        @(negedge clk);
        d_req_valid = 1;
        d_req_write = 1;
        d_req_addr  = addr;
        d_req_wdata = wdata;
        d_req_wstrb = wstrb;
        do @(posedge clk); while (!d_req_ready);
        @(negedge clk);
        d_req_valid = 0;
        d_req_write = 0;
        d_req_addr  = 32'hDEAD_DEAD;         // scramble after accept
        d_req_wdata = 32'hBAD0_BAD0;
        d_req_wstrb = 4'hF;
        // update the reference model the same way the bridge should
        for (int b = 0; b < 4; b++)
            if (wstrb[b]) begin
                if (addr[2]) ref_mem[addr[10:3]][32+8*b +: 8] = wdata[8*b +: 8];
                else         ref_mem[addr[10:3]][8*b +: 8]    = wdata[8*b +: 8];
            end
        // wait for the MC to finish handing the write to the bridge
        do @(posedge clk); while (dut.state != 2'd0);
    endtask

    function automatic void check_line(string name, logic [31:0] addr, logic [63:0] got);
        logic [63:0] exp;
        exp = ref_mem[addr[10:3]];
        if (got === exp) pass($sformatf("%s 0x%08h -> %h", name, addr, got));
        else             fail($sformatf("%s 0x%08h: got %h expected %h", name, addr, got, exp));
    endfunction

    // -------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------
    logic [63:0] rdata, rdata2;
    int i_before, d_before, r_before, w_before;

    initial begin
        for (int i = 0; i < 256; i++) begin
            mem[i]     = init_line(i);
            ref_mem[i] = init_line(i);
        end

        repeat (3) @(posedge clk);
        rst = 0;
        repeat (2) @(posedge clk);

        // ---------------------------------------------------------
        $display("\n[1] imem read alone");
        imem_read(32'h0000_0100, rdata);
        check_line("imem", 32'h0000_0100, rdata);
        imem_read(32'h0000_0104, rdata);           // word 1 of the same line
        check_line("imem (word_sel=1)", 32'h0000_0104, rdata);

        // ---------------------------------------------------------
        $display("\n[2] dmem read alone");
        dmem_read(32'h0000_0200, rdata);
        check_line("dmem", 32'h0000_0200, rdata);

        // ---------------------------------------------------------
        $display("\n[3] dmem write, then read back");
        i_before = i_resp_count; d_before = d_resp_count;
        dmem_write(32'h0000_0204, 32'hDEAD_BEEF, 4'b1111);   // full word, upper half
        if (d_resp_count == d_before && i_resp_count == i_before)
            pass("write produced no response");
        else
            fail("write produced a response");
        dmem_read(32'h0000_0200, rdata);
        check_line("readback after full-word write", 32'h0000_0200, rdata);

        dmem_write(32'h0000_0208, 32'h0000_AB00, 4'b0010);   // single byte, lower half
        dmem_read(32'h0000_0208, rdata);
        check_line("readback after byte write", 32'h0000_0208, rdata);

        // ---------------------------------------------------------
        $display("\n[4] both sides request in the same cycle (round-robin)");
        grant_log = "";
        repeat (3) begin
            fork
                imem_read(32'h0000_0300, rdata);
                dmem_read(32'h0000_0400, rdata2);
            join
            check_line("contended imem", 32'h0000_0300, rdata);
            check_line("contended dmem", 32'h0000_0400, rdata2);
        end
        // across 3 contended pairs, wins should alternate: never the same side twice in a row
        begin
            logic ok;
            ok = 1;
            for (int k = 1; k < grant_log.len(); k++)
                if (grant_log[k] == grant_log[k-1]) ok = 0;
            if (ok && grant_log.len() == 6)
                pass($sformatf("grants alternate: %s", grant_log));
            else
                fail($sformatf("grants did not alternate: %s", grant_log));
        end

        // ---------------------------------------------------------
        $display("\n[5] bridge busy: mem_req_ready held low");
        stall_ready = 1;
        fork
            imem_read(32'h0000_0500, rdata);
            begin
                repeat (6) @(posedge clk);
                if (mem_req_valid)
                    pass("MC held mem_req_valid while bridge was busy");
                else
                    fail("MC dropped mem_req_valid while bridge was busy");
                @(negedge clk);
                stall_ready = 0;
            end
        join
        check_line("read after stall", 32'h0000_0500, rdata);

        // ---------------------------------------------------------
        $display("\n[6] back-to-back reads: every request gets exactly one response");
        i_before = i_resp_count; d_before = d_resp_count; r_before = bridge_reads;
        for (int k = 0; k < 8; k++) begin
            if (k % 2 == 0) begin
                imem_read(32'h0000_0600 + 8*k, rdata);
                check_line("b2b imem", 32'h0000_0600 + 8*k, rdata);
            end else begin
                dmem_read(32'h0000_0600 + 8*k, rdata);
                check_line("b2b dmem", 32'h0000_0600 + 8*k, rdata);
            end
        end
        if (i_resp_count - i_before == 4 && d_resp_count - d_before == 4)
            pass("4 imem + 4 dmem responses, none extra");
        else
            fail($sformatf("response counts wrong: imem %0d dmem %0d",
                           i_resp_count - i_before, d_resp_count - d_before));
        if (bridge_reads - r_before == 8)
            pass("bridge saw exactly 8 reads (no duplicates)");
        else
            fail($sformatf("bridge saw %0d reads, expected 8", bridge_reads - r_before));

        // ---------------------------------------------------------
        $display("\n[7] write and read contending in the same cycle");
        fork
            dmem_write(32'h0000_0700, 32'h1234_5678, 4'b1111);
            imem_read(32'h0000_0710, rdata);
        join
        check_line("imem during write", 32'h0000_0710, rdata);
        dmem_read(32'h0000_0700, rdata);
        check_line("readback of contended write", 32'h0000_0700, rdata);

        // ---------------------------------------------------------
        repeat (5) @(posedge clk);
        $display("\n==========================================");
        $display("  %0d passed, %0d failed", passes, fails);
        $display("  bridge totals: %0d reads, %0d writes", bridge_reads, bridge_writes);
        if (fails == 0) $display("  ALL TESTS PASSED");
        else            $display("  SOME TESTS FAILED");
        $display("==========================================\n");
        $finish;
    end

    // watchdog — a hung handshake fails instead of running forever
    initial begin
        #200000;
        $display("  FAIL  watchdog timeout — a handshake never completed");
        $finish;
    end

endmodule