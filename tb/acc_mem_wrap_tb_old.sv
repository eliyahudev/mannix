//======================================================================================================
//
// Module: acc_cnn_tb
//
// Design Unit Owner :Nitzan Dabush
//                    
// Original Author   :Nitzan Dabush
// Original Date     : 22-Nov-2020
//
//======================================================================================================

module acc_mem_wrap_tb ();



parameter DEPTH=4;

parameter   CLK_PERIOD = 5;


parameter JUMP_COL=1;
parameter JUMP_ROW=1;
parameter WORD_WIDTH=8;
parameter NUM_WORDS_IN_LINE=32;
parameter ADDR_WIDTH=19;

//parameter ADDR_WIDTH=12; //TODO: check width
parameter MAX_BYTES_TO_RD=20;
parameter LOG2_MAX_BYTES_TO_RD=$clog2(MAX_BYTES_TO_RD);  
parameter MAX_BYTES_TO_WR=5;  
parameter LOG2_MAX_BYTES_TO_WR=$clog2(MAX_BYTES_TO_WR);
parameter MEM_DATA_BUS=128;

parameter X_ROWS_NUM=128;
parameter X_COLS_NUM=128;

parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 


parameter Y_ROWS_NUM=4;
parameter Y_COLS_NUM=4;

parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);

parameter DP_DEPTH=4;
//=================================================================================

parameter FCC_DP_DEPTH=32; 		 		// How many bytes DP every time.

parameter FCC_X_ROWS_NUM=128;			//Data: vector of (X_COLS_NUM , X_ROWS_NUM)
parameter FCC_X_COLS_NUM=1;

parameter FCC_X_LOG2_ROWS_NUM =$clog2(FCC_X_ROWS_NUM);
parameter FCC_X_LOG2_COLS_NUM =$clog2(FCC_X_COLS_NUM); 


parameter FCC_Y_ROWS_NUM=128;
parameter FCC_Y_COLS_NUM=128;

parameter FCC_Y_LOG2_ROWS_NUM =$clog2(FCC_Y_ROWS_NUM);
parameter FCC_Y_LOG2_COLS_NUM =$clog2(FCC_Y_COLS_NUM);

parameter FCC_CNT_32_MAX = X_ROWS_NUM/32;

//Non Changing parameters:

parameter FCC_WORD_WIDTH=8;
parameter FCC_NUM_WORDS_IN_LINE=32;
parameter FCC_ADDR_WIDTH=19;

//Not used Parameters :                      

parameter FCC_MAX_BYTES_TO_RD=20;
parameter FCC_LOG2_MAX_BYTES_TO_RD=$clog2(FCC_MAX_BYTES_TO_RD);  
parameter FCC_MAX_BYTES_TO_WR=5;  
parameter FCC_LOG2_MAX_BYTES_TO_WR=$clog2(FCC_MAX_BYTES_TO_WR);
parameter FCC_MEM_DATA_BUS=128;





//===============================================================================

reg         clk;
reg         rst_n;
reg         clk_config_tb;
reg         clk_enable;

reg [((X_COLS_NUM*X_ROWS_NUM)-1):0] [7:0]  a_data; 
//reg signed [7:0]  w_data [0:((Y_COLS_NUM*Y_ROWS_NUM)-1)];
reg signed [((Y_COLS_NUM*Y_ROWS_NUM)-1):0][7:0]  w_data; 
reg [31:0][7:0] bias_data;

//====================      
// Software Interface
//====================
reg [ADDR_WIDTH-1:0]            sw_cnn_addr_bias;     // CNN Bias value address		
reg [ADDR_WIDTH-1:0]            sw_cnn_addr_x;	// CNN Data window FIRST address
reg [ADDR_WIDTH-1:0]            sw_cnn_addr_y;	// CNN  weights window FIRST address
reg [ADDR_WIDTH-1:0]            sw_cnn_addr_z;	// CNN return address
reg [X_LOG2_ROWS_NUM:0]       sw_cnn_x_m;  	        // CNN data matrix num of rows
reg [X_LOG2_COLS_NUM:0]       sw_cnn_x_n;	        // CNN data matrix num of columns
reg [Y_LOG2_ROWS_NUM:0]       sw_cnn_y_m;	        // CNN weight matrix num of rows
reg [Y_LOG2_COLS_NUM:0]       sw_cnn_y_n;	        // CNN weight matrix num of columns 
wire                            cnn_sw_busy_ind;	// An output to the software - 1 – CNN unit is busy CNN is available (Default)

reg                             cnn_go;
wire                            cnn_done;

reg                             mem_intf_write_mem_gnt;

reg                             mem_intf_read_pic_mem_gnt;
reg                             mem_intf_read_pic_last;

reg [31:0][7:0]                 mem_intf_read_pic_mem_data;

reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_pic_mem_last_valid ;

reg                                              mem_intf_read_wgt_mem_gnt;
reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_wgt_last;
reg signed [31:0][7:0]                           mem_intf_read_wgt_mem_data;
reg                                              mem_intf_read_wgt_mem_last_valid;

reg                                              mem_intf_read_bias_mem_gnt;
reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_bias_last;
reg signed [31:0][7:0]                           mem_intf_read_bias_mem_data;
reg                                              mem_intf_read_bias_mem_last_valid;

