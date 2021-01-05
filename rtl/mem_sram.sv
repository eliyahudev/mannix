module mem_sram
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [255:0] data_in,
	input read,
	input [19:0] addr,
	input write,
	output [255:0] data_out
	);
endmodule
