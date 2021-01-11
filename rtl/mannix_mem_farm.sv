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
	logic last;
	logic [3:0] num_of_last_valid;
	mem_mux_a i_mem_mux_a(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(read_ddr_req.mem_data),
	.data_valid(read_ddr_req.mem_valid),
	.base_addr(base_addr),
	.last (last),
	.num_of_last_valid(num_of_last_valid),
	.data_out(write_ddr_req.mem_data)
	);
/*
	mem_mux_b i_mem_mux_b(
	.clk(clk),
	.rst_n(rst_n),

	);

	mem_sram i_mem_sram(
	.clk(clk),
	.rst_n(rst_n),
	);

	mem_ctrl i_mem_ctrl(
	.clk(clk),
	.rst_n(rst_n),
	);
*/
endmodule
	
