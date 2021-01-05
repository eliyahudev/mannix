interface mem_intf_write 
	#( parameter WORD_WIDTH=8,
	   parameter NUM_WORDS_IN_LINE=32,
	   parameter ADDR_WIDTH=19);

	   logic mem_req;
	   logic mem_ack;
	   logic last;
	   logic [ADDR_WIDTH-1:0] mem_start_addr;
	   logic [ADDR_WIDTH-1:0] mem_size_bytes;
	   logic [NUM_WORDS_IN_LINE-1:0][WORD_WIDTH-1:0] mem_data;
	   logic [$clog2(NUM_WORDS_IN_LINE)-1:0] mem_last_valid;
		modport client_write (input mem_ack,
	   					 output mem_req, mem_start_addr, mem_size_bytes, last, mem_data, mem_last_valid);


		modport memory_write (input mem_req, mem_start_addr, mem_size_bytes, last, mem_data, mem_last_valid,
	   					 output mem_ack);
endinterface
	   					



