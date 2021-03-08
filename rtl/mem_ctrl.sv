module mem_ctrl
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [31:0] read_addr_ddr,
	input [31:0] write_addr_ddr,
	input read_from_ddr,
	input write_to_ddr,
	input [18:0] read_addr_sram,
	input [18:0] write_addr_sram,
	input [4:0] client_priority,
	input [15:0] client_read_req,
	input [15:0][18:0] client_read_addr,
	output logic [18:0] base_addr_to_demux,
	output logic last_demux,
	output logic [3:0] num_of_last_valid_demux,
	output logic [15:0][4:0] client_to_send_fabric,
	output logic read_ddr,
	output logic [31:0] addr_read,
	output logic write_ddr,
	output logic [31:0] addr_write,
	output logic [15:0][4:0] num_bytes_valid,
	output logic [15:0] read_sram,
	output logic [15:0] write_sram
	);

	always @(posedge clk or negedge rst_n)
		if (!rst_n)begin
			read_ddr<='0;
			read_sram<='0;
			write_sram<='0;
		end
		else if (read_from_ddr) begin
				addr_read<=read_addr_ddr;
				read_ddr<=1'b1;
				base_addr_to_demux<=write_addr_sram;
				write_sram<=16'b11;
			end
			else begin
				read_ddr<=1'b0;	
			end
				
			
		
endmodule
