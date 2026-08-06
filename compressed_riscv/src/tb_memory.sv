module tb_memory#(
	parameter MEM_WORDS = 1024,
	parameter string HEXFILE = "program.hex"
	)(
	input logic clk,
	input logic imem_req_valid,
	input logic [31:0] imem_req_addr,
	
	output logic imem_req_ready,
	output logic imem_resp_valid,
	output logic [31:0] imem_resp_data,
	
	input logic dmem_req_valid,
	input logic dmem_req_write,
	input logic [31:0] dmem_req_addr,
	input logic [31:0] dmem_req_wdata,
	input logic [3:0] dmem_req_wstrb,
	output logic dmem_req_ready,
	output logic dmem_resp_valid,
	output logic [31:0] dmem_resp_rdata
	);
	
	logic [31:0] mem[0:MEM_WORDS-1];
	
	initial
	begin
		$readmemh(HEXFILE, mem);
	end
	
	localparam int IDX_BITS = $clog2(MEM_WORDS);
	
	wire [IDX_BITS - 1:0] iidx = imem_req_addr[IDX_BITS + 1:2];
	wire [IDX_BITS - 1:0] didx = dmem_req_addr[IDX_BITS + 1:2];
	
	assign imem_req_ready = 1'b1;
	assign imem_resp_valid = imem_req_valid;
	assign imem_resp_data = mem[iidx];
	
	assign dmem_req_ready = 1'b1;
	assign dmem_resp_valid = dmem_req_valid;
	assign dmem_resp_rdata = mem[didx];
	
	
	always @(posedge clk)
		begin
			if(dmem_req_valid && dmem_req_write)
				begin
					if(dmem_req_wstrb[0]) 
						mem[didx][7:0] <= dmem_req_wdata[7:0];
					if(dmem_req_wstrb[1])
						mem[didx][15:8] <= dmem_req_wdata[15:8];
					if(dmem_req_wstrb[2]) 
						mem[didx][23:16] <= dmem_req_wdata[23:16];
					if(dmem_req_wstrb[3])
						mem[didx][31:24] <= dmem_req_wdata[31:24];
				end
			end
	endmodule
				
						
	