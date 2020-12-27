module mannix_mem_farm (
	mem_intf_read.memory_read fcc_pic_r,
	mem_intf_read.memory_read fcc_wgt_r,
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
endmodule
	
