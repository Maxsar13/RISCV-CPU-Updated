module forwarding_unit(
	input logic id_ex_valid,
	input logic [4:0] id_ex_rs1,
	input logic [4:0] id_ex_rs2,
	input logic ex_mem_valid,
	input logic [4:0] ex_mem_rd,
	input logic ex_mem_reg_write,
	input logic ex_mem_is_load,
	input logic mem_wb_valid,
	input logic [4:0] mem_wb_rd,
	input logic mem_wb_reg_write,
	
	output logic [1:0] forward_a,
	output logic [1:0] forward_b,
	output logic [1:0] forward_store
	);
	
	always_comb
	begin
		forward_a = 2'b00;
		forward_b = 2'b00;
		forward_store = 2'b00;
		
		if(id_ex_valid && ex_mem_valid && ex_mem_reg_write && !ex_mem_is_load && ex_mem_rd != 5'd0 && ex_mem_rd == id_ex_rs1)
			begin
				forward_a = 2'b10;
			end
		else if(id_ex_valid && mem_wb_valid && mem_wb_reg_write && mem_wb_rd != 5'd0 && mem_wb_rd == id_ex_rs1)
			begin
				forward_a = 2'b01;
			end
		
		if(id_ex_valid && ex_mem_valid && ex_mem_reg_write && !ex_mem_is_load && ex_mem_rd != 5'd0 && ex_mem_rd == id_ex_rs2)
			begin
				forward_b = 2'b10;
			end
		else if(id_ex_valid && mem_wb_valid && mem_wb_reg_write && mem_wb_rd != 5'd0 && mem_wb_rd == id_ex_rs2)
			begin
				forward_b = 2'b01;
			end
		
		if(id_ex_valid && ex_mem_valid && ex_mem_reg_write && !ex_mem_is_load && ex_mem_rd != 5'd0 && ex_mem_rd == id_ex_rs2)
			begin
				forward_store = 2'b10;
			end
		else if(id_ex_valid && mem_wb_valid && mem_wb_reg_write && mem_wb_rd != 5'd0 && mem_wb_rd == id_ex_rs2)
			begin
				forward_store = 2'b01;
			end
		end
	endmodule
		
		