reg [7:0] calc_row;
reg signed [34:0] sum_res_real;
reg signed [31:0]       avrg;

wire signed [31:0] data2write_out;
wire [7:0]  activation_out_smpl;

reg [7:0] index;
reg signed [7:0] data [0:3] ;
reg signed [7:0] weights [0:3];
reg [7:0] results [0:15624];
reg signed [31:0] results_real [0:15624];
//reg signed [16:0] bias ;
//reg [17:0] result;


integer dta;
integer wgt;
integer b;
integer res;
integer res_real;
integer scan;

//====================      
// FCC
//====================		
reg [ADDR_WIDTH-1:0]            fc_addrx;		// FC Data window FIRST address
reg [ADDR_WIDTH-1:0]            fc_addry;		// FC  weights window FIRST address
reg [ADDR_WIDTH-1:0]            fc_addrz;		// FC return address
reg [ADDR_WIDTH-1:0]	 	  fc_addrb;
reg [X_LOG2_ROWS_NUM-1:0]       fc_xm;  		// FC data matrix num of *rows*
reg [Y_LOG2_ROWS_NUM-1:0]       fc_ym;	      	// FC weight matrix num of *rows*
reg [Y_LOG2_COLS_NUM-1:0]       fc_yn;	        // FC weight matrix num of *columns* 
wire                            fc_sw_busy_ind;	// An output to the software - 1 – FC unit is busy FC is available (Default)
reg 				fc_done;		// Indicating FC finished
reg				fc_go;			// Indicating FC to start
reg [X_LOG2_ROWS_NUM-1:0] 	cnn_bn;
reg                         			   fcc_mem_intf_write_mem_ack;

reg                             		   fcc_mem_intf_read_pic_mem_valid;
reg                             		   fcc_mem_intf_read_pic_last;

reg signed [31:0][WORD_WIDTH - 1:0]  		   fcc_mem_intf_read_pic_mem_data;

reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] fcc_mem_intf_read_pic_mem_last_valid ;

reg                                              fcc_mem_intf_read_wgt_mem_valid;
reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] fcc_mem_intf_read_wgt_last;
reg signed [31:0][WORD_WIDTH - 1:0]              fcc_mem_intf_read_wgt_mem_data;
reg                                              fcc_mem_intf_read_wgt_mem_last_valid;

reg                                              fcc_mem_intf_read_bias_mem_valid;
reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] fcc_mem_intf_read_bias_last;
reg signed [31:0]	                           fcc_mem_intf_read_bias_mem_data;
reg                                              fcc_mem_intf_read_bias_mem_last_valid;


reg [WORD_WIDTH - 1:0] fcc_data [0:31] ;
reg signed [WORD_WIDTH - 1:0] fcc_weights [0:31];
reg signed [31:0] fcc_bias ;
reg signed [31:0] fcc_result [0:X_ROWS_NUM - 1];


integer fcc_dta;
integer fcc_wgt;
integer fcc_b;
integer fcc_res;
integer fcc_scan;



//============mem=============

//port for memory
logic [31:0] read_addr_ddr;
logic read_from_ddr;
logic write_to_ddr;
logic [31:0] write_addr_ddr;
logic [4:0]  client_priority;
logic [18:0] read_addr_sram;
logic [18:0] write_addr_sram;
logic odd;
integer which_part, which_bank, which_addr,mem_start_addr_fixed, start_addr;
logic [16383:0][255:0] values_of_memory;
logic mem_ack;
mem_intf_write mem_intf_write_sw();
mem_intf_read mem_intf_read_bias_cnn();
logic [31:0][7:0] load_data;


//==============================================================================================
//   
always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;



initial
begin
	//CNN
	// dta = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/data.txt", "r");
	// wgt = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/weights.txt", "r");
	// res_real = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/res_real.txt", "r");
	// res = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/results_after_activation.txt", "r");

	dta = $fopen("../txt_files/128x128/data.txt", "r");
	wgt = $fopen("../txt_files/128x128/weights.txt", "r");
	res_real = $fopen("../txt_files/128x128/res_real.txt", "r");
	res = $fopen("../txt_files/128x128/results_after_activation.txt", "r");

	clk_enable = 1'b1;
	clk_config_tb   = 1'b0;
	cnn_go=1'b0;
	sum_res_real=35'd0;
	avrg=32'd0;

	for (integer k=0;k<(X_ROWS_NUM*X_COLS_NUM);k=k+1)
	begin
		scan=$fscanf(dta,"%d\n",a_data[k]);
	end

	for (integer s=0;s<(Y_ROWS_NUM*Y_COLS_NUM);s=s+1)
	begin
		scan=$fscanf(wgt,"%d\n",w_data[s]);
	end

	for (integer r=0;r<((X_ROWS_NUM-3'd3)*(X_COLS_NUM-3'd3));r=r+1)
	begin
		scan=$fscanf(res,"%d\n",results[r]);

	end

	for (integer r1=0;r1<((X_ROWS_NUM-3'd3)*(X_COLS_NUM-3'd3));r1=r1+1)
	begin
		scan=$fscanf(res_real,"%d\n",results_real[r1]);
		sum_res_real=sum_res_real+results_real[r1];
	end
	bias_data='d0;
	avrg=sum_res_real/15625;

	$monitor("START CNN TEST\n");

	RESET_VALUES();
	ASYNC_RESET();
	MEM_LOAD(a_data, X_ROWS_NUM*X_COLS_NUM, 0);
	MEM_LOAD(w_data, Y_ROWS_NUM*Y_COLS_NUM, 65536);
	MEM_LOAD(bias_data, 32, 1<<16);
	//MEM_READ(a_data, X_ROWS_NUM*X_COLS_NUM, 0);



	@(posedge clk)
	cnn_go=1'b1;
