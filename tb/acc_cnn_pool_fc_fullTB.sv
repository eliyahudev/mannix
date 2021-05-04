//======================================================================================================
//
// Module: acc_mem_wrap_tb
//
// Design Unit Owner :Nitzan Dabush, Dor Shilo
//                    
// Original Author   :Nitzan Dabush
// Original Date     : 22-jan-2020
//
//======================================================================================================

module acc_mem_wrap_tb ();


//******************************************* 28X28 data cnn+fc *******************************


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

parameter X_ROWS_NUM=31; //CNN
parameter X_COLS_NUM=31; //CNN

parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 


parameter Y_ROWS_NUM=5; //CNN filter
parameter Y_COLS_NUM=5; //CNN filter

parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);

parameter DP_DEPTH=Y_ROWS_NUM; //demand
//=================================================================================
//FCC parameters
parameter FCC_DP_DEPTH=32; 		 		// How many bytes DP every time.


parameter FCC_X_ROWS_NUM=625;			//Data: vector of (X_COLS_NUM , X_ROWS_NUM)
parameter FCC_X_COLS_NUM=1;

parameter FCC_X_LOG2_ROWS_NUM =$clog2(FCC_X_ROWS_NUM);
parameter FCC_X_LOG2_COLS_NUM =$clog2(FCC_X_COLS_NUM); 


parameter FCC_Y_ROWS_NUM=5;
parameter FCC_Y_COLS_NUM=625;



parameter FCC_Y_LOG2_ROWS_NUM =$clog2(FCC_Y_ROWS_NUM);
parameter FCC_Y_LOG2_COLS_NUM =$clog2(FCC_Y_COLS_NUM);

parameter FCC_CNT_32_MAX = FCC_X_ROWS_NUM/32 + 1'd1;

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
//=================================================================================
//POOL parameters
parameter POOL_X_ROWS_NUM=27;
parameter POOL_X_COLS_NUM=27;
				 
parameter POOL_Y_ROWS_NUM=3;
parameter POOL_Y_COLS_NUM=3;




//===============================================================================

reg         clk;
reg         rst_n;
reg         clk_config_tb;
reg         clk_enable;

reg [((X_COLS_NUM*X_ROWS_NUM)-1):0] [7:0]  a_data; 
//reg signed [7:0]  w_data [0:((Y_COLS_NUM*Y_ROWS_NUM)-1)];
reg signed [((Y_COLS_NUM*Y_ROWS_NUM)-1):0][7:0]  w_data; 
reg [3:0][7:0] bias_data;

reg [((FCC_X_ROWS_NUM*FCC_X_COLS_NUM)-1):0] [7:0]  fcc_a_data; 
reg signed [((FCC_Y_COLS_NUM*FCC_Y_ROWS_NUM)-1):0][7:0]  fcc_w_data; 
reg signed [((FCC_X_COLS_NUM*FCC_X_ROWS_NUM)-1):0][31:0]  fcc_bias_data; 
reg [7:0] fcc_results [0:FCC_X_ROWS_NUM-1];
reg signed [31:0] fcc_results_real [0:FCC_X_ROWS_NUM-1];

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
reg [15624:0] [7:0] results ;
reg signed [31:0] results_real [0:15624];



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
reg [ADDR_WIDTH-1:0]	 	fc_addrb;
reg [FCC_X_LOG2_ROWS_NUM-1:0]   fc_xm;  		// FC data matrix num of *rows*
reg [FCC_Y_LOG2_ROWS_NUM-1:0]   fc_ym;	      	// FC weight matrix num of *rows*
reg [FCC_Y_LOG2_COLS_NUM-1:0]   fc_yn;	        // FC weight matrix num of *columns* 
wire                            fc_sw_busy_ind;	// An output to the software - 1 – FC unit is busy FC is available (Default)
reg 				fc_done;		// Indicating FC finished
reg				fc_go;			// Indicating FC to start
reg [X_LOG2_ROWS_NUM-1:0] 	cnn_bn;
reg                         			   fcc_mem_intf_write_mem_ack;

