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
	logic [3:0] req_wstrb_q; 
	
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
		else if(state == IDLE_STATE && miss_req_valid && miss_req_ready)
			begin
				req_addr_q <= miss_req_addr;
				req_wdata_q	<= miss_req_wdata;
				req_wstrb_q	<= miss_req_wstrb;
			end
		end
		
	//next-state logic
	always_comb begin
		next_state = state;
		case (state)
			IDLE_STATE: begin
			end
			READ_WAIT: begin
			end
			WRITE_WAIT: begin
			end
			default: next_state = IDLE_STATE;
		endcase
	end
	
	//output logic
	always_comb begin
		//Defaults for every output
		case (state)
			IDLE_STATE:
			begin
			end
			READ_WAIT:
			begin
			end
			WRITE_WAIT:
			begin
			end
			default:	;
		endcase
	end
endmodule			   