//	TEST_128X128_4X4();
	wait(cnn_done)
	cnn_go=1'b0;
	#100;
	//FCC
	$monitor("START FCC TEST\n");

	fcc_dta = $fopen("../txt_files/data_bin.txt", "r");
	fcc_wgt = $fopen("../txt_files/weights_bin.txt", "r");
	fcc_b   = $fopen("../txt_files/bias_bin.txt", "r");
	fcc_res = $fopen("../txt_files/result_bin.txt", "r");


	FCC_RESET_VALUES();
	ASYNC_RESET();
	FCC_READ_RESULT();

	//The task that start it all!
	//  FCC_TEST_128X128();

	#100;


	$stop;
end // initial begin



mem_intf_read mem_intf_read_pic();

// assign mem_intf_read_pic.mem_valid=mem_intf_read_pic_mem_gnt;
// assign mem_intf_read_pic.last=mem_intf_read_pic_last;
// assign mem_intf_read_pic.mem_data=mem_intf_read_pic_mem_data;
// assign mem_intf_read_pic.mem_last_valid=mem_intf_read_pic_mem_last_valid;


mem_intf_read mem_intf_read_wgt();

// assign mem_intf_read_wgt.mem_valid=mem_intf_read_wgt_mem_gnt;
// assign mem_intf_read_wgt.last=mem_intf_read_wgt_last;
// assign mem_intf_read_wgt.mem_data=mem_intf_read_wgt_mem_data;
// assign mem_intf_read_wgt.mem_last_valid=mem_intf_read_wgt_mem_last_valid;

mem_intf_read mem_intf_read_bias();

// assign mem_intf_read_bias.mem_valid=mem_intf_read_bias_mem_gnt;
// assign mem_intf_read_bias.last=mem_intf_read_bias_last;
// assign mem_intf_read_bias.mem_data=mem_intf_read_bias_mem_data;
// assign mem_intf_read_bias.mem_last_valid=mem_intf_read_bias_mem_last_valid;  

mem_intf_write mem_intf_write();

//assign mem_intf_write.mem_ack=mem_intf_write_mem_gnt; 

//==================== FCC =======================================================


mem_intf_read fcc_mem_intf_read_pic();
//assigning the Grant from memory to our's. 
// assign fcc_mem_intf_read_pic.mem_valid=fcc_mem_intf_read_pic_mem_valid;
// assign fcc_mem_intf_read_pic.last=fcc_mem_intf_read_pic_last;
// assign fcc_mem_intf_read_pic.mem_data=fcc_mem_intf_read_pic_mem_data;
// assign fcc_mem_intf_read_pic.mem_last_valid=fcc_mem_intf_read_pic_mem_last_valid;

//-------------------------------------------------------------------------------------------
//Reading the weights
mem_intf_read fcc_mem_intf_read_wgt();

// assign fcc_mem_intf_read_wgt.mem_valid=fcc_mem_intf_read_wgt_mem_valid;
// assign fcc_mem_intf_read_wgt.last=fcc_mem_intf_read_wgt_last;
// assign fcc_mem_intf_read_wgt.mem_data=fcc_mem_intf_read_wgt_mem_data;
// assign fcc_mem_intf_read_wgt.mem_last_valid=fcc_mem_intf_read_wgt_mem_last_valid;

//-------------------------------------------------------------------------------------------
//Reading the biases
mem_intf_read fcc_mem_intf_read_bias();           
// assign fcc_mem_intf_read_bias.mem_valid=fcc_mem_intf_read_bias_mem_valid;
// assign fcc_mem_intf_read_bias.last=fcc_mem_intf_read_bias_last;
// assign fcc_mem_intf_read_bias.mem_data=fcc_mem_intf_read_bias_mem_data;
// assign fcc_mem_intf_read_bias.mem_last_valid=fcc_mem_intf_read_bias_mem_last_valid;
//-------------------------------------------------------------------------------------------

mem_intf_write fcc_mem_intf_write();
//assign fcc_mem_intf_write.mem_ack=fcc_mem_intf_write_mem_ack;


//simhi

//DUMMY I/F
mem_intf_read pool_r();
mem_intf_write pool_w();
initial begin
	pool_r.mem_req=1'b0;
	pool_r.mem_start_addr='0;
	pool_r.mem_size_bytes='0;
	pool_w.mem_req=1'b0;
	pool_w.mem_start_addr='0;
	pool_w.mem_size_bytes='0;
end

mem_intf_read #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256))  read_ddr_req();
mem_intf_write #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256)) write_ddr_req ();
mem_intf_write #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256)) write_sw_req ();

