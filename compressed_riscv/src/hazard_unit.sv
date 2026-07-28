module hazard_unit(	
	input logic if_id_valid,
	input logic id_ex_valid,
	input logic id_ex_mem_read,
	input logic [4:0] id_ex_rd,
	input logic [4:0] if_id_rs1,
	input logic [4:0] if_id_rs2,
	input logic if_id_uses_rs1,
	input logic if_id_uses_rs2,
	
	output logic load_use_stall
	);
	
	assign load_use_stall = if_id_valid && id_ex_valid && id_ex_mem_read && (id_ex_rd != 5'd0) && ((if_id_uses_rs1 && id_ex_rd == if_id_rs1) || (if_id_uses_rs2 && id_ex_rd == if_id_rs2));	
endmodule
	