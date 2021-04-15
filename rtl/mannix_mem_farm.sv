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
`include "mem_intf.svh"
module mannix_mem_farm #(
	parameter WORD_WIDTH=8,
	parameter NUM_WORDS_IN_LINE=32,
	parameter ADDR_WIDTH=19
	)
	(
	input clk, // Clock
 	input rst_n, // Reset
	mem_intf_read.memory_read fcc_pic_r,
	mem_intf_read.memory_read fcc_wgt_r,
	mem_intf_read.memory_read fcc_bias_r,
	mem_intf_read.memory_read cnn_pic_r,
	mem_intf_read.memory_read cnn_wgt_r,
	mem_intf_read.memory_read cnn_bias_r,
	mem_intf_read.memory_read pool_r,
	mem_intf_write.memory_write fcc_w,
	mem_intf_write.memory_write cnn_w,
	mem_intf_write.memory_write pool_w,
	mem_intf_write.memory_write sw_w, //req dor writing the memory -intf like the clients
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
	logic [15:0][18:0] addr_sram_from_demux, addr_sram, addr_sram_from_req_ctrl;
	logic [15:0][255:0] data_out_sram, data_to_align, data_to_client, data_in_demux;
	logic [15:0][255:0] data_in_sram, data_req_ctrl_to_sram, data_from_demux;
	logic [15:0][4:0] num_bytes_valid;
	logic [15:0] cs, cs_req, cs_init;
	logic [15:0] client_read_req;
	logic [15:0] read_req_ctrl,write_req_ctrl, write_sram;
	logic [15:0][18:0] client_read_addr;
	logic data_valid_demux, valid_to_demux;
	logic req_for_sw, req_for_sw_demux;
	logic [15:0][262143:0] debug_mem;
	logic [15:0] mask_enable;
	logic [15:0][255:0] mask;
	logic [15:0][15:0] req_arb, gnt_arb, req_req_ctrl, gnt_req_ctrl;
	assign client_read_req = {10'd0,fcc_pic_r.mem_req, fcc_wgt_r.mem_req, fcc_bias_r.mem_req, 
	cnn_pic_r.mem_req, cnn_wgt_r.mem_req, pool_r.mem_req};

	assign client_read_addr = {{10{19'b0}},fcc_pic_r.mem_start_addr, fcc_wgt_r.mem_start_addr,
	fcc_bias_r.mem_start_addr, cnn_pic_r.mem_start_addr, cnn_wgt_r.mem_start_addr, pool_r.mem_start_addr};
	// divide the interface signal to input and output structs
	// because array of interface cannot be
	req_ctrl_in_s [15:0] req_ctrl_in;
	req_ctrl_out_s [15:0] req_ctrl_out;
	
	assign req_ctrl_in[0] = {fcc_pic_r.mem_req, fcc_pic_r.mem_start_addr, fcc_pic_r.mem_size_bytes, 295'd0 };
	assign req_ctrl_in[1] = {fcc_wgt_r.mem_req, fcc_wgt_r.mem_start_addr, fcc_wgt_r.mem_size_bytes, 295'd0 };
	assign req_ctrl_in[2] = {fcc_bias_r.mem_req, fcc_bias_r.mem_start_addr, fcc_bias_r.mem_size_bytes, 295'd0 };
	//assign req_ctrl_in[3] = '0; //TODO back the interfce
	assign req_ctrl_in[3] = {cnn_pic_r.mem_req, cnn_pic_r.mem_start_addr, cnn_pic_r.mem_size_bytes, 295'b0 };
	//assign req_ctrl_in[4] = '0;
	assign req_ctrl_in[4] = {cnn_wgt_r.mem_req, cnn_wgt_r.mem_start_addr, cnn_wgt_r.mem_size_bytes, 295'b0 };
	assign req_ctrl_in[5] = {pool_r.mem_req, pool_r.mem_start_addr, pool_r.mem_size_bytes, 295'b0 };
	//assign req_ctrl_in[6] = '0;
	assign req_ctrl_in[6] = {39'b0, cnn_bias_r.mem_req, cnn_bias_r.mem_start_addr, cnn_bias_r.mem_size_bytes, cnn_bias_r.mem_data };
	assign req_ctrl_in[7] = {39'd0, fcc_w.mem_req, fcc_w.mem_start_addr, fcc_w.mem_size_bytes, fcc_w.mem_data };
	assign req_ctrl_in[8] = {39'd0, cnn_w.mem_req, cnn_w.mem_start_addr, cnn_w.mem_size_bytes, cnn_w.mem_data };
	assign req_ctrl_in[9] = {39'd0, pool_w.mem_req, pool_w.mem_start_addr, pool_w.mem_size_bytes, pool_w.mem_data };
	assign req_ctrl_in[10] = {39'd0, sw_w.mem_req, sw_w.mem_start_addr, sw_w.mem_size_bytes, sw_w.mem_data };
	
	assign req_ctrl_in[15:11] = '0;

	assign  {fcc_pic_r.mem_valid, fcc_pic_r.mem_data} = req_ctrl_out[0][257:1];
	assign  {fcc_wgt_r.mem_valid, fcc_wgt_r.mem_data} = req_ctrl_out[1][257:1];
	assign  {fcc_bias_r.mem_valid, fcc_bias_r.mem_data} = req_ctrl_out[2][257:1];
	assign  {cnn_pic_r.mem_valid, cnn_pic_r.mem_data} = req_ctrl_out[3][257:1];
	assign  {cnn_wgt_r.mem_valid, cnn_wgt_r.mem_data} = req_ctrl_out[4][257:1];
	assign  {pool_r.mem_valid, pool_r.mem_data} = req_ctrl_out[5][257:1];
	assign  {cnn_bias_r.mem_valid, cnn_bias_r.mem_data} = req_ctrl_out[6][257:1];

	assign fcc_w.mem_ack = req_ctrl_out[7][0];
	assign cnn_w.mem_ack = req_ctrl_out[8][0];
	assign pool_w.mem_ack = req_ctrl_out[9][0];
	assign sw_w.mem_ack = req_ctrl_out[10][0];

	mem_demux i_mem_demux(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(data_in_demux),
		.data_valid(data_valid_demux),
		.base_addr(base_addr),
		.last (last_demux),
		.num_of_last_valid(num_of_last_valid_demux),
		.data_out(data_from_demux),
		.cs(cs_init),
		.addr_sram(addr_sram_from_demux),
		.demux_busy(demux_busy)
	);
/*	always @(posedge clk or negedge rst_n)
			if (!rst_n) begin
				req_for_sw<=1'b0;
			end
			else if (sw_w.mem_req)
				req_for_sw<=1'b1;
			else
				req_for_sw<=1'b0;*/
	assign req_for_sw_demux = write_sw_req.mem_req;
	assign data_valid_demux= req_for_sw_demux ? valid_to_demux : read_ddr_req.mem_valid;
	assign data_in_demux = req_for_sw_demux ? write_sw_req.mem_data : read_ddr_req.mem_data;
	assign cs= |cs_req ? cs_req : cs_init; 
	assign write_sram = |cs_req ? write_req_ctrl : cs_init;
	assign data_in_sram = sw_w.mem_req ? data_req_ctrl_to_sram : data_from_demux;
	assign addr_sram = write_sw_req.mem_req ?  addr_sram_from_demux : addr_sram_from_req_ctrl; 

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
				.read(read_req_ctrl),
				.addr(addr_sram[i]),
				.write(write_sram[i]),
				.data_out(data_out_sram[i]),
				.mask_enable(mask_enable[i]),
				.mask(mask[i]),
				.debug_mem(debug_mem[i])	
				);

			mem_align i_mem_align(
				.clk(clk),
				.rst_n(rst_n),
				.data_in(data_to_align[i]),
				.num_bytes(num_bytes_valid[i]),
				.data_out(data_to_client[i])
			);
			mem_arbiter #(.PORTS(16)) i_mem_arbiter(
				.clk(clk),
				.rst_n(rst_n),
				.req(req_arb[i]),
				.gnt(gnt_arb[i])
			);
			
			

				
		end
	endgenerate
			mem_req_ctrl i_req_ctrl(
				.clk(clk),
				.rst_n(rst_n),
				.intf_in(req_ctrl_in),
				.intf_out(req_ctrl_out),
				.req(req_arb),
				.gnt(gnt_arb),
				.data_in(data_out_sram),
				.data_out(data_req_ctrl_to_sram),
				.mask(mask),
				.mask_enable(mask_enable),
				.req_sram(cs_req),
				.addr_to_sram(addr_sram_from_req_ctrl),
				.read(read_req_ctrl),
				.write(write_req_ctrl)
			);  
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
	
