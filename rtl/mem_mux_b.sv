//======================================================================================================
//Module: pool
//Description:
//Design Unit Owner : Nitzan Lalazar
//Original Author   : Netanel Lalazar
//Original Date     : 27-Nov-2020
//======================================================================================================
module mem_mux_b
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [15:0][255:0] data_in,
	input [15:0][4:0] client_to_send,
	output [31:0][255:0] data_out
	);
endmodule
