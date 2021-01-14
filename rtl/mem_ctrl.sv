module mem_ctrl
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [31:0] read_addr_ddr,
	input [31:0] write_addr_ddr,
	input [4:0] client_priority,
	output logic [18:0] base_addr_to_demux,
	output logic last_demux,
	output logic [3:0] num_of_last_valid_demux,
	output logic [15:0][4:0] client_to_send_fabric,
	output logic read,
	output logic [31:0] addr_read,
	output logic write,
	output logic [31:0] addr_write,
	output logic [15:0][4:0] num_bytes_valid,
	output logic [15:0][18:0] addr_sram,
	output logic [15:0]cs
	);
endmodule
