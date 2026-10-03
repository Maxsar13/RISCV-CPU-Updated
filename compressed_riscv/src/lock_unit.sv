module lock_unit #(
    parameter logic [31:0] LOCK_ADDR = 32'hF000_0010
)(
    input  logic        clk,
    input  logic        rst,

    // -------------------------
    // Core 0 request
    // -------------------------
    input  logic        req_0,
    input  logic        write_0,
    input  logic [31:0] addr_0,
    input  logic [31:0] wdata_0,

    output logic        ready_0,
    output logic        resp_valid_0,
    output logic [31:0] rdata_0,

    // -------------------------
    // Core 1 request
    // -------------------------
    input  logic        req_1,
    input  logic        write_1,
    input  logic [31:0] addr_1,
    input  logic [31:0] wdata_1,

    output logic        ready_1,
    output logic        resp_valid_1,
    output logic [31:0] rdata_1,

    // -------------------------
    // Debug/status
    // -------------------------
    output logic        locked,
    output logic        owner
);

    // 0 = free
    // 1 = locked
    logic lock_reg;

    // 0 = Core 0 owns lock
    // 1 = Core 1 owns lock
    logic owner_reg;

    // Round-robin priority used only when BOTH cores
    // try to acquire a free lock simultaneously.
    //
    // 0 = Core 0 gets priority
    // 1 = Core 1 gets priority
    logic rr_priority;

    logic lock_req_0;
    logic lock_req_1;

    logic acquire_0;
    logic acquire_1;

    logic release_0;
    logic release_1;

    logic grant_0;
    logic grant_1;

    // --------------------------------------------------
    // MMIO address decode
    // --------------------------------------------------

    assign lock_req_0 =
        req_0 &&
        (addr_0 == LOCK_ADDR);

    assign lock_req_1 =
        req_1 &&
        (addr_1 == LOCK_ADDR);

    // READ = atomic acquire attempt
    assign acquire_0 =
        lock_req_0 &&
        !write_0;

    assign acquire_1 =
        lock_req_1 &&
        !write_1;

    // WRITE 0 = release attempt
    assign release_0 =
        lock_req_0 &&
        write_0 &&
        (wdata_0 == 32'd0);

    assign release_1 =
        lock_req_1 &&
        write_1 &&
        (wdata_1 == 32'd0);

    // --------------------------------------------------
    // Acquire arbitration
    // --------------------------------------------------
    //
    // If only one core requests the lock, that core
    // gets the acquire attempt.
    //
    // If both request simultaneously, round-robin
    // decides which core gets the successful attempt.
    // --------------------------------------------------

    always_comb begin
        grant_0 = 1'b0;
        grant_1 = 1'b0;

        if (acquire_0 && acquire_1) begin
            if (rr_priority == 1'b0)
                grant_0 = 1'b1;
            else
                grant_1 = 1'b1;
        end
        else if (acquire_0) begin
            grant_0 = 1'b1;
        end
        else if (acquire_1) begin
            grant_1 = 1'b1;
        end
    end

    // --------------------------------------------------
    // MMIO responses
    // --------------------------------------------------
    //
    // ACQUIRE READ RESULT:
    //
    // 0 = success
    // 1 = busy / failed
    // --------------------------------------------------

    always_comb begin
        ready_0      = 1'b0;
        ready_1      = 1'b0;

        resp_valid_0 = 1'b0;
        resp_valid_1 = 1'b0;

        rdata_0      = 32'd0;
        rdata_1      = 32'd0;

        // -------------------------
        // Core 0 response
        // -------------------------
        if (lock_req_0) begin
            ready_0      = 1'b1;
            resp_valid_0 = 1'b1;

            if (acquire_0) begin
                if (!lock_reg && grant_0)
                    rdata_0 = 32'd0;   // success
                else
                    rdata_0 = 32'd1;   // busy
            end
        end

        // -------------------------
        // Core 1 response
        // -------------------------
        if (lock_req_1) begin
            ready_1      = 1'b1;
            resp_valid_1 = 1'b1;

            if (acquire_1) begin
                if (!lock_reg && grant_1)
                    rdata_1 = 32'd0;   // success
                else
                    rdata_1 = 32'd1;   // busy
            end
        end
    end

    // --------------------------------------------------
    // Lock state update
    // --------------------------------------------------

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lock_reg    <= 1'b0;
            owner_reg   <= 1'b0;
            rr_priority <= 1'b0;
        end
        else begin

            // ------------------------------------------
            // Release
            // ------------------------------------------
            //
            // Only the current owner is allowed
            // to release the lock.
            // ------------------------------------------

            if (lock_reg) begin

                if (release_0 && (owner_reg == 1'b0)) begin
                    lock_reg <= 1'b0;
                end
                else if (release_1 && (owner_reg == 1'b1)) begin
                    lock_reg <= 1'b0;
                end

            end

            // ------------------------------------------
            // Acquire
            // ------------------------------------------
            //
            // Only acquire if currently free.
            // ------------------------------------------

            else begin

                if (grant_0) begin
                    lock_reg  <= 1'b1;
                    owner_reg <= 1'b0;

                    // Give Core 1 priority next time
                    // both request simultaneously.
                    rr_priority <= 1'b1;
                end

                else if (grant_1) begin
                    lock_reg  <= 1'b1;
                    owner_reg <= 1'b1;

                    // Give Core 0 priority next time.
                    rr_priority <= 1'b0;
                end
            end
        end
    end

    // --------------------------------------------------
    // Debug/status outputs
    // --------------------------------------------------

    assign locked = lock_reg;
    assign owner  = owner_reg;

endmodule