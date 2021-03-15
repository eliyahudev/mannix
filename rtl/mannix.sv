//======================================================================================================
// Module: manix
// Description: the wrapper of accelerators and the memory.
// Design Unit Owner: Simhi Gerner                  
// Original Author   : Simhi Gerner
// Original Date     : 13-Jan-2021
//======================================================================================================
module mannix #(
	parameter ADDR_WIDTH=19,
	parameter X_ROWS_NUM=128,
	parameter X_COLS_NUM=128,
				 
	parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM),
	parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM), 

	parameter Y_ROWS_NUM=4,
	parameter Y_COLS_NUM=4,
				 
	parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM),
	parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM),

	parameter DATA_ROWS_NUM=4,  
	parameter DATA_COLS_NUM=4,  
	parameter DATA_LOG2_ROWS_NUM = $clog2(DATA_ROWS_NUM),
	parameter DATA_LOG2_COLS_NUM = $clog2(DATA_COLS_NUM),

	parameter RES_ROWS_NUM=2,
	parameter RES_COLS_NUM=2,
	parameter OUT_LOG2_ROWS_NUM=$clog2(RES_ROWS_NUM),
	parameter OUT_LOG2_COLS_NUM=$clog2(RES_COLS_NUM)
	)
	(
	input 				clk,
	input 				rst_n,
	//port for memory
	input [31:0] 		read_addr_ddr,
	input [31:0] 		write_addr_ddr,
	input [18:0] 		read_addr_sram,
	input [18:0] 		write_addr_sram,
	input 				read_from_ddr,
	input 				write_to_ddr,
	input [4:0] 		client_priority,

	//port for fcc
	input [31:0] 		fc_addrx, 
  	input [31:0] 		fc_addry,
  	input [31:0] 		fc_addrb,
	input [31:0] 		fc_xm,
    input [31:0] 		fc_ym,
	input [31:0] 		fc_yn,
  	input [31:0] 		cnn_bn,
  	input 				fc_go,
  	output [31:0]		fc_addrz,
  	output reg 			fc_done,
	output reg 			fc_sw_busy_ind,
	
  	//port for pool
    input [ADDR_WIDTH-1:0]            sw_pool_rd_addr,	//POOL Data matrix FIRST address
    input [ADDR_WIDTH-1:0]            sw_pool_wr_addr,	//POOL return address
    input [DATA_LOG2_ROWS_NUM-1:0]    sw_pool_rd_m,  	//POOL data matrix num of rows
    input [DATA_LOG2_COLS_NUM-1:0]    sw_pool_rd_n,	//POOL data matrix num of columns
    input [OUT_LOG2_ROWS_NUM-1:0]     sw_pool_m,	//POOL size - rows
    input [OUT_LOG2_COLS_NUM-1:0]     sw_pool_n,	//POOL size - columns 
    output                            pool_sw_busy_ind,	//An output to the software - 1 – POOL unit is busy - 0 -POOL is available (Default)
  	//port for cnn
    input [ADDR_WIDTH-1:0]            sw_cnn_addr_bias, 	// CNN Bias value address
    input [ADDR_WIDTH-1:0]            sw_cnn_addr_x,	// CNN Data window FIRST address
    input [ADDR_WIDTH-1:0]            sw_cnn_addr_y,	// CNN  weights window FIRST address
    input [ADDR_WIDTH-1:0]            sw_cnn_addr_z,	// CNN return address
    input [X_LOG2_ROWS_NUM:0]         sw_cnn_x_m,  	// CNN data matrix num of rows
    input [X_LOG2_COLS_NUM:0]         sw_cnn_x_n,	        // CNN data matrix num of columns
    input [Y_LOG2_ROWS_NUM:0]         sw_cnn_y_m,	        // CNN weight matrix num of rows
    input [Y_LOG2_COLS_NUM:0]         sw_cnn_y_n,	        // CNN weight matrix num of columns 
    output reg                        cnn_sw_busy_ind,	// An output to the software - 1 – CNN unit is busy CNN is available (Default)

    input                             sw_cnn_go,          //Input from Software to start calculation
    output reg                        sw_cnn_done        //Output to Softare to inform on end of calculation
  	);

  	mem_intf_read mem_intf_read_wgt_fcc();
	mem_intf_read mem_intf_read_pic_fcc();
	mem_intf_read mem_intf_read_bias_fcc();
  	mem_intf_write mem_intf_write_fcc();
  	mem_intf_write mem_intf_write_pool();
  	mem_intf_read mem_intf_read_mx_pool();
  	mem_intf_write mem_intf_write_cnn();
  	mem_intf_read mem_intf_read_pic_cnn();
  	mem_intf_read mem_intf_read_wgt_cnn();
	mem_intf_read mem_intf_read_bias_cnn();
	mem_intf_read #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256))  read_ddr_req();
	mem_intf_write #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256)) write_ddr_req ();
	mem_intf_write #(.ADDR_WIDTH(19),.NUM_WORDS_IN_LINE(8), .WORD_WIDTH(32)) write_sw_req ();

  	fcc i_fcc (
		.clk(clk),
		.rst_n(rst_n),
		.fc_addrx(fc_addrx),
		.fc_addry(fc_addry),
		.fc_addrb(fc_addrb),
		.fc_addrz(fc_addrz),
		.fc_xm(fc_xm),
		.fc_ym(fc_ym),
		.fc_yn(fc_yn),
		.cnn_bn(cnn_bn),
		.fc_go(fc_go),
		.fc_done(fc_done),
		.mem_intf_write(mem_intf_write_fcc),
		.mem_intf_read_pic(mem_intf_read_pic_fcc),
		.mem_intf_read_wgt(mem_intf_read_wgt_fcc), 
		.mem_intf_read_bias(mem_intf_read_bias_fcc),        
		.fc_sw_busy_ind(fc_sw_busy_ind)
  	);

  

  	pool i_pool (
  		.clk(clk),
       	.rst_n(rst_n),
        .mem_intf_write(mem_intf_write_pool),
        .mem_intf_read_mx(mem_intf_read_mx_pool),    
        .pool_sw_busy_ind(pool_sw_busy_ind),
        .sw_pool_rd_addr(sw_pool_rd_addr),
        .sw_pool_wr_addr(sw_pool_wr_addr),
        .sw_pool_rd_m(sw_pool_rd_m),   
        .sw_pool_rd_n(sw_pool_rd_n),
        .sw_pool_m(sw_pool_m),   
        .sw_pool_n(sw_pool_n)
        );
	
	cnn #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.X_ROWS_NUM(X_ROWS_NUM),
		.X_COLS_NUM(X_COLS_NUM),
					 
		.X_LOG2_ROWS_NUM (X_LOG2_ROWS_NUM),
		.X_LOG2_COLS_NUM (X_LOG2_COLS_NUM), 
  
		.Y_ROWS_NUM(Y_ROWS_NUM),
		.Y_COLS_NUM(Y_COLS_NUM),
					 
		.Y_LOG2_ROWS_NUM (Y_LOG2_ROWS_NUM),
		.Y_LOG2_COLS_NUM (Y_LOG2_COLS_NUM)

	)i_cnn (
		.clk(clk),
       	.rst_n(rst_n),
		.mem_intf_write(mem_intf_write_cnn),
		.mem_intf_read_pic(mem_intf_read_pic_cnn),
        .mem_intf_read_wgt(mem_intf_read_wgt_cnn),
        .mem_intf_read_bias( mem_intf_read_bias_cnn),        
        .cnn_sw_busy_ind(cnn_sw_busy_ind),
        .sw_cnn_addr_bias(sw_cnn_addr_bias),
        .sw_cnn_addr_x(sw_cnn_addr_x),
        .sw_cnn_addr_y(sw_cnn_addr_y),
        .sw_cnn_addr_z(sw_cnn_addr_z),
        .sw_cnn_x_m(sw_cnn_x_m),  
        .sw_cnn_x_n(sw_cnn_x_n),
        .sw_cnn_y_m(sw_cnn_y_m),
        .sw_cnn_y_n(sw_cnn_y_n),
        .sw_cnn_go(sw_cnn_go),
        .sw_cnn_done(sw_cnn_done),
        //Debug output - Internal use
        .data2write_out()
	);

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
		.write_addr_sram(write_addr_sram),
		.write_sw_req(write_sw_req)
	);
	
endmodule
