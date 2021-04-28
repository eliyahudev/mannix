//======================================================================================================
//Module: sram
//Description: single port sram memory of 32kB 
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 12-Jan-2021
//======================================================================================================
module mem_sram
	(
	input clk, // Clock
	input rst_n,
 	input cs, // chip select
 	input [3:0] id,
	input [255:0] data_in,
	input read,
	input [18:0] addr, 
	input write,
	input mask_enable,
	input [255:0] mask, //where the bit that high, there the new data will written 
	output logic [255:0] data_out,
	output logic [262144-1:0] debug_mem //for debug - need to be deleted
	);
	
	logic [1023:0][255:0] mem;
	
	always @(posedge clk)
		if (cs) begin
			if (write && !read && !mask_enable)
				mem[addr[14:5]]<=data_in;//the [4:0] bits are the 32B inside the line
			if (write && !read && mask_enable)
				mem[addr[14:5]]<= (data_in & mask) | (mem[addr[14:5]] & (~mask));//the [4:0] bits are the 32B inside the line
			if (read && !write)
				data_out<=mem[addr[14:5]];
		end

	//assertions
	no_read_and_write: assert property (@(posedge clk)disable iff (!rst_n) cs |-> !(read && write));
	match_id: assert property (@(posedge clk)disable iff (!rst_n) cs |-> id == addr[18:15] );
	
	//debug
	assign debug_mem=mem;
				
endmodule