mannix_mem_farm mannix_mem_farm_ins (
		.clk(clk), // Clock
		.rst_n(rst_n), // Reset
		.fcc_pic_r(fcc_mem_intf_read_pic),
		.fcc_wgt_r(fcc_mem_intf_read_wgt),
		.fcc_bias_r(fcc_mem_intf_read_bias),
		.cnn_pic_r(mem_intf_read_pic),
		.cnn_wgt_r(mem_intf_read_wgt),
		.cnn_bias_r(mem_intf_read_bias),
		.sw_w(mem_intf_write_sw),
		.pool_r(pool_r),//DUMMY
		.fcc_w(fcc_mem_intf_write),
		.cnn_w(mem_intf_write),
		.pool_w(pool_w),//DUMMY

		.read_from_ddr(read_from_ddr),
			.write_to_ddr(write_to_ddr),
			.read_addr_sram(read_addr_sram),
			.write_addr_sram(write_addr_sram),
			.write_sw_req(write_sw_req),

			.read_ddr_req(read_ddr_req),
			.write_ddr_req(write_ddr_req),
			.read_addr_ddr(read_addr_ddr),
			.write_addr_ddr(write_addr_ddr),
			.client_priority(client_priority)
		);






	fcc  #(

		.DP_DEPTH(FCC_DP_DEPTH),
		.ADDR_WIDTH(ADDR_WIDTH),

		.MAX_BYTES_TO_RD(FCC_MAX_BYTES_TO_RD),
		.LOG2_MAX_BYTES_TO_RD(FCC_LOG2_MAX_BYTES_TO_RD),  
		.MAX_BYTES_TO_WR(FCC_MAX_BYTES_TO_WR),  
		.LOG2_MAX_BYTES_TO_WR(FCC_LOG2_MAX_BYTES_TO_WR),
		.MEM_DATA_BUS(FCC_MEM_DATA_BUS),

		.CNT_32_MAX(FCC_CNT_32_MAX),

		.X_ROWS_NUM(FCC_X_ROWS_NUM),
		.X_COLS_NUM(FCC_X_COLS_NUM),

		.X_LOG2_ROWS_NUM(FCC_X_LOG2_ROWS_NUM),
		.X_LOG2_COLS_NUM(FCC_X_LOG2_COLS_NUM), 


		.Y_ROWS_NUM(FCC_Y_ROWS_NUM),
		.Y_COLS_NUM(FCC_Y_COLS_NUM),

		.Y_LOG2_ROWS_NUM(FCC_Y_LOG2_ROWS_NUM),
		.Y_LOG2_COLS_NUM(FCC_Y_LOG2_COLS_NUM)

	)fcc_ins (
		.clk(clk),
		.rst_n(rst_n),

		.mem_intf_write(fcc_mem_intf_write),
		.mem_intf_read_pic(fcc_mem_intf_read_pic),
		.mem_intf_read_wgt(fcc_mem_intf_read_wgt),
		.mem_intf_read_bias(fcc_mem_intf_read_bias),

		.fc_sw_busy_ind(fc_sw_busy_ind),
		.fc_addrx(fc_addrx),
		.fc_addry(fc_addry),
		.fc_addrz(fc_addrz),
		.fc_addrb(fc_addrb),
		.fc_xm(fc_xm),   
		.fc_ym(fc_ym),
		.fc_yn(fc_yn),
		.cnn_bn(cnn_bn),

		.fc_go(fc_go),
		.fc_done(fc_done)

	);






cnn #(
	.DP_DEPTH(DP_DEPTH),
	.JUMP_COL(JUMP_COL),
	.JUMP_ROW(JUMP_ROW),    
	.ADDR_WIDTH(ADDR_WIDTH),

	.X_ROWS_NUM(X_ROWS_NUM),
	.X_COLS_NUM(X_COLS_NUM),

	.Y_ROWS_NUM(Y_ROWS_NUM),
	.Y_COLS_NUM(Y_COLS_NUM)

)cnn_ins(
	.clk(clk),
	.rst_n(rst_n),

	.mem_intf_write(mem_intf_write),
	.mem_intf_read_pic(mem_intf_read_pic),
	.mem_intf_read_wgt(mem_intf_read_wgt),
	.mem_intf_read_bias(mem_intf_read_bias),  

	.cnn_sw_busy_ind(cnn_sw_busy_ind),
	. sw_cnn_addr_bias(sw_cnn_addr_bias), 
	.sw_cnn_addr_x(sw_cnn_addr_x),
	.sw_cnn_addr_y(sw_cnn_addr_y),
	.sw_cnn_addr_z(sw_cnn_addr_z),
	.sw_cnn_x_m(sw_cnn_x_m),   
	.sw_cnn_x_n(sw_cnn_x_n),
	.sw_cnn_y_m(sw_cnn_y_m),
	.sw_cnn_y_n(sw_cnn_y_n),

	.sw_cnn_go(cnn_go),
	.sw_cnn_done(cnn_done),
	//Debug
	.data2write_out(data2write_out),   
	.activation_out_smpl(activation_out_smpl)

);




//===================
//      TASKS
//=================== 
//  integer i ;

task ASYNC_RESET();
	begin
		rst_n = 1'b1;
		#1
		rst_n = 1'b0;
		#30
		rst_n= 1'b1;
		#5;
	end
endtask // ASYNC_RESET