reg                             		   fcc_mem_intf_read_pic_mem_valid;
reg                             		   fcc_mem_intf_read_pic_last;

reg [31:0][WORD_WIDTH - 1:0]  		   fcc_mem_intf_read_pic_mem_data;

reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] fcc_mem_intf_read_pic_mem_last_valid ;

reg                                              fcc_mem_intf_read_wgt_mem_valid;
reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] fcc_mem_intf_read_wgt_last;
reg signed [31:0][WORD_WIDTH - 1:0]              fcc_mem_intf_read_wgt_mem_data;
reg                                              fcc_mem_intf_read_wgt_mem_last_valid;

reg                                              fcc_mem_intf_read_bias_mem_valid;
reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] fcc_mem_intf_read_bias_last;
reg signed [31:0]	                          fcc_mem_intf_read_bias_mem_data;
reg                                              fcc_mem_intf_read_bias_mem_last_valid;


integer fcc_dta;
integer fcc_wgt;
integer fcc_b;
integer fcc_res;
integer fcc_scan;

//POOL signals
integer pool_res;
reg[(POOL_X_ROWS_NUM-POOL_Y_ROWS_NUM+1'd1)*(POOL_X_COLS_NUM-POOL_Y_COLS_NUM+1'd1) - 1:0] [7:0] pool_results ;	  	
// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==       
// pool Software Interface
// ==  ==  ==  ==  ==  ==  ==  ==  ==  == 		
		reg [ADDR_WIDTH-1:0]            sw_pool_addr_x;	//POOL Data matrix FIRST address
		reg [ADDR_WIDTH-1:0]            sw_pool_addr_z;	//POOL return address
		
		reg [X_LOG2_ROWS_NUM:0]    	sw_pool_x_m;  	//POOL data matrix num of rows
		reg [X_LOG2_COLS_NUM:0]    	sw_pool_x_n;	//POOL data matrix num of columns
		
		reg [Y_LOG2_ROWS_NUM:0]     	sw_pool_y_m;	//POOL filter size - rows
		reg [Y_LOG2_COLS_NUM:0]     	sw_pool_y_n;	//POOL filter size - columns 
		
		reg 				sw_pool_go; //SW indication to start calculation 
		wire				sw_pool_done;		//Design indication to SW that calculation is done.
		wire 				pool_sw_busy_ind;	//An output to the software: 1 if POOL unit is busy and 0 if POOL is available (Default)

		mem_intf_write 			mem_intf_write_pool();
		mem_intf_read 			mem_intf_read_pic_pool();

		//============mem=============

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

reg [31:0]           index_res;
//==============================================================================================
//   
always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;


int outfile;
integer count;
initial
begin
//--------------------------FILES----------------------------------------------------
	dta = $fopen("../cnn_fc_matrix_generator/data.txt", "r"); 			//CNN data
	wgt = $fopen("../cnn_fc_matrix_generator/weights.txt", "r");			//CNN weights
	res_real = $fopen("../cnn_fc_matrix_generator/results_real_cnn.txt", "r");	//CNN result real
	res = $fopen("../cnn_fc_matrix_generator/resultsCNN.txt", "r");			//CNN result

	//***************************************CNN*************************************
//	CNN gets 31X31 matrix -> 961 data vector ->matlab weights are filter size 5x5
//					and bias is 1 with value of 1
	fc_go =1'b0; 
	clk_enable = 1'b1;
	clk_config_tb   = 1'b0;
	cnn_go=1'b0;
	sw_pool_go=1'b0;
	sum_res_real=35'd0;
	avrg=32'd0;
	//----cnn : reading all files to arrays ------
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
		end
bias_data=32'd1;


$monitor("START CNN TEST\n");

RESET_VALUES();
ASYNC_RESET();
 $display("READ DATA\n");
	MEM_LOAD(a_data, X_ROWS_NUM*X_COLS_NUM, 0);
 $display("READ wgt\n");
	MEM_LOAD(w_data, Y_ROWS_NUM*Y_COLS_NUM, 65536); //2^16
 $display("READ BIAS\n");
	MEM_LOAD(bias_data, 4,131072);//2^17 or 1<<17
