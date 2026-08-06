module tb_cpu_top;
	
	logic clk;
	logic rst;
	
	//imem wires
	logic imem_req_valid;
	logic [31:0] imem_req_addr;
	logic imem_req_ready;
	logic imem_resp_valid;
	logic [31:0] imem_resp_data;
	
	
	//dmem wires
	logic dmem_req_valid;
	logic dmem_req_write;
	logic [31:0] dmem_req_addr;
	logic [31:0] dmem_req_wdata;
	logic [3:0] dmem_req_wstrb;
	logic dmem_req_ready;
	logic dmem_resp_valid;
	logic [31:0] dmem_resp_rdata;
	
	//debug outputs
	
	logic [31:0] pc_debug;
	logic [31:0] instr_debug;
	logic halted;
	logic trap;
	logic [31:0] trap_pc;
	logic [31:0] retired_debug;
	
	
	cpu_top #(
	.RESET_VECTOR(32'h0000_0000)
	)
	dut (
		.clk(clk),
		.rst(rst),
		.imem_req_valid(imem_req_valid),
		.imem_req_addr(imem_req_addr),
		.imem_req_ready(imem_req_ready),
		.imem_resp_valid(imem_resp_valid),
		.imem_resp_data(imem_resp_data),
		.dmem_req_valid(dmem_req_valid),
		.dmem_req_write(dmem_req_write),
		.dmem_req_addr(dmem_req_addr),
		.dmem_req_wdata(dmem_req_wdata),
		.dmem_req_wstrb(dmem_req_wstrb),
		.dmem_req_ready(dmem_req_ready),
		.dmem_resp_valid(dmem_resp_valid),
		.dmem_resp_rdata(dmem_resp_rdata),
		.pc_debug(pc_debug),
		.instr_debug(instr_debug),
		.halted(halted),
		.trap(trap),
		.trap_pc(trap_pc),
		.retired_debug(retired_debug)
		);
		
	tb_memory#(
		.MEM_WORDS(1024),
		.HEXFILE("program.hex")
	)
	memory(
		.clk(clk),
		.imem_req_valid(imem_req_valid),
		.imem_req_addr(imem_req_addr),
		.imem_req_ready(imem_req_ready),
		.imem_resp_valid(imem_resp_valid),
        .imem_resp_data(imem_resp_data),
        .dmem_req_valid(dmem_req_valid),
        .dmem_req_write(dmem_req_write),
        .dmem_req_addr(dmem_req_addr),
        .dmem_req_wdata(dmem_req_wdata),
        .dmem_req_wstrb(dmem_req_wstrb),
        .dmem_req_ready(dmem_req_ready),
        .dmem_resp_valid(dmem_resp_valid),
        .dmem_resp_rdata(dmem_resp_rdata)
    );
	
	initial clk = 0;
		always #5 clk = ~clk;
			
	initial 
		begin
			rst = 1;
			#20;
			rst = 0;
			
			repeat(60)
			begin
				@(posedge clk);
				$display("t = %0t pc = %08h instr = %08h | cyc = %0d instr = %0d stall = %0d retired = %0d x6 = %0d x7 = %0d x8 = %0d", $time, pc_debug, instr_debug, dut.cycle_count, dut.instr_count, dut.stall_count, retired_debug, dut.id_stage_inst.regfile_inst.regs[6], dut.id_stage_inst.regfile_inst.regs[7], dut.id_stage_inst.regfile_inst.regs[8]);
				if(halted) 
					begin
						$display(">>> HALTED at t = %0t", $time);
						$display(">>> FINAL: cycles = %0d instrs = %0d stalls = %0d", dut.cycle_count, dut.instr_count, dut.stall_count);
						$finish;
					end
			end
			$display(">>> timeout");
			$finish;
		end
endmodule
					