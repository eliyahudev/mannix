/*======================================================================================================
//Module: mannix_mem_farm
//Description: the wrapper of all module of the memory.
the sw responsible to load this module, this can be done in two ways:
	1. The sw send the addr to read from the ddr.
	2. the sw send the data directly
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 27-Nov-2020
//======================================================================================================*/
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
	mem_intf_read.client_read read_ddr_req, //req for reading from the ddr to this memory farm
	mem_intf_write.client_write write_ddr_req, //req for writing to the ddr from this memory farm
	mem_intf_write.client_write write_sw_req, //the sotware req for writing directly to this memory farm
	input [31:0] read_addr_ddr, // the addr to read from the ddr, come from the sw
	input [31:0] write_addr_ddr, // the writing addr in the ddr, come from the sw
	input [18:0] read_addr_sram,
	input [18:0] write_addr_sram,
	input read_from_ddr,
	input write_to_ddr,
	input [4:0] client_priority
	);
	logic [18:0] base_addr;
	logic last_demux;
	logic [3:0] num_of_last_valid_demux;
	logic [15:0][4:0] ctrl_fabric;
	logic [15:0] read_sram;
//	logic [15:0] write_sram; should be removed when test will pass
	logic [15:0][18:0] addr_sram;
	logic [15:0][255:0] data_out_sram, data_to_align, data_to_client, data_in_demux;
	logic [15:0][255:0] data_in_sram;
	logic [15:0][4:0] num_bytes_valid;
	logic [15:0] cs;
	logic [15:0] client_read_req;
	logic [15:0][18:0] client_read_addr;
	logic data_valid_demux, valid_to_demux;
	logic req_for_sw;
	logic [15:0][262143:0] debug_mem;

	assign client_read_req = {10'd0,fcc_pic_r.mem_req, fcc_wgt_r.mem_req, fcc_bias_r.mem_req, 
	cnn_pic_r.mem_req, cnn_wgt_r.mem_req, pool_r.mem_req};

	assign client_read_addr = {{10{19'b0}},fcc_pic_r.mem_start_addr, fcc_wgt_r.mem_start_addr,
	fcc_bias_r.mem_start_addr, cnn_pic_r.mem_start_addr, cnn_wgt_r.mem_start_addr, pool_r.mem_start_addr};

	
	mem_demux i_mem_demux(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(data_in_demux),
		.data_valid(data_valid_demux),
		.base_addr(base_addr),
		.last (last_demux),
		.num_of_last_valid(num_of_last_valid_demux),
		.data_out(data_in_sram),
		.cs(cs),
		.addr_sram(addr_sram),
		.demux_busy(demux_busy)
	);
	assign req_from_sw = write_sw_req.mem_req;
	assign data_valid_demux= req_from_sw ? valid_to_demux : read_ddr_req.mem_valid;
	assign data_in_demux = req_from_sw ? write_sw_req.mem_data : read_ddr_req.mem_data;

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
				.cs(cs[i]),
				.id(i[3:0]),
				.data_in(data_in_sram[i]),
				.read(read_sram[i]),
				.addr(addr_sram[i]),
				.write(cs[i]),
				.data_out(data_out_sram[i]),
				.debug_mem(debug_mem[i])
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
		.read_from_ddr(read_from_ddr),
		.write_addr_ddr(write_addr_ddr),
		.write_to_ddr(write_to_ddr),
		.client_priority(client_priority),
		.base_addr_to_demux(base_addr),
		.last_demux(last_demux),
		.num_of_last_valid_demux(num_of_last_valid_demux),
		.client_to_send_fabric(ctrl_fabric),
		.read_ddr(read_ddr_req.mem_req),
		.addr_read(read_ddr_req.mem_start_addr),
		.write_ddr(write_ddr_req.mem_req),
		.addr_write(write_ddr_req.mem_start_addr),
		.num_bytes_valid(num_bytes_valid),
		.client_read_req(client_read_req),
		.client_read_addr(client_read_addr),
		.read_sram(read_sram),
	//	.write_sram(write_sram),
		.read_addr_sram(read_addr_sram),
		.write_addr_sram(write_addr_sram),
		.write_sw_req (write_sw_req),
		.demux_busy(demux_busy),
		.valid_to_demux(valid_to_demux)
	);

endmodule
	