//***************************************POOL*************************************
//
//	POOL gets 27X27 matrix -> filter is 3x3 -> output is 25x25
//---------------------------------------------------------------------------------
$display("START POOL TEST\n");

//****************** 27x27 OVERWRITE simulation ************************
//pool_dta = $fopen("../cnn_fc_matrix_generator/resultsCNN.txt", "r"); --- ITS CNN RESULTS
pool_res = $fopen("../cnn_fc_matrix_generator/resultsPOOL.txt", "r");


//----pool : reading all files to arrays ------

 $display("READ DATA\n");
/*for (integer k=0;k<(POOL_X_ROWS_NUM*POOL_X_COLS_NUM);k=k+1)
	begin
		scan=$fscanf(dta,"%d\n",pool_a_data[k]);
	end*/
$display("READ POOL RESULTS\n");
for (integer r=0;r<((POOL_X_ROWS_NUM-POOL_Y_ROWS_NUM+1'd1)*(POOL_X_COLS_NUM-POOL_Y_COLS_NUM+1'd1));r=r+1)
	begin
		scan=$fscanf(pool_res,"%d\n",pool_results[r]);
	end
   $display("Done pool read\n");  
RESET_VALUES();
   



  MEM_LOAD(results, POOL_X_ROWS_NUM*POOL_X_COLS_NUM, 327680);//5*2^16
   $display("Finished data for pool");

//***************************************FCC*************************************
//
//	POOL retrives 25X25 matrix -> 625 data vector ->matlab weights 5x625
//					and bias is 5x1
//---------------------------------------------------------------------------------
$display("START FCC TEST\n");

	
	outfile = $fopen("../tb/FCresults_fullTB.log", "w");
 	if (!outfile) begin
		    $fdisplay(outfile,"Couldn't open file");
		    $finish();
	    end
//****************** 25x25 OVERWRITE simulation ************************
//fcc_dta = $fopen("../cnn_fc_matrix_generator/resultsPOOL.txt", "r"); its POOL RESULTS
fcc_wgt = $fopen("../cnn_fc_matrix_generator/weightsFC.txt", "r");
fcc_res = $fopen("../cnn_fc_matrix_generator/resultsFC.txt", "r");
fcc_b   = $fopen("../cnn_fc_matrix_generator/biasFC.txt", "r");

//----fcc : reading all files to arrays ------

 $display("READ DATA\n");
/*for (integer k=0;k<(FCC_X_ROWS_NUM*FCC_X_COLS_NUM);k=k+1)
	begin
		scan=$fscanf(fcc_dta,"%d\n",fcc_a_data[k]);
	end*/
$display("READ WGT\n");
for (integer s=0;s<(FCC_Y_ROWS_NUM*FCC_Y_COLS_NUM);s=s+1)
	begin
		scan=$fscanf(fcc_wgt,"%d\n",fcc_w_data[s]);
	end
$display("READ BIAS\n");
for (integer u=0;u<(FCC_X_ROWS_NUM*FCC_X_COLS_NUM);u=u+1)
	begin
		scan=$fscanf(fcc_b,"%d\n",fcc_bias_data[u]);
	end

