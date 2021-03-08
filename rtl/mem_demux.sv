//======================================================================================================
//Module: mem_demux
//Description: get the data from the ddr and send it to the appropriate sram 
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 12-Jan-2021
//======================================================================================================
//TODO the send the data to the right sram, now the data send to all instead for just the 
//two relevant srams
module mem_demux 
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [15:0][255:0] data_in,
	input data_valid,
	input [18:0] base_addr,
	input last,
	input [3:0] num_of_last_valid,
	output logic [15:0] cs,
	output logic [15:0][255:0] data_out,
	output logic [15:0][18:0] addr_sram
	);

	always @(posedge clk or negedge rst_n)
		if(!rst_n)
			cs<='0;
		else if(data_valid)begin
			cs[1:0]<=2'b11;
				if (base_addr[5]==0) begin
					addr_sram[0]<={4'b0,base_addr[14:0]};
					addr_sram[1]<={4'b1,base_addr[14:0]};
					data_out[0]<=data_in[0];
					data_out[1]<=data_in[1];
				end
				else begin
					addr_sram[0]<={4'b0,base_addr[14:5]};
					addr_sram[1]<={4'b1,base_addr[14:5]};
					data_out[0]<=data_in[1];
					data_out[1]<=data_in[0];
				end
			end
			else
				cs[1:0]<=2'b00;
endmodule
