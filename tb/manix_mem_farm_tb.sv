//======================================================================================================
//
// Module: manix_mem_farm_tb
//
// Design Unit Owner : Simhi Gerner
//                    
// Original Author   : Simhi Gerner
// Original Date     : 13-Jan-2021
//
//======================================================================================================



module manix_mem_farm_tb ();

	parameter WORD_WIDTH=8;
	parameter NUM_WORDS_IN_LINE=32;
	parameter ADDR_WIDTH=19;
	logic clk;
	logic rst_n;
	//port for memory
	logic [31:0] read_addr_ddr;
	logic read_from_ddr;
	logic write_to_ddr;
	logic [31:0] write_addr_ddr;
	logic [4:0] client_priority;
	logic [18:0] read_addr_sram;
	logic [18:0] write_addr_sram;
  
  	//interfaces
  	mem_intf_read mem_intf_read_wgt_fcc();
	mem_intf_read mem_intf_read_pic_fcc();
	mem_intf_read mem_intf_read_bias_fcc();
  	mem_intf_write mem_intf_write_fcc();
  	mem_intf_write mem_intf_write_pool();
  	mem_intf_read mem_intf_read_mx_pool();
  	mem_intf_write mem_intf_write_cnn();
  	mem_intf_read mem_intf_read_pic_cnn();
  	mem_intf_read mem_intf_read_wgt_cnn();
	mem_intf_read #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256))  read_ddr_req();
	mem_intf_write #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256)) write_ddr_req ();


  
   

	mannix_mem_farm i_mannix_mem_farm (
	.clk(clk),
	.rst_n(rst_n),
	.fcc_pic_r(mem_intf_read_pic_fcc),
	.fcc_wgt_r(mem_intf_read_wgt_fcc),
	.fcc_bias_r(mem_intf_read_bias_fcc),
	.cnn_pic_r(mem_intf_read_pic_cnn),
	.cnn_wgt_r(mem_intf_read_wgt_cnn),
	.pool_r(mem_intf_read_mx_pool),
	.fcc_w(mem_intf_write_fcc),
	.pool_w(mem_intf_write_pool),
	.cnn_w(mem_intf_write_cnn),
	.read_addr_ddr(read_addr_ddr),
	.read_from_ddr(read_from_ddr),
	.write_to_ddr(write_to_ddr),
	.write_addr_ddr(write_addr_ddr),
	.client_priority(client_priority),
	.read_ddr_req(read_ddr_req),
	.write_ddr_req(write_ddr_req),
	.read_addr_sram(read_addr_sram),
	.write_addr_sram(write_addr_sram)
	);
 

	always #5 clk = !clk;

	initial begin
      	clk= 1'b1;
      	rst_n = 1'b0;
      	write_to_ddr=1'b0;
      	read_from_ddr=1'b0;
      	mem_intf_read_mx_pool.mem_req=0;
      	mem_intf_read_wgt_cnn.mem_req=0;
		mem_intf_read_mx_pool.mem_start_addr=0;
      	mem_intf_read_wgt_cnn.mem_start_addr=0;
      	write_addr_sram=0;
      	#31 rst_n= 1'b1;
      	#9 read_from_ddr=1'b1;
		read_addr_ddr=255;
		wait (read_ddr_req.mem_req==1'b1) @(posedge clk)
		read_ddr_req.mem_valid=1'b1;
		read_ddr_req.mem_data[0]=1;
		read_ddr_req.mem_data[1]=2;
		#10 read_ddr_req.mem_valid=1'b0;
		mem_intf_read_mx_pool.mem_req=1;
      	mem_intf_read_wgt_cnn.mem_req=1;
		mem_intf_read_mx_pool.mem_start_addr=0;
      	mem_intf_read_wgt_cnn.mem_start_addr=0;
		#10 
		#30
      	$finish();
    end
 
  endmodule