task RESET_VALUES();
	begin

		calc_row <=8'd0;
		index<=8'd0;
		mem_intf_write_mem_gnt=1'b0;

		mem_intf_read_pic_mem_gnt=1'b0;
		mem_intf_read_pic_last=1'b0;
		mem_intf_read_pic_mem_data='d0;
		mem_intf_read_pic_mem_last_valid='d0; 

		mem_intf_read_wgt_mem_gnt=1'b0;
		mem_intf_read_wgt_last=1'b0;
		mem_intf_read_wgt_mem_data='d0;
		mem_intf_read_wgt_mem_last_valid='d0;

		mem_intf_read_bias_mem_gnt=1'b0;
		mem_intf_read_bias_last=1'b0;
		mem_intf_read_bias_mem_data='d0;
		mem_intf_read_bias_mem_last_valid='d0;    

		write_to_ddr=1'b0;
		read_from_ddr=1'b0;
		read_ddr_req.mem_valid=1'b0;
		write_addr_sram=0;
		write_sw_req.mem_req=1'b0;
		write_sw_req.last=1'b1;
		write_sw_req.mem_last_valid = 1'b0;
		mem_intf_write_sw.mem_req=1'b0;
		mem_intf_write_sw.mem_start_addr='0;
		mem_intf_write_sw.mem_size_bytes='0;


		//sw_cnn_addr_bias={ADDR_WIDTH{1'b0}}; // CNN Bias value address 
		sw_cnn_addr_x={ADDR_WIDTH{1'b0}};	// CNN Data window FIRST address
		sw_cnn_addr_y='d65536;	//2^16 CNN  weights window FIRST address
		sw_cnn_addr_bias='d131072; //2*2^16==d131072 CNN Bias value address
		sw_cnn_addr_z='d196608;	//3*2^16==196608 CNN return address
		sw_cnn_x_m=X_ROWS_NUM;  	        // CNN data matrix num of rows
		sw_cnn_x_n=X_COLS_NUM;	        // CNN data matrix num of columns
		sw_cnn_y_m=Y_ROWS_NUM;	        // CNN weight matrix num of rows
		sw_cnn_y_n=Y_COLS_NUM;	        // CNN weight matrix num of columns



	end
endtask // ASYNC_RESET
integer data_mem,scan_mem;
integer addr_sram;

task MEM_LOAD(input reg [((X_COLS_NUM*X_ROWS_NUM)-1):0] [7:0] data_8_bit, input integer size, integer start_addr);
	data_mem = $fopen("../txt_files/data_bin.txt", "r");
	addr_sram=0;
	clk_enable = 1'b1;

		repeat (2) begin
			@ (posedge clk) ;
		end
	for (integer out=0;out<(size/32)+((size%32)!=0);out=out+1) begin
	for (integer k=0;k<32;k=k+1)
	begin
		scan_mem=$fscanf(data_mem,"%b\n",load_data[k]);
	end
		begin
			$display("writing to addresses 0 the values 256'b1111");
			addr_sram=start_addr+out*32;
			mem_intf_write_sw.mem_start_addr=addr_sram;
			mem_intf_write_sw.mem_size_bytes=6'd32;
			mem_intf_write_sw.mem_req=1'b1;
			mem_intf_write_sw.mem_data=data_8_bit[out*32+:32];
			for (integer index=0;index<32;index=index+1)
				$display("scan_mem[%d]: %h\n",index,data_8_bit[out*32+index]);
			wait (mem_intf_write_sw.mem_ack ==1'b1) @(negedge clk)
			addr_sram=mem_intf_write_sw.mem_start_addr;
			if (addr_sram[5]==0)
				odd=0;
			else
				odd=1;
			which_part= (addr_sram>>5)/2048;
			which_bank=which_part*2+odd;
			which_addr=((addr_sram)%(2048*32)-odd*32)/2;
			//check for fail
			if (acc_mem_wrap_tb.mannix_mem_farm_ins.debug_mem[which_bank][which_addr*8+:256]!=mem_intf_write_sw.mem_data)begin
				$display("TEST FAIL\ntime=%d loop=%d bank=%d, addr=%d \n expected:%h, actual:%h",
					$time,out,which_bank,which_addr,mem_intf_write_sw.mem_data,acc_mem_wrap_tb.mannix_mem_farm_ins.debug_mem[which_bank][which_addr*8+:256]);
			//	$finish();
			end
			else begin
				$display("check passed\ntime=%d loop=%d bank=%d, addr=%d \n expected:%h, actual:%h",
					$time,out,which_bank,which_addr,mem_intf_write_sw.mem_data,acc_mem_wrap_tb.mannix_mem_farm_ins.debug_mem[which_bank][which_addr*8+:256]);
			end
		//	$display("PASS");
		end
	end
			mem_intf_write_sw.mem_req=1'b0;
endtask //// MEM_LOAD

task MEM_READ(input reg [((X_COLS_NUM*X_ROWS_NUM)-1):0] [7:0] data_8_bit, input integer size, integer start_addr);
	data_mem = $fopen("../txt_files/data_bin.txt", "r");
	addr_sram=0;
	clk_enable = 1'b1;

		repeat (10) begin
			@ (posedge clk) ;
		end
	//for (integer out=0;out<(size/32)+((size%32)!=0);out=out+1) begin
	for (integer out=0;out<2;out=out+1) begin
	for (integer k=0;k<32;k=k+1)
	begin
		scan_mem=$fscanf(data_mem,"%b\n",load_data[k]);
	end
		begin
			$display("writing to addresses 0 the values 256'b1111");
			addr_sram=start_addr+out*32+1;
			pool_r.mem_start_addr=addr_sram;
			pool_r.mem_size_bytes=6'd32;
			pool_r.mem_req=1'b1;
			mem_intf_write_sw.mem_data=data_8_bit[out*32+:32];
			for (integer index=0;index<32;index=index+1)
				$display("scan_mem[%d]: %h\n",index,data_8_bit[out*32+index]);
			wait (pool_r.mem_valid ==1'b1) @(negedge clk)
			addr_sram=pool_r.mem_start_addr;
			if (addr_sram[5]==0)
				odd=0;
			else
				odd=1;
			which_part= (addr_sram>>5)/2048;
			which_bank=which_part*2+odd;
			which_addr=((addr_sram)%(2048*32)-odd*32)/2;
			//check for fail
			if (acc_mem_wrap_tb.mannix_mem_farm_ins.debug_mem[which_bank][which_addr*8+:256]!=pool_r.mem_data)begin
				$display("TEST FAIL\ntime=%d loop=%d bank=%d, addr=%d \n expected:%h, actual:%h",
					$time,out,which_bank,which_addr,pool_r.mem_data,acc_mem_wrap_tb.mannix_mem_farm_ins.debug_mem[which_bank][which_addr*8+:256]);
			//	$finish();
			end
			else begin
				$display("check passed\ntime=%d loop=%d bank=%d, addr=%d \n expected:%h, actual:%h",
					$time,out,which_bank,which_addr,pool_r.mem_data,acc_mem_wrap_tb.mannix_mem_farm_ins.debug_mem[which_bank][which_addr*8+:256]);
			end
		//	$display("PASS");
		end
	end
			pool_r.mem_req=1'b0;
endtask //// MEM_READ

integer j;


task MEM_PIC_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input [7:0] num_of_bytes );//input signed [7:0] data [0:3]);
	begin
		wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr==addr))
		@(posedge clk)
		for(integer jj=0;jj<num_of_bytes;jj++)
		begin
			mem_intf_read_pic_mem_data[jj]=a_data[jj];
		end

		mem_intf_read_pic_mem_last_valid=num_of_bytes-1'b1;

		mem_intf_read_pic_mem_gnt=1'b1;
		//@(posedge clk)
		//  mem_intf_read_pic_mem_gnt=1'b0;
	end
endtask // MEM_PIC_READ_REQ_FRST


reg [ADDR_WIDTH-1:0] addr4loop;
reg [ADDR_WIDTH-1:0] r;

task MEM_PIC_READ_REQ (input [ADDR_WIDTH-1:0] addr,input [7:0] num_of_bytes );// input signed [7:0] data [0:3]);
	begin
		wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr==addr))
		@(posedge clk)
		addr4loop='d0;
		for(j=0;j<num_of_bytes;j++)
		begin            
			mem_intf_read_pic_mem_data[j]=a_data[addr+j];
		end


		mem_intf_read_pic_mem_last_valid=num_of_bytes-1'b1;

		mem_intf_read_pic_mem_gnt=1'b1;

		repeat (1) begin
			@ (posedge clk) ;
		end

		mem_intf_read_pic_mem_gnt=1'b0;   
	end
