module dmc(
	input logic clk,
	input logic rst,
	
	//Dcache to DMC
	input logic miss_req_valid,
	input logic miss_req_write,
	input logic [31:0] miss_req_addr,
	input logic [31:0] miss_req_wdata,
	input logic [3:0] miss_req_wstrb,
	
	//Arbiter to DMC
	input logic mem_req_ready,
	input logic mem_resp_valid,
	input logic [63:0] mem_resp_data,
	
	//DMC to Dcache 
	output logic miss_req_ready,	//Ready to accept a new request
	output logic miss_resp_ready,		//64 bit line is available
	output logic [63:0] miss_resp_data,
	
	//DMC to Arbiter
	output logic mem_req_valid,
	output logic mem_req_write,
	output logic [31:0] mem_req_addr,
	output logic [31:0] mem_req_wdata,
	output logic [3:0] mem_req_wstrb
	);
	
	//initiating the FSM
	typedef enum logic[1:0] {
	IDLE_STATE,
	READ_WAIT,
	WRITE_WAIT
	} state_t;
	
	state_t state, next_state;	   
	
	
	//latched request fields
	logic [31:0] req_addr_q;
	logic [31:0] req_wdata_q;
	logic [3:0] req_wstrb_q; //Which 32 bit word to actually write. Whole word, upper or lower half, or by byte.
	
	//changing the state register
	always_ff @(posedge clk or posedge rst) begin
		if(rst)
			begin
				state <= IDLE_STATE;
			end
		else 
			begin
				state <= next_state;
			end
		end
		
	
	//latching request on accept
	always_ff @(posedge clk or posedge rst) begin
		if(rst)
			begin
				req_addr_q <= 32'd0;
				req_wdata_q <= 32'd0;
				req_wstrb_q <= 4'd0;
			end
		else if(state == IDLE_STATE && miss_req_valid && miss_req_ready)  //This is like a place holder for the incoming write values. 
			begin														  //Since writes dont care about reading something back, we take it once from the dcache and read from here,
				req_addr_q <= miss_req_addr;							  //And no matter what dcache does, unless it resets we have the saved variables
				req_wdata_q	<= miss_req_wdata;
				req_wstrb_q	<= miss_req_wstrb;
			end
		end
		
	//next-state logic
	always_comb begin
		next_state = state;
		case (state)
			IDLE_STATE: begin 
				if(miss_req_valid)
					begin
						next_state = miss_req_write ? WRITE_WAIT : READ_WAIT;
					end
			end
			READ_WAIT: begin 
				if (mem_resp_valid)
					begin
						next_state = IDLE_STATE;
					end
			end
			WRITE_WAIT: begin
				if(mem_req_ready && mem_req_valid) //Since for write we just dump, theres gotta be something to tell us if its reveived.											
					begin						   //If arbiter idles high, then mem_req_ready is asserted before mem_req_valid, meaning both should be set high
						next_state = IDLE_STATE;
					end
			end
			default: next_state = IDLE_STATE;
		endcase
	end
	
	//output logic
	always_comb begin
		//Defaults for every output	
		miss_req_ready = 1'b0;
		miss_resp_ready = 1'b0;
		miss_resp_data = 64'd0;
		mem_req_valid = 1'b0;
		mem_req_write = 1'b0;
		mem_req_addr = 32'd0;
		mem_req_wdata = 32'd0;
		mem_req_wstrb = 4'd0;
		
		
		
		case (state)
			IDLE_STATE:
			begin 
				miss_req_ready = 1'b1;
			end
			READ_WAIT:
			begin	
				mem_req_valid = 1'b1;
				mem_req_write = 1'b0;
				miss_resp_ready = mem_resp_valid;
				miss_resp_data = mem_resp_data;
				mem_req_addr = {req_addr_q[31:3], 3'b000}; //Line aligned as each line covers every 16 bits
				
			end
			WRITE_WAIT:
			begin 
				mem_req_valid = 1'b1;
				mem_req_write = 1'b1;
				mem_req_wdata = req_wdata_q;
				mem_req_wstrb = req_wstrb_q;
				mem_req_addr = req_addr_q;	//We only write 32 bits at a time which should be aligned already with the data
			end
			default: ;
		endcase
	end
endmodule			   