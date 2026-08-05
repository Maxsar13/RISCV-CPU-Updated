// five-stage RV32I top
// release-safe debug
module cpu_top #(
    parameter RESET_VECTOR = 32'h0000_0000
)(
    input  logic        clk,
    input  logic        rst,

    output logic        imem_req_valid,
    output logic  [31:0] imem_req_addr,
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
    input  logic [31:0] dmem_resp_rdata,

	

    output logic [31:0] pc_debug,
    output logic [31:0] instr_debug,
    output logic         halted,
    output logic         trap,
    output logic  [31:0] trap_pc,
    output logic  [31:0] retired_debug
);
    // stall/flush control
    logic        fetch_enable;
    logic        if_id_enable;
    logic        if_id_flush;
    logic        id_ex_enable;
    logic        id_ex_flush;
    logic        ex_mem_enable;
    logic        mem_wb_enable;

    // IF logics
    logic        fetch_valid;
    logic [31:0] fetch_pc;
    logic [31:0] fetch_instr;

    // IF/ID wires
    logic        if_id_valid_q;
    logic [31:0] if_id_pc_q;
    logic [31:0] if_id_instr_q;

    // ID wires
    logic [4:0]  id_rs1, id_rs2, id_rd;
    logic [2:0]  id_funct3;
    logic [31:0] id_imm;
    logic [5:0]  id_alu_op;
    logic        id_alu_src_pc, id_alu_src_imm;
    logic        id_reg_write, id_mem_read, id_mem_write;
    logic        id_branch, id_jump, id_jalr;
    logic [1:0]  id_result_sel;
    logic        id_uses_rs1, id_uses_rs2;
    logic        id_illegal, id_halt;
    logic [31:0] rf_rs1_data, rf_rs2_data;
    // ID/EX logics
    logic        id_ex_valid_q;
    logic [31:0] id_ex_pc_q;
    logic [31:0] id_ex_rs1_data_q;
    logic [31:0] id_ex_rs2_data_q;
    logic [31:0] id_ex_imm_q;
    logic [4:0]  id_ex_rs1_q;
    logic [4:0]  id_ex_rs2_q;
    logic [4:0]  id_ex_rd_q;
    logic [2:0]  id_ex_funct3_q;
    logic [5:0]  id_ex_alu_op_q;
    logic        id_ex_alu_src_pc_q;
    logic        id_ex_alu_src_imm_q;
    logic        id_ex_reg_write_q;
    logic        id_ex_mem_read_q;
    logic        id_ex_mem_write_q;
    logic        id_ex_branch_q;
    logic        id_ex_jump_q;
    logic        id_ex_jalr_q;
    logic [1:0]  id_ex_result_sel_q;
    logic        id_ex_illegal_q;
    logic        id_ex_halt_q;

    // forward selects
    logic [1:0]  forward_a_sel;
    logic [1:0]  forward_b_sel;
    logic [1:0]  forward_store_sel;

    // EX logics
    logic [31:0] ex_a;
    logic [31:0] ex_b;
    logic [31:0] ex_alu_result;
    logic [31:0] ex_store_data;
    logic        branch_taken;
    logic [31:0] branch_target;
    logic        redirect;
    logic        ex_trap;

    // EX/MEM logics
    logic        ex_mem_valid_q;
    logic [31:0] ex_mem_pc_q;
    logic [31:0] ex_mem_alu_result_q;
    logic [31:0] ex_mem_store_data_q;
    logic [4:0]  ex_mem_rd_q;
    logic [2:0]  ex_mem_funct3_q;
    logic        ex_mem_reg_write_q;
    logic        ex_mem_mem_read_q;
    logic        ex_mem_mem_write_q;
    logic [1:0]  ex_mem_result_sel_q;
    logic        ex_mem_trap_q;
    logic        ex_mem_halt_q;	
	
	
	//Counters
	logic [31:0] cycle_count;
	logic [31:0] instr_count;
	logic [31:0] stall_count;

    // EX/MEM bypass value
    logic [31:0] ex_mem_forward_value =
        (ex_mem_result_sel_q == 2'd2) ? (ex_mem_pc_q + 32'd4) : ex_mem_alu_result_q;

    logic [31:0] mem_data;
    logic        memory_stall;

    // MEM/WB logics
    logic        mem_wb_valid_q;
    logic [31:0] mem_wb_pc_q;
    logic [31:0] mem_wb_alu_result_q;
    logic [31:0] mem_wb_mem_data_q;
    logic [4:0]  mem_wb_rd_q;
    logic        mem_wb_reg_write_q;
    logic [1:0]  mem_wb_result_sel_q;
    logic        mem_wb_trap_q;
    logic        mem_wb_halt_q;

    // WB logics
    logic [31:0] wb_data;
    logic [4:0]  wb_rd;
    logic        wb_we;

    logic load_use_stall;

    // pipe control
    rv32_pipeline_control pipeline_control_inst (
        .halted(halted),
        .memory_stall(memory_stall),
        .load_use_stall(load_use_stall),
        .redirect(redirect),
        .ex_trap(ex_trap),
        .fetch_enable(fetch_enable),
        .if_id_enable(if_id_enable),
        .if_id_flush(if_id_flush),
        .id_ex_enable(id_ex_enable),
        .id_ex_flush(id_ex_flush),
        .ex_mem_enable(ex_mem_enable),
        .mem_wb_enable(mem_wb_enable)
    );

    // IF
    if_stage #(
        .RESET_VECTOR(RESET_VECTOR)
    ) if_stage_inst (
        .clk(clk),
        .rst(rst),
        .enable(fetch_enable),
        .redirect(redirect),
        .redirect_target(branch_target),
        .imem_req_ready(imem_req_ready),
        .imem_resp_valid(imem_resp_valid),
        .imem_resp_data(imem_resp_data),
        .imem_req_valid(imem_req_valid),
        .imem_req_addr(imem_req_addr),
        .fetch_valid(fetch_valid),
        .fetch_pc(fetch_pc),
        .fetch_instr(fetch_instr),
        .pc_debug(pc_debug)
    );

    // IF/ID
    if_id_reg if_id_reg_inst (
        .clk(clk),
        .rst(rst),
        .enable(if_id_enable),
        .flush(if_id_flush),
        .valid_in(fetch_valid),
        .pc_in(fetch_pc),
        .instr_in(fetch_instr),
        .valid_out(if_id_valid_q),
        .pc_out(if_id_pc_q),
        .instr_out(if_id_instr_q)
    );

    // ID
    id_stage id_stage_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(if_id_valid_q),
        .instr_in(if_id_instr_q),
        .wb_we(wb_we),
        .wb_rd(wb_rd),
        .wb_data(wb_data),
        .rs1_out(id_rs1),
        .rs2_out(id_rs2),
        .rd_out(id_rd),
        .funct3_out(id_funct3),
        .imm_out(id_imm),
        .alu_op_out(id_alu_op),
        .alu_src_pc_out(id_alu_src_pc),
        .alu_src_imm_out(id_alu_src_imm),
        .reg_write_out(id_reg_write),
        .mem_read_out(id_mem_read),
        .mem_write_out(id_mem_write),
        .branch_out(id_branch),
        .jump_out(id_jump),
        .jalr_out(id_jalr),
        .result_sel_out(id_result_sel),
        .uses_rs1_out(id_uses_rs1),
        .uses_rs2_out(id_uses_rs2),
        .illegal_out(id_illegal),
        .halt_out(id_halt),
        .rs1_data_out(rf_rs1_data),
        .rs2_data_out(rf_rs2_data)
    );

    // decode debug
    assign instr_debug = if_id_instr_q;

    // load-use bubble
    hazard_unit hazard_unit_inst (
        .if_id_valid(if_id_valid_q),
        .id_ex_valid(id_ex_valid_q),
        .id_ex_mem_read(id_ex_mem_read_q),
        .id_ex_rd(id_ex_rd_q),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .if_id_uses_rs1(id_uses_rs1),
        .if_id_uses_rs2(id_uses_rs2),
        .load_use_stall(load_use_stall)
    );

    // ID/EX
    id_ex_reg id_ex_reg_inst (
        .clk(clk),
        .rst(rst),
        .enable(id_ex_enable),
        .flush(id_ex_flush),
        .valid_in(if_id_valid_q),
        .pc_in(if_id_pc_q),
        .rs1_data_in(rf_rs1_data),
        .rs2_data_in(rf_rs2_data),
        .imm_in(id_imm),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),
        .funct3_in(id_funct3),
        .alu_op_in(id_alu_op),
        .alu_src_pc_in(id_alu_src_pc),
        .alu_src_imm_in(id_alu_src_imm),
        .reg_write_in(id_reg_write),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .branch_in(id_branch),
        .jump_in(id_jump),
        .jalr_in(id_jalr),
        .result_sel_in(id_result_sel),
        .illegal_in(id_illegal),
        .halt_in(id_halt),
        .valid_out(id_ex_valid_q),
        .pc_out(id_ex_pc_q),
        .rs1_data_out(id_ex_rs1_data_q),
        .rs2_data_out(id_ex_rs2_data_q),
        .imm_out(id_ex_imm_q),
        .rs1_out(id_ex_rs1_q),
        .rs2_out(id_ex_rs2_q),
        .rd_out(id_ex_rd_q),
        .funct3_out(id_ex_funct3_q),
        .alu_op_out(id_ex_alu_op_q),
        .alu_src_pc_out(id_ex_alu_src_pc_q),
        .alu_src_imm_out(id_ex_alu_src_imm_q),
        .reg_write_out(id_ex_reg_write_q),
        .mem_read_out(id_ex_mem_read_q),
        .mem_write_out(id_ex_mem_write_q),
        .branch_out(id_ex_branch_q),
        .jump_out(id_ex_jump_q),
        .jalr_out(id_ex_jalr_q),
        .result_sel_out(id_ex_result_sel_q),
        .illegal_out(id_ex_illegal_q),
        .halt_out(id_ex_halt_q)
    );

    // bypass control
    forwarding_unit forwarding_unit_inst (
        .id_ex_valid(id_ex_valid_q),
        .id_ex_rs1(id_ex_rs1_q),
        .id_ex_rs2(id_ex_rs2_q),
        .ex_mem_valid(ex_mem_valid_q),
        .ex_mem_rd(ex_mem_rd_q),
        .ex_mem_reg_write(ex_mem_reg_write_q),
        .ex_mem_is_load(ex_mem_mem_read_q),
        .mem_wb_valid(mem_wb_valid_q),
        .mem_wb_rd(mem_wb_rd_q),
        .mem_wb_reg_write(mem_wb_reg_write_q),
        .forward_a(forward_a_sel),
        .forward_b(forward_b_sel),
        .forward_store(forward_store_sel)
    );

    // EX
    ex_stage ex_stage_inst (
        .valid_in(id_ex_valid_q),
        .pc_in(id_ex_pc_q),
        .rs1_data_in(id_ex_rs1_data_q),
        .rs2_data_in(id_ex_rs2_data_q),
        .imm_in(id_ex_imm_q),
        .rs1_in(id_ex_rs1_q),
        .rs2_in(id_ex_rs2_q),
        .funct3_in(id_ex_funct3_q),
        .alu_op_in(id_ex_alu_op_q),
        .alu_src_pc_in(id_ex_alu_src_pc_q),
        .alu_src_imm_in(id_ex_alu_src_imm_q),
        .mem_read_in(id_ex_mem_read_q),
        .mem_write_in(id_ex_mem_write_q),
        .branch_in(id_ex_branch_q),
        .jump_in(id_ex_jump_q),
        .jalr_in(id_ex_jalr_q),
        .illegal_in(id_ex_illegal_q),
        .halt_in(id_ex_halt_q),
        .forward_a_sel(forward_a_sel),
        .forward_b_sel(forward_b_sel),
        .forward_store_sel(forward_store_sel),
        .ex_mem_forward_value(ex_mem_forward_value),
        .wb_forward_value(wb_data),
        .ex_a_out(ex_a),
        .ex_b_out(ex_b),
        .alu_result_out(ex_alu_result),
        .store_data_out(ex_store_data),
        .branch_taken_out(branch_taken),
        .branch_target_out(branch_target),
        .redirect_out(redirect),
        .trap_out(ex_trap)
    );

    // EX/MEM
    ex_mem_reg ex_mem_reg_inst (
        .clk(clk),
        .rst(rst),
        .enable(ex_mem_enable),
        .flush(1'b0),
        .valid_in(id_ex_valid_q),
        .pc_in(id_ex_pc_q),
        .alu_result_in(ex_alu_result),
        .store_data_in(ex_store_data),
        .rd_in(id_ex_rd_q),
        .funct3_in(id_ex_funct3_q),
        .reg_write_in(id_ex_reg_write_q),
        .mem_read_in(id_ex_mem_read_q),
        .mem_write_in(id_ex_mem_write_q),
        .result_sel_in(id_ex_result_sel_q),
        .trap_in(ex_trap),
        .halt_in(id_ex_valid_q && id_ex_halt_q),
        .valid_out(ex_mem_valid_q),
        .pc_out(ex_mem_pc_q),
        .alu_result_out(ex_mem_alu_result_q),
        .store_data_out(ex_mem_store_data_q),
        .rd_out(ex_mem_rd_q),
        .funct3_out(ex_mem_funct3_q),
        .reg_write_out(ex_mem_reg_write_q),
        .mem_read_out(ex_mem_mem_read_q),
        .mem_write_out(ex_mem_mem_write_q),
        .result_sel_out(ex_mem_result_sel_q),
        .trap_out(ex_mem_trap_q),
        .halt_out(ex_mem_halt_q)
    );

    // MEM
    mem_stage mem_stage_inst (
        .valid_in(ex_mem_valid_q),
        .alu_result_in(ex_mem_alu_result_q),
        .store_data_in(ex_mem_store_data_q),
        .funct3_in(ex_mem_funct3_q),
        .mem_read_in(ex_mem_mem_read_q),
        .mem_write_in(ex_mem_mem_write_q),
        .trap_in(ex_mem_trap_q),
        .dmem_req_ready(dmem_req_ready),
        .dmem_resp_valid(dmem_resp_valid),
        .dmem_resp_rdata(dmem_resp_rdata),
		.cycle_count(cycle_count),
		.instr_count(instr_count),
		.stall_count(stall_count),
        .dmem_req_valid(dmem_req_valid),
        .dmem_req_write(dmem_req_write),
        .dmem_req_addr(dmem_req_addr),
        .dmem_req_wdata(dmem_req_wdata),
        .dmem_req_wstrb(dmem_req_wstrb),
        .mem_data_out(mem_data),
        .memory_stall(memory_stall)
    );

    // MEM/WB
    mem_wb_reg mem_wb_reg_inst (
        .clk(clk),
        .rst(rst),
        .enable(mem_wb_enable),
        .flush(1'b0),
        .valid_in(ex_mem_valid_q),
        .pc_in(ex_mem_pc_q),
        .alu_result_in(ex_mem_alu_result_q),
        .mem_data_in(mem_data),
        .rd_in(ex_mem_rd_q),
        .reg_write_in(ex_mem_reg_write_q),
        .result_sel_in(ex_mem_result_sel_q),
        .trap_in(ex_mem_trap_q),
        .halt_in(ex_mem_halt_q),
        .valid_out(mem_wb_valid_q),
        .pc_out(mem_wb_pc_q),
        .alu_result_out(mem_wb_alu_result_q),
        .mem_data_out(mem_wb_mem_data_q),
        .rd_out(mem_wb_rd_q),
        .reg_write_out(mem_wb_reg_write_q),
        .result_sel_out(mem_wb_result_sel_q),
        .trap_out(mem_wb_trap_q),
        .halt_out(mem_wb_halt_q)
    );

    // WB
    wb_stage wb_stage_inst (
        .valid_in(mem_wb_valid_q),
        .pc_in(mem_wb_pc_q),
        .alu_result_in(mem_wb_alu_result_q),
        .mem_data_in(mem_wb_mem_data_q),
        .rd_in(mem_wb_rd_q),
        .reg_write_in(mem_wb_reg_write_q),
        .result_sel_in(mem_wb_result_sel_q),
        .trap_in(mem_wb_trap_q),
        .halt_in(mem_wb_halt_q),
        .wb_data_out(wb_data),
        .wb_rd_out(wb_rd),
        .wb_we_out(wb_we)
    );

    // halt/trap state
    always @(posedge clk or posedge rst) begin
        if (rst) 
			begin
            // reset status
            halted <= 1'b0;
            trap <= 1'b0;
            trap_pc <= 32'd0;
            retired_debug <= 32'd0;
			//Resetting counters
			stall_count <= 32'd0;  
			cycle_count <= 32'd0;
			instr_count <= 32'd0;
        	end 
		else
			begin
				cycle_count <= cycle_count + 32'd1;	
				
				if(memory_stall)
					begin
						stall_count <= stall_count + 32'd1;	 //If memory stalled, increment
					end
				else
					begin
            		// commit count
            			if (mem_wb_valid_q && !mem_wb_trap_q && !mem_wb_halt_q)
							begin
                				retired_debug <= retired_debug + 32'd1;
								instr_count <= instr_count + 32'd1; //INcrementing instruction counter 
							end
            		// stop on halt
            			if (mem_wb_valid_q && mem_wb_halt_q)
                			halted <= 1'b1;
            		// stop on trap
            			if (mem_wb_valid_q && mem_wb_trap_q) 
							begin
                				halted <= 1'b1;
                				trap <= 1'b1;
                				trap_pc <= mem_wb_pc_q;
            				end
					end
			end
    end
endmodule