module memory_controller(
	input logic clk,
	input logic rst,
	
	//IMEM arbiter to MC
	input logic i_req_valid,
	input logic [31:0] i_req_addr,
	output logic i_req_ready,
	output logic i_resp_valid,
	output logic [63:0] i_resp_data,
	
	//DMEM arbiter to MC 
	input logic d_req_valid,
	input logic d_req_write,
	input logic [31:0] d_req_addr,	 
	input logic [31:0] d_req_wdata,
	input logic [3:0] d_req_wstrb,
	output logic d_req_ready,
	output logic d_resp_valid, 
	output logic [63:0] d_resp_data,
	
	
	//Bridge to MC
	input logic mem_req_ready,
	input logic mem_resp_valid,
	input logic [63:0] mem_resp_data,
	
	
	//DMC to Bridge
	output logic mem_req_valid,
	output logic mem_req_write,
	output logic [31:0] mem_req_addr,
	output logic [31:0] mem_req_wdata,
	output logic [3:0] mem_req_wstrb
	);
	
	//initiating the FSM
	typedef enum logic[1:0] {
	IDLE_STATE,
	READ_REQ, //Request is sent out, it is now just waiting to be accepted
	READ_DATA,		//Accepted and it is now just waiting for data.
	WRITE_WAIT
	} state_t;
	
	state_t state, next_state;	   
	
	
	//latched request fields
	logic [31:0] req_addr_q;
	logic [31:0] req_wdata_q;
	logic [3:0] req_wstrb_q; //Which 32 bit word to actually write. Whole word, upper or lower half, or by byte. 
	
	logic rr; //Making a round robin for imem and dmem. 0 = imem, 1 = dmem
	logic sel_q;	//Whoever owns the request
	
	
	//Assigning priorities by looking at req_valid in inputs, as well as round robin variable
	logic grant_i, grant_d;
	assign grant_i = i_req_valid && (!d_req_valid || !rr);
	assign grant_d = d_req_valid && (!i_req_valid || rr);
	
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
				sel_q <= 0;
				rr <= 0;
				req_addr_q <= 32'd0;
				req_wdata_q <= 32'd0;
				req_wstrb_q <= 4'd0; 
			end
		else if(state == IDLE_STATE && (grant_i || grant_d))  				  //This is like a place holder for the incoming write values. 
			begin
				sel_q <= grant_d;		   //Since dmem is 1, if its 0 then Imem has priority
				req_addr_q <= grant_d ? d_req_addr : i_req_addr;							  
				req_wdata_q	<= d_req_wdata;
				req_wstrb_q	<= d_req_wstrb;
				rr <= grant_i;			  //If grant_i, round robin goes to 0, else goes to 1
			end
		end
		
	//next-state logic
	always_comb begin
		next_state = state;
		case (state)
			IDLE_STATE: begin 
				if(grant_d && d_req_write)
					begin
						next_state = WRITE_WAIT;
					end
				else if(grant_i || grant_d)
					begin
						next_state = READ_REQ;
					end
			end
			READ_REQ: begin 
				if (mem_req_ready)
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
			WRITE_WAIT: begin
				if(mem_req_ready) 				   //Since for write we just dump, theres gotta be something to tell us if its reveived.											
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
		mem_req_valid = 1'b0;
		mem_req_write = 1'b0;
		mem_req_addr = 32'd0;
		mem_req_wdata = 32'd0;
		mem_req_wstrb = 4'd0; 
		i_req_ready = 1'b0;
		d_req_ready = 1'b0;
		i_resp_valid = 1'b0;
		d_resp_valid = 1'b0;
		i_resp_data = 64'd0;
		d_resp_data = 64'd0;
		
		//Mem_req_valid will now only set when a request isnt accepted
		
		case (state)
			IDLE_STATE:
			begin 
				i_req_ready = grant_i;
				d_req_ready = grant_d;
			end
			READ_REQ:
			begin	
				mem_req_valid = 1'b1;
				mem_req_write = 1'b0;
				mem_req_addr = {req_addr_q[31:3], 3'b000}; //64 bit line, clear last 3 bits
				
			end
			READ_DATA: 
			begin	
				i_resp_valid = mem_resp_valid && !sel_q;
				d_resp_valid = mem_resp_valid && sel_q;
				i_resp_data = mem_resp_data;			   //Data gets sent to both, but resp_valid decides what cache actually recieves it
				d_resp_data = mem_resp_data;
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