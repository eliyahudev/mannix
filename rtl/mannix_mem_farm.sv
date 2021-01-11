//======================================================================================================
//Module: mannix_mem_farm
//Description:
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 27-Nov-2020
//======================================================================================================
module mannix_mem_farm (
	input clk, // Clock
 	input rst_n, // Reset
	mem_intf_read.memory_read fcc_pic_r,
	mem_intf_read.memory_read fcc_wgt_r,
	mem_intf_read.memory_read fcc_bias_r,
	mem_intf_read.memory_read cnn_pic_r,
	mem_intf_read.memory_read cnn_wgt_r,
	mem_intf_read.memory_read pool_r,
	mem_intf_write.memory_write fcc_w,
	mem_intf_write.memory_write cnn_w,
	mem_intf_write.memory_write pool_w,
	mem_intf_read.client_read read_ddr_req,
	mem_intf_write.client_write write_ddr_req,
	input [31:0] read_addr_ddr,
	input [31:0] write_addr_ddr,
	input [4:0] client_priority
	);
	logic [18:0] base_addr;
	logic last_demux;
	logic [3:0] num_of_last_valid_demux;
	logic [15:0][4:0] ctrl_fabric;
	logic [15:0] read_sram;
	logic [15:0] write_sarm;
	logic [15:0][18:0] addr_sram;
	logic [15:0][255:0] data_out_sram, data_to_align, data_to_client;
	logic [15:0][255:0] data_in_sram;
	logic [15:0][4:0] num_bytes_valid;


	mem_demux i_mem_demux(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(read_ddr_req.mem_data),
	.data_valid(read_ddr_req.mem_valid),
	.base_addr(base_addr),
	.last (last_demux),
	.num_of_last_valid(num_of_last_valid_demux),
	.data_out(data_in_sram)
	);

	mem_fabric i_mem_fabric(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(data_out_sram),
	.client_to_send(ctrl_fabric),
	.data_out(data_to_align)

	);
	genvar i;
	generate
		for (i=0; i < 16; i++) begin: loop
			mem_sram i_mem_sram(
			.clk(clk),
			.rst_n(rst_n),
			.data_in(data_in_sram[i]),
			.read(read_sram[i]),
			.addr(addr_sram[i]),
			.write(write_sarm[i]),
			.data_out(data_out_sram[i])
			);

			mem_align i_mem_align(
			.clk(clk),
			.rst_n(rst_n),
			.data_in(data_to_align[i]),
			.num_bytes(num_bytes_valid[i]),
			.data_out(data_to_client[i])
			);
		end
	endgenerate
	mem_ctrl i_mem_ctrl(
	.clk(clk),
	.rst_n(rst_n),
	.read_addr_ddr(read_addr_ddr),
	.write_addr_ddr(write_addr_ddr),
	.client_priority(client_priority),
	.base_addr_to_demux(base_addr),
	.last_demux(last_demux),
	.num_of_last_valid_demux(num_of_last_valid_demux),
	.client_to_send_fabric(ctrl_fabric),
	.read(read_ddr_req.mem_req),
	.addr_read(read_ddr_req.mem_start_addr),
	.write(write_ddr_req.mem_req),
	.addr_write(write_ddr_req.mem_start_addr),
	.num_bytes_valid(num_bytes_valid),
	.addr_sram(addr_sram)
	);

endmodule
	
