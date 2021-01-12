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
 	input cs, // chip select
 	input [3:0] id,
	input [255:0] data_in,
	input read,
	input [18:0] addr, 
	input write,
	output logic [255:0] data_out
	);
	
	logic [1023:0][255:0] mem;
	
	always @(posedge clk)
		if (cs) begin
			if (write && !read)
				mem[addr[14:5]]<=data_in;
			if (read && !write)
				data_out<=mem[addr[14:5]];
		end

	//assertions
	no_read_and_write: assert property (@(posedge clk) !(read && write));
	match_id: assert property (@(posedge clk) cs |-> id == addr[18:15] );
				
endmodule
