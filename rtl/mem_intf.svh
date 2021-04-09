// -------------------------------------------------------------------------
// File name		: mem_intf.svh 
// Title				: 
// Project      	: 
// Developers   	: gerners 
// Created      	: Fri Apr 09, 2021  12:25AM 
// Last modified  : 
// Description  	: 
// Notes        	: 
// Version			: 0.1
// ---------------------------------------------------------------------------
// Copyright 
// Confidential Proprietary 
// ---------------------------------------------------------------------------
`ifndef mem_intf
	`define mem_intf
	parameter WORD_WIDTH=8;
	parameter NUM_WORDS_IN_LINE=32;
	parameter ADDR_WIDTH=19;

	typedef struct packed {
			logic read_mem_req;
			logic [ADDR_WIDTH-1:0] read_mem_start_addr;
			logic [ADDR_WIDTH-1:0] read_mem_size_bytes;
			logic write_mem_req;
			logic [ADDR_WIDTH-1:0] write_mem_start_addr;
			logic [ADDR_WIDTH-1:0] write_mem_size_bytes;
			logic [NUM_WORDS_IN_LINE-1:0][WORD_WIDTH-1:0] write_mem_data;
		} req_ctrl_in_s;

	typedef struct packed {
		logic read_mem_valid;
		logic [NUM_WORDS_IN_LINE-1:0][WORD_WIDTH-1:0] read_mem_data;
		logic write_mem_ack;
		} req_ctrl_out_s;

`endif
