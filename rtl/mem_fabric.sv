//======================================================================================================
//Module: mem_fabric
//Description:
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 27-Nov-2020
//======================================================================================================
module mem_fabric
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [15:0][255:0] data_in,
	input [15:0][4:0] client_to_send,
	output logic [15:0][255:0] data_out
	);
endmodule
