module i_dmc(
	input logic clk,
	input logic rst,
	
	//Icache to DMC
	input logic	miss_req_valid,
	input logic [31:0] miss_req_addr, 
	
	
	//DMC to Arbiter
	output logic mem_req_valid,
	output logic [31:0] mem_req_addr,
	
	//Arbiter to DMC
	input logic mem_req_ready,
	input logic mem_resp_valid,
	input logic [63:0] mem_resp_data, 
	
	//DMC to Icache
	output logic miss_req_ready,
	output logic miss_resp_valid,
	output logic [63:0] miss_resp_data

	);	
	
	typedef enum logic[1:0]{
	IDLE_STATE,
	READ_REQ,
	READ_DATA
	}state_t;
	
	state_t state, next_state;
	
	logic [31:0] req_addr_q;
	
	//FSM Next state logic
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
	//Latches
	always_ff @(posedge clk or posedge rst) begin
		if(rst)
			begin
				req_addr_q <= 32'b0;
			end
		else if(IDLE_STATE && miss_req_valid)
			begin
				req_addr_q <= miss_req_addr;
			end
	end	   
	
    //Next state FSM logic
	always_comb begin
		next_state = state;
		case(state)
			IDLE_STATE: begin
				if(miss_req_valid)
					begin
						next_state = READ_REQ;
					end
			end
			READ_REQ: begin	
				if(mem_req_ready)
					begin
						next_state = READ_DATA;
					end
			end
			READ_DATA: begin 
				if(mem_resp_valid)
					begin
						next_state = IDLE_STATE;
					end
			end
			default: next_state = IDLE_STATE;
		endcase
	end	 
	
	//Output logic
	always_comb begin
		miss_req_ready = 1'b0;
		miss_resp_valid = 1'b0;
		miss_resp_data = 64'd0;
		mem_req_valid = 1'b0;
		mem_req_addr = 32'd0;
		
		case(state)
			IDLE_STATE: begin
				miss_req_ready = 1'b1;
				end
			READ_REQ: begin
				mem_req_valid = 1'b1;
				mem_req_addr = {req_addr_q[31:3], 3'b000}; //Line aligned as each line covers every 16 bits
			end
			READ_DATA: begin  
				miss_resp_valid = mem_resp_valid;
				miss_resp_data = mem_resp_data;			
			end
			default: ;
		endcase
	end
endmodule
		
		
	
	
	
	