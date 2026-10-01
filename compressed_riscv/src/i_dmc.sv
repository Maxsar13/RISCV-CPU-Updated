module i_dmc(
	input logic clk,
	input logic rst,
	
	//Icache to DMC
	input logic	miss_req_valid,
	input logic [31:0] miss_req_addr, 
	
	//Arbiter to DMC
	input logic mem_req_ready,
	input logic mem_resp_valid,
	input logic [63:0] mem_resp_data,
	
	//DMC to Icache
	output logic miss_req_ready,
	output logic miss_resp_valid,
	output logic [63:0] miss_resp_data,
	
	//Arbiter to DMC
	output logic mem_req_valid,
	output logic [31:0] mem_req_addr
	);	
	
	typedef enum logic[1:0]{
	IDLE_STATE,
	READ_REQ,
	READ_DATA
	}state_t;
	
	state_t state, next_state;
	
	logic [31:0] req_addr_q;
	
	
	
	