endtask // MEM_PIC_READ_REQ


task MEM_WGT_READ_REQ (input [ADDR_WIDTH-1:0] addr, input signed [((Y_COLS_NUM*Y_ROWS_NUM)-1):0][7:0] data );
	begin
		wait ((mem_intf_read_wgt.mem_req==1'b1)&&(mem_intf_read_wgt.mem_start_addr=={ADDR_WIDTH{1'b0}}))  
		for(j=0;j<(Y_COLS_NUM*Y_ROWS_NUM);j++)
			mem_intf_read_wgt_mem_data[j]=data[j];

		mem_intf_read_wgt_mem_gnt=1'b1;

		repeat (1) begin
			@ (posedge clk) ;
		end
		//Need to verify if gnt de-asserted after 1 cycle or not
		mem_intf_read_pic_mem_gnt=1'b0; 
		mem_intf_read_wgt_mem_gnt=1'b0;

	end
endtask // MEM_WGT_READ_REQ

task MEM_BIAS_READ_REQ (input [ADDR_WIDTH-1:0] addr, input signed [31:0] data);
	begin
		wait ((mem_intf_read_bias.mem_req==1'b1)&&(mem_intf_read_bias.mem_start_addr=={ADDR_WIDTH{1'b0}}))
		mem_intf_read_bias_mem_data='d0;
		// mem_intf_read_bias_mem_data[3:0]=data;

		mem_intf_read_bias_mem_gnt=1'b1;

		repeat (2) begin
			@ (posedge clk) ;
		end
		//Need to verify if gnt de-asserted after 1 cycle or not
		mem_intf_read_bias_mem_gnt=1'b0; 

	end
endtask // MEM_WGT_READ_REQ




//reg [7:0] data;
//reg [7:0] index;
reg [ADDR_WIDTH-1:0] start_line_addr;
reg [31:0]           index_res;
integer              u;

