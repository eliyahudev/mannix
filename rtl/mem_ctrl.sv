module mem_ctrl
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [31:0] read_addr_ddr,
	input [31:0] write_addr_ddr,
	input [4:0] client_priority,
	output [18:0] base_addr_to_mux_a,
	output last_mux_a,
	output [4:0] num_of_last_valid_mux_a,
	output [15:0][4:0] client_to_send_mux_b,
	output [15:0] read,
	output [15:0][18:0] addr_read,
	output [15:0] write,
	output [15:0] [18:0] addr_write
	);
endmodule