for (integer r=0;r<(FCC_X_ROWS_NUM*FCC_X_COLS_NUM);r=r+1)
	begin
		scan=$fscanf(fcc_res,"%d\n",fcc_results[r]);

	end
   $display("Finished FCC values read\n");//ASYNC_RESET();  
   FCC_RESET_VALUES();
   



   FCC_MEM_LOAD(pool_results, FCC_X_ROWS_NUM*FCC_X_COLS_NUM, 196608);//6*2^15
   $display("Finished data - now wgt\n");
   FCC_MEM_LOAD(fcc_w_data, FCC_Y_ROWS_NUM*FCC_Y_COLS_NUM, 229376);//8*2^18
   $display("Finished wgt - now bias\n");	
   FCC_MEM_LOAD(fcc_bias_data,4*FCC_Y_ROWS_NUM*FCC_X_COLS_NUM, 262144);//9*2^16
   $display("Finished bias - now we start CNN\n");


   @(posedge clk)
  //CNNN
  /* $display("start cnn\n");//ASYNC_RESET();  
	#CLK_PERIOD
	#CLK_PERIOD
        cnn_go=1'b1;
	#CLK_PERIOD
	#CLK_PERIOD
	cnn_go=1'b0;
	
	//------------------------
	 wait(cnn_done);
	for (integer index=0;index<Y_ROWS_NUM*Y_COLS_NUM;index=index+1) begin
		if(address_read_debug(98304+index)==results[index])
			$display("ok in index %d, value is %d\n",index,results[index]);
		else
			$display("not ok in index %d, valueCNN is %d,valueMAT is\n",index,address_read_debug(98304+index),results[index]);
		end
	   $display("CNN has finished now FC\n");
	  #100*/
	//POOL
	/*$display("start pool\n");  
	#CLK_PERIOD
	#CLK_PERIOD
        sw_pool_go=1'b1;
	#CLK_PERIOD
	#CLK_PERIOD
	sw_pool_go=1'b0;
	wait(sw_pool_done)
	for (integer index=0;index<POOL_Y_ROWS_NUM*POOL_Y_COLS_NUM;index=index+1) begin
		if(address_read_debug(163840+index)==results[index])
			$display("ok in index %d, value is %d\n",index,pool_results[index]);
		else
			$display("not ok in index %d, valueCNN is %d,valueMAT is\n",index,address_read_debug(163840+index),results[index]);
	end	
	#100*/

	// FCC
	$display("FC start\n");
	#CLK_PERIOD
	#CLK_PERIOD
	 fc_go=1'b1;
	#CLK_PERIOD
	#CLK_PERIOD
	  fc_go=1'b0;

	   wait(fc_done);
	   #100;
	count=0;
	for (integer index=0;index<FCC_Y_ROWS_NUM;index=index+1) begin
		if(address_read_debug(294912+index)==fcc_results[index])
			$display("ok in index %d, value is %d\n",index,fcc_results[index]);
		else begin
			$display("not ok in index %d, valueFC is %d,valueMAT is\n",index,address_read_debug(294912+index),fcc_results[index]);
			count = count +1;		
		end	
	end	
	if(count == 0) begin
		   $fdisplay(outfile,"PASS");	
	end
	else begin
		   $fdisplay(outfile,"FAIL");
	end
        $fclose(outfile);	  
	$fclose(fcc_dta);
	$fclose(fcc_wgt);
	$fclose(fcc_b);
	$fclose(fcc_res); 	
	$stop;
end

   //---------------------------------------------

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
				.pool_r(mem_intf_read_pic_pool),
				.fcc_w(fcc_mem_intf_write),
				.cnn_w(mem_intf_write),
				.pool_w(mem_intf_write_pool),

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

	pool #(	
				.X_ROWS_NUM (POOL_X_ROWS_NUM),
				.X_COLS_NUM (POOL_X_COLS_NUM),
						

				.Y_ROWS_NUM (POOL_Y_ROWS_NUM),
				.Y_COLS_NUM (POOL_Y_COLS_NUM)


		      )pool_ins(
			    .clk(clk),
			    .rst_n(rst_n),

			    .mem_intf_write(mem_intf_write_pool),
			    .mem_intf_read_pic(mem_intf_read_pic_pool),
			    
			    .pool_sw_busy_ind(pool_sw_busy_ind),
			    .sw_pool_addr_x(sw_pool_addr_x),
			    .sw_pool_addr_z(sw_pool_addr_z),
			    .sw_pool_x_m(sw_pool_x_m),   
			    .sw_pool_x_n(sw_pool_x_n),
			    .sw_pool_y_m(sw_pool_y_m),
			    .sw_pool_y_n(sw_pool_y_n),
			       
			    .sw_pool_go(sw_pool_go),
			    .sw_pool_done(sw_pool_done),
			       //Debug
			    .data2write_out(data2write_out)   

			    );




