module dmem_bram #(
    parameter WORDS = 16384,
    parameter ADDR_WIDTH = $clog2(WORDS),
    parameter INIT_FILE = "",
	parameter RD_BITS = 32 //32 = one word per read, 64 = full cache line
)(
    input  logic        clk,
    input  logic        dmem_req_valid,
    input  logic        dmem_req_write,
    input  logic [31:0] dmem_req_addr,
    input  logic [31:0] dmem_req_wdata,
    input  logic [3:0]  dmem_req_wstrb,
    output logic        dmem_req_ready,
    output reg         dmem_resp_valid,
    output reg  [RD_BITS - 1:0] dmem_resp_rdata
);

    assign dmem_req_ready = 1'b1;
	
	generate 
	if(RD_BITS == 32) begin : g_word 
		//Original 32-bit memory unchanged
		
		logic [ADDR_WIDTH-1:0] addr;
    	assign addr = dmem_req_addr[ADDR_WIDTH+1:2];
		
		(* ram_style = "block" *) reg [31:0] mem [0:WORDS-1];
		
	    initial begin
	        if (INIT_FILE != "")
	            $readmemh(INIT_FILE, mem);
	    end
	
	    always_ff @(posedge clk) begin
	        dmem_resp_valid <= dmem_req_valid && !dmem_req_write;
	
	        if (dmem_req_valid && dmem_req_write) begin
	            if (dmem_req_wstrb[0]) mem[addr][7:0]   <= dmem_req_wdata[7:0];
	            if (dmem_req_wstrb[1]) mem[addr][15:8]  <= dmem_req_wdata[15:8];
	            if (dmem_req_wstrb[2]) mem[addr][23:16] <= dmem_req_wdata[23:16];
	            if (dmem_req_wstrb[3]) mem[addr][31:24] <= dmem_req_wdata[31:24];
	        end
	
	        if (dmem_req_valid && !dmem_req_write)
	            dmem_resp_rdata <= mem[addr]; 
		end
	end
	else begin : g_line	 
		//64-bit lines: same capacity, half as many rows
			localparam LINES = WORDS / 2;
			logic [ADDR_WIDTH - 2:0] line;
			assign line = dmem_req_addr[ADDR_WIDTH + 1:3]; 
				
			(* ram_style = "block" *) reg [63:0] mem [0:LINES - 1];
				
			//load the same 32-bit hex file, packed two words per line
			reg [31:0] init_words [0:WORDS - 1];
			initial begin
				if(INIT_FILE != "") begin
					$readmemh(INIT_FILE, init_words);
					for (int i = 0; i < LINES; i++)
						mem[i] = {init_words[2*i + 1], init_words[2*i]};
				end
			end
				
			// a 32-bit store becomes an 8-byte write with only one half enabled
			logic [7:0] be;
			logic [63:0] wd;
			assign be = dmem_req_addr[2] ? {dmem_req_wstrb, 4'b0000} : {4'b0000, dmem_req_wstrb};
			assign wd = {dmem_req_wdata, dmem_req_wdata};
				
			always @(posedge clk) begin
				dmem_resp_valid <= dmem_req_valid && !dmem_req_write;
					
				if(dmem_req_valid && dmem_req_write)
					for(int b = 0; b < 8; b++)
						if(be[b]) mem[line][8*b +: 8] <= wd[8*b +: 8];
								
				if(dmem_req_valid && !dmem_req_write)
					dmem_resp_rdata <= mem[line];
			end
		end
		endgenerate
endmodule