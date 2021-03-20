//======================================================================================================
//Module: mem_ctrl
//Description: the controller of the memory
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 27-Nov-2020
//======================================================================================================
module mem_ctrl
	(
	input clk, // Clock
 	input rst_n, // Reset
 	mem_intf_write.client_write write_sw_req,
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
	//output logic [15:0] write_sram, should be removed when test will pass
	input logic demux_busy,
	output logic valid_to_demux
	);

//////////////////////////////////////
// requst to read data from the ddr///
//////////////////////////////////////
	always @(posedge clk or negedge rst_n)
		if (!rst_n)begin
			read_ddr<='0;
	//		write_sram<='0;
		end
		else if (read_from_ddr) begin
				addr_read<=read_addr_ddr;
				read_ddr<=1'b1;
		//		base_addr_to_demux<=write_addr_sram;
		//		write_sram<=16'b11;
			end
			else begin
				read_ddr<=1'b0;	
			end

	always @(posedge clk or negedge rst_n)
		if (!rst_n)begin
			read_sram<='0;
		end
		else if (client_read_req[0]) begin
				addr_read<=read_addr_ddr;
				read_ddr<=1'b1;
	//			base_addr_to_demux<=write_addr_sram;
	//			write_sram<=16'b11;
			end
			else begin
				read_ddr<=1'b0;	
			end
				
/////////////////////////////////////////////////////
// requst to write data directly from the software//
/////////////////////////////////////////////////////
	//send ack to the sw
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			write_sw_req.mem_ack<='0;	
		end
		else if (valid_to_demux)begin
				write_sw_req.mem_ack<=1'b1;
		end
			else
				write_sw_req.mem_ack<=1'b0;
	//send the address to the demux
/*	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			base_addr_to_demux<='0;
		end
		else begin
			base_addr_to_demux<=write_sw_req.mem_start_addr;
		end*/
	assign base_addr_to_demux=write_sw_req.mem_req ? write_sw_req.mem_start_addr : write_addr_sram;
	assign valid_to_demux = write_sw_req.mem_req && !demux_busy;
		
endmodule