integer data_mem,scan_mem;
integer addr_sram;
//**************************CNN + POOL MEM_LOAD***********************************8
task MEM_LOAD(input reg [((128*128)-1):0] [7:0] data_8_bit, input integer size, integer start_addr);
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
//=============================================================================================================
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
//=============================================================================================================
	function [7:0] address_read_debug (
        input [ADDR_WIDTH-1:0] addr
    );
        integer which_part, which_bank, which_addr;
		logic odd;
		logic [ADDR_WIDTH-1:0] addr_int;
		logic [255:0] full_line;
		addr_int=addr;
		addr_int[4:0]='0;
			if (addr[5]==0)
				odd=0;
			else
				odd=1;
			which_part= (addr_int>>5)/2048;
			which_bank=which_part*2+odd;
			which_addr=((addr_int)%(2048*32)-odd*32)/2;
			full_line=acc_mem_wrap_tb.mannix_mem_farm_ins.debug_mem[which_bank][which_addr*8+:256];
			address_read_debug=full_line[addr[4:0]*8+:8];
    endfunction
//**************************FCC MEM_LOAD***********************************
task FCC_MEM_LOAD(input reg [((128*128)-1):0] [7:0] data_8_bit, input integer size, integer start_addr);
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
				$display("scan_mem[%d]: %h\n",out*32+index,data_8_bit[out*32+index]);
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
//=============================================================================================================
task FCC_MEM_READ(input reg [((FCC_X_COLS_NUM*FCC_X_ROWS_NUM)-1):0] [7:0] data_8_bit, input integer size, integer start_addr);
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


		//sw_cnn_addr_bias={ADDR_WIDTH{1'b0}};  // CNN Bias value address
		sw_cnn_addr_x={ADDR_WIDTH{1'b0}};	// CNN Data window FIRST address
		sw_cnn_addr_y='d32768;			// CNN  weights window FIRST address - 2^15 		
		sw_cnn_addr_bias='d65536; 		// CNN Bias value address 		
		sw_cnn_addr_z='d98304;			//3*2^16==196608 CNN return address
		sw_cnn_x_m=X_ROWS_NUM;  	        // CNN data matrix num of rows
		sw_cnn_x_n=X_COLS_NUM;	        	// CNN data matrix num of columns
		sw_cnn_y_m=Y_ROWS_NUM;	        	// CNN weight matrix num of rows
		sw_cnn_y_n=Y_COLS_NUM;	        	// CNN weight matrix num of columns

		sw_pool_addr_x='d131072;		// POOL Data window FIRST address
		sw_pool_addr_z='d163840;		// POOL return address
		sw_pool_x_m=POOL_X_ROWS_NUM;  	        // POOL data matrix num of rows
		sw_pool_x_n=POOL_X_COLS_NUM;	       		// POOL data matrix num of columns
		sw_pool_y_m=POOL_Y_ROWS_NUM;	        	// POOL weight matrix num of rows
		sw_pool_y_n=POOL_Y_COLS_NUM;	        	// POOL weight matrix num of columns


	end
endtask // ASYNC_RESET


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

		// ******* Test addresses *******				*/
		  fc_addrx='d196608;		// FC Data window FIRST address
		  fc_addry='d229376;		// FC  weighs FIRST address
		  fc_addrb='d262144;		// FC bias address
		  fc_addrz='d294912;
		
		  fc_xm=FCC_X_ROWS_NUM;	  		// FC data matrix num of rows
		  fc_ym=FCC_Y_ROWS_NUM;       		// FC weight matrix num of rows
		  fc_yn=FCC_Y_COLS_NUM;        		// FC weight matrix num of columns
		  fc_go = 1'b0;
		  cnn_bn = 'd128 ;

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

	  end
  endtask // ASYNC_RESET

endmodule