task WINDOWS_IN_RAW(input [15:0] times , input [7:0] row_num);
	begin
		//  data=8'd6;
		if(row_num==8'd0)
		begin
			index=8'd1; 
		end
		else
		begin
			index=8'd0;
		end
		start_line_addr=row_num*X_COLS_NUM;
		repeat(times)
	begin
		index_res=(row_num*(X_ROWS_NUM-Y_ROWS_NUM+1))+index;

		//$monitor ("index: %d, Value res: %d , RTL val: %d \n",index_res,results[index_res],) ;
		for(u=0;u<Y_ROWS_NUM;u++)
		begin
			MEM_PIC_READ_REQ(start_line_addr+JUMP_ROW*index+sw_cnn_x_n*u,Y_ROWS_NUM);
		end

		// MEM_PIC_READ_REQ(start_line_addr+JUMP_ROW*index,4);
		// MEM_PIC_READ_REQ(start_line_addr+JUMP_ROW*index+sw_cnn_x_n,4);
		// MEM_PIC_READ_REQ(start_line_addr+JUMP_ROW*index+sw_cnn_x_n*2,4);
		// MEM_PIC_READ_REQ(start_line_addr+JUMP_ROW*index+sw_cnn_x_n*3,4);

		//  data=data+3'd4;
		index=index+1'b1;
		wait(data2write_out==results_real[index_res]);
		$display ("index: %d, Value res: %d , RTL val: %d \n",index_res,results[index_res],activation_out_smpl) ;
		if(results[index_res]==activation_out_smpl)
			$display("Yay");
		else
			$display("Boo");
		// $monitor ("index: %d equal, Value: %d",index ,results_real[(row_num*(8'd125))+(index-1'd1)]);
	end
end
  endtask




  task TEST_128X128_4X4();//input [ADDR_WIDTH-1:0] start_addr);
	  begin      
		  MEM_PIC_READ_REQ_FRST(sw_cnn_addr_x,Y_ROWS_NUM);
		  MEM_WGT_READ_REQ(sw_cnn_addr_y,w_data);
		  MEM_BIAS_READ_REQ(sw_cnn_addr_bias,avrg); 
		  //==============================================
		  MEM_PIC_READ_REQ(sw_cnn_x_n,Y_ROWS_NUM);
		  MEM_PIC_READ_REQ(sw_cnn_x_n*2,Y_ROWS_NUM);
		  MEM_PIC_READ_REQ(sw_cnn_x_n*3,Y_ROWS_NUM);
		  //MEM_PIC_READ_REQ(sw_cnn_x_n*4,Y_ROWS_NUM);
		  wait(data2write_out==results_real[0])
		  $monitor ("index: 0 equal, Value: %d",results_real[0]);

		  WINDOWS_IN_RAW(X_ROWS_NUM-Y_ROWS_NUM,calc_row);
		  calc_row=calc_row+1'b1;
		  $monitor("end %d row at %0t",calc_row,$time);

		  for(integer i=1;i<(X_ROWS_NUM-Y_ROWS_NUM+1);i++)
		  begin
			  WINDOWS_IN_RAW(X_ROWS_NUM-Y_ROWS_NUM+1,calc_row);
			  calc_row=calc_row+1'b1;
			  $monitor("end %d row at %0t",calc_row,$time);         
		  end

		  $display("done");

	  end
  endtask

  always @(posedge clk)
  begin
	  if(mem_intf_write.mem_req) //&& mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
	  begin
		  mem_intf_write_mem_gnt<=1'b1;
	  end                 
	  else
	  begin
		  mem_intf_write_mem_gnt<=1'b0;          
	  end
  end // always @ (posedge clk)

  //=============================================================================================================

  task FCC_RESET_VALUES();
	  begin


		  fcc_mem_intf_write_mem_ack=1'b0;

		  fcc_mem_intf_read_pic_mem_valid=1'b0;
		  fcc_mem_intf_read_pic_last=1'b0;
		  fcc_mem_intf_read_pic_mem_data='d0;
		  fcc_mem_intf_read_pic_mem_last_valid='d0; 

		  fcc_mem_intf_read_wgt_mem_valid=1'b0;
		  fcc_mem_intf_read_wgt_last=1'b0;
		  fcc_mem_intf_read_wgt_mem_data='d0;
		  fcc_mem_intf_read_wgt_mem_last_valid='d0; 

		  fcc_mem_intf_read_bias_mem_valid=1'b0;
		  fcc_mem_intf_read_bias_last=1'b0;
		  fcc_mem_intf_read_bias_mem_data='d0;
		  fcc_mem_intf_read_bias_mem_last_valid='d0;

		  fc_addrx={ADDR_WIDTH{1'b0}};		// FC Data window FIRST address
		  fc_addry={ADDR_WIDTH{1'b0}};		// FC  weighs FIRST address
		  fc_addrz={ADDR_WIDTH{1'b0}};		// FC bias address
		  fc_addrb={ADDR_WIDTH{1'b0}};		// FC return address

		  // fc_xm={X_LOG2_ROWS_NUM{1'b0}};  		// FC data matrix num of rows
		  // fc_ym={Y_LOG2_ROWS_NUM{1'b0}};	        // FC weight matrix num of rows
		  // fc_yn={Y_LOG2_COLS_NUM{1'b0}};	        // FC weight matrix num of columns
		  fc_xm='d128;  	// FC data matrix num of rows
		  fc_ym='d128;        // FC weight matrix num of rows
		  fc_yn='d128;        // FC weight matrix num of columns
		  fc_go = 1'b0;
		  cnn_bn = 'd128 ;


	  end
  endtask // ASYNC_RESET
  //-------------------------------------------------------------------------------------------
  //===================================================================
  //task MEM_PIC_READ_REQ_FRST
  //
  //	inputs:
  //		1) data - the data we want to give the pic at start
  //		2) addr - the start addr
  //===================================================================
  integer m ;
  task FCC_MEM_PIC_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input [7:0] data [0:31] );//[0:31]);
	  begin
		  wait ((fcc_mem_intf_read_pic.mem_req==1'b1))//&&(fcc_mem_intf_read_pic.mem_start_addr==addr))
		  @(posedge clk)
		  for(m=0;m<32;m=m+1) begin
			  fcc_mem_intf_read_pic_mem_data[m] = data[m] ; 
		  end        
		  fcc_mem_intf_read_pic_mem_last_valid=8'd31;

		  fcc_mem_intf_read_pic_mem_valid=1'b1;  
	  end

  endtask // MEM_PIC_READ_REQ_FRST
  //-------------------------------------------------------------------------------------------
  //===================================================================
  //task MEM_WGT_READ_REQ_FRST
  //
  //	inputs:
  //		1) data - the data we want to give the pic at start
  //		2) addr - the start addr
  //===================================================================
  integer l;
  task FCC_MEM_WGT_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input signed [7:0] data [0:31] );
	  begin
		  wait ((fcc_mem_intf_read_wgt.mem_req==1'b1))//&&(mem_intf_read_wgt.mem_start_addr==addr))
		  @(posedge clk)
		  for(l=0;l<32;l=l+1) begin
			  fcc_mem_intf_read_wgt_mem_data[l] = data[l] ; 
		  end   
		  //  mem_intf_read_wgt_mem_data = data ; 
		  fcc_mem_intf_read_wgt_mem_last_valid=8'd31;

		  fcc_mem_intf_read_wgt_mem_valid=1'b1;  
	  end

  endtask // MEM_PIC_READ_REQ_FRST
  //-------------------------------------------------------------------------------------------
  //===================================================================
  //task MEM_BIAS_READ_REQ
  //
  //	inputs:
  //		1) data - the data we want to give the pic at start
  //		2) addr - the start addr
  //
  //	Description:
  //		same as the last one but here we wait 2 clk cycles to 
  //		low gnt
  //===================================================================
  task FCC_MEM_BIAS_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [31:0] data);
	  begin
		  wait ((fcc_mem_intf_read_bias.mem_req==1'b1))//&&(mem_intf_read_bias.mem_start_addr==addr))
		  @(posedge clk)
		  //mem_intf_read_bias_mem_data ='d0;
		  fcc_mem_intf_read_bias_mem_data=data; 

		  fcc_mem_intf_read_bias_mem_last_valid=8'd31;

		  fcc_mem_intf_read_bias_mem_valid=1'b1;
		  repeat (2) begin
			  @ (posedge clk) ;
		  end
		  fcc_mem_intf_read_bias_mem_valid=1'b0;
	  end
  endtask // MEM_PIC_READ_REQ*/
 //-------------------------------------------------------------------------------------------
 //===========================================================================
 integer k;
 task FCC_READ_RESULT ();
	 begin
		 @(posedge clk) begin
			 for (k=0;k<128;k=k+1)begin
				 fcc_scan=$fscanf(fcc_res,"%d\n",fcc_result[k]);
			 end
		 end
	 end
 endtask

 //-------------------------------------------------------------------------------------------
 reg [ADDR_WIDTH-1:0] fcc_address;
 integer            i;//,j;
 integer p;
 task FCC_TEST_128X128();//input [ADDR_WIDTH-1:0] start_addr);
	 begin
		 p=0;
		 fc_go = 1'b1;
		 fcc_address = {ADDR_WIDTH{1'b0}};
		 repeat (FCC_X_ROWS_NUM) begin //128
			 p=p+1;
			 @(posedge clk) begin
				 fcc_scan=$fscanf(fcc_b,"%d\n",fcc_bias);
				 FCC_MEM_BIAS_READ_REQ(fcc_address,fcc_bias);
				 repeat(FCC_CNT_32_MAX) begin
					 for (j=0;j<32;j=j+1)begin
						 fcc_scan=$fscanf(fcc_dta,"%d\n",fcc_data[j]);
						 fcc_scan=$fscanf(fcc_wgt,"%d\n",fcc_weights[j]);

					 end


					 FCC_MEM_PIC_READ_REQ_FRST(fcc_address,fcc_data);

					 FCC_MEM_WGT_READ_REQ_FRST(fcc_address,fcc_weights);

					 #6.25
					 fcc_mem_intf_read_pic_mem_valid=1'b0; 
					 fcc_mem_intf_read_wgt_mem_valid=1'b0;
					 fcc_address = fcc_address + 19'd32;
					 i=i+32;
				 end	
			 end	 
		 end
		 $fclose(fcc_dta);
		 $fclose(fcc_wgt);
		 $fclose(fcc_b);
		 $fclose(fcc_res);
	 end
 endtask
 //===============================================================================================================
 always @(posedge clk)
 begin
	 if(fcc_mem_intf_write.mem_req) //&& mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
	 begin
		 fcc_mem_intf_write_mem_ack<=1'b1;
	 end                 
	 else
	 begin 
		 fcc_mem_intf_write_mem_ack<=1'b0;          
	 end
 end // always @ (posedge clk)



 endmodule






