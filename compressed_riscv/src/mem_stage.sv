`include "definitions.vh"

module mem_stage(
	input logic valid_in,
	input logic [31:0] alu_result_in,
	input logic [31:0] store_data_in,
	input logic [2:0] funct3_in,
	input logic mem_read_in,
	input logic mem_write_in,
	input logic trap_in,
	input logic dmem_req_ready,
	input logic dmem_resp_valid,
	input logic [31:0] dmem_resp_rdata,
	
	output logic dmem_req_valid,
	output logic dmem_req_write,
	output logic [31:0] dmem_req_addr,
	output logic [31:0] dmem_req_wdata,
	output logic [3:0] dmem_req_wstrb,
	output logic [31:0] mem_data_out,
	output logic memory_stall
	);
	
	//valid mem op
	
	logic dmem_active = valid_in && (mem_read_in || mem_write_in) && !trap_in;
	//Dmem request
	assign dmem_req_valid = dmem_active;
	assign dmem_req_write = mem_write_in;
	assign dmem_req_addr = alu_result_in;
	//store formatting
	assign dmem_req_wdata = store_wdata(alu_result_in, store_data_in, funct3_in);
	assign dmem_req_wstrb = store_wstrb(alu_result_in, funct3_in, mem_write_in);
	
	//Load formatting
	assign mem_data_out = load_data(alu_result_in, dmem_resp_rdata, funct3_in);
	
	//load wait
	assign memory_stall = dmem_active && !(dmem_req_ready && (mem_write_in || dmem_resp_valid));
	
	//store strobes
	function [3:0] store_wstrb;
		input [31:0] addr;
		input [2:0] funct3;
		input en;
		begin
			if(!en)
				store_wstrb = 4'b0000;
			else
				begin
					case(funct3)
						//SB
						3'b000: store_wstrb = 4'b0001 << addr[1:0];
						3'b001: store_wstrb = addr[1] ? 4'b1100 : 4'b0011;//SH
						3'b010: store_wstrb = 4'b1111; //SW
						default: store_wstrb = 4'b0000;
					endcase
				end
		end
	endfunction
	
	//Store lanes
	function [31:0] store_wdata;
		input [31:0] addr;
		input [31:0] data;
		input [2:0] funct3;
		begin
			case(funct3)
				//SB lane
				3'b000: store_wdata = {4{data[7:0]}} << (addr[1:0] * 8);
				//SH Lane
				3'b001: store_wdata = addr[1] ? {data[15:0], 16'd0} : {16'd0, data[15:0]};
				//sw Lane
				default: store_wdata = data;
			endcase
		end
	endfunction
	
	//Load Extended
	function[31:0] load_data;
		input [31:0] addr;
		input [31:0] data;
		input [2:0] funct3;
		begin
			case(funct3)
				//LB
				3'b000: begin
					case(addr[1:0])
						2'd0: load_data = {{24{data[7]}}, data[7:0]};
						2'd1: load_data = {{24{data[15]}}, data[15:8]};
						2'd2: load_data = {{24{data[23]}}, data[23:16]};
						default: load_data = {{24{data[31]}}, data[31:24]};
					endcase
				end
				//LH
				3'b001: load_data = addr[1] ? {{16{data[31]}}, data[31:16]} : {{16{data[15]}}, data[15:0]};
				//LW
				3'b010 : load_data = data;
				//LBU
				3'b100:begin
					case(addr[1:0])
						2'd0: load_data = {24'd0, data[7:0]};
						2'd1: load_data = {24'd0, data[15:8]};
						2'd2: load_data = {24'd0, data[23:16]};
						default: load_data = {24'd0, data[31:24]};
					endcase
				end
				//LHU
				3'b101: load_data = addr[1] ? {16'd0, data[31:16]} : {16'd0, data[15:0]};
				default: load_data = 32'd0;
			endcase
		end
endfunction
endmodule
						