//======================================================================================================
//
// Module: fcc_acc_tb
//
// Design Unit Owner : Dor Shilo 
//                    
// Original Author   : Dor Shilo and BIG credit to Nitzan
// Original Date     : 1-Jan-2020
//
//
//	latest changes :
//			added reading from bias, weights, weights and result txt files found in SW
//
//======================================================================================================


module acc_fcc_tb ();

  parameter DEPTH=32;
  parameter   CLK_PERIOD = 6.25; //80Mhz


  //parameter JUMP=1;
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
  parameter X_COLS_NUM=1;
                     
  parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  

  parameter Y_ROWS_NUM=128;
  parameter Y_COLS_NUM=128;
                     
  parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);
  

  reg         clk;
  reg         rst_n;
  reg         clk_config_tb;
  reg         clk_enable;

  
  //====================      
  // Software Interface
  //====================		
  reg [ADDR_WIDTH-1:0]            fc_addrx;		// FC Data window FIRST address
  reg [ADDR_WIDTH-1:0]            fc_addry;		// FC  weights window FIRST address
  reg [ADDR_WIDTH-1:0]            fc_addrz;		// FC return address
  reg [ADDR_WIDTH-1:0]	 	  fc_addrb;
  reg [X_LOG2_ROWS_NUM-1:0]       fc_xm;  		// FC data matrix num of *rows*
  reg [Y_LOG2_ROWS_NUM-1:0]       fc_ym;	      	// FC weight matrix num of *rows*
  reg [Y_LOG2_COLS_NUM-1:0]       fc_yn;	        // FC weight matrix num of *columns* 
  wire                            fc_sw_busy_ind;	// An output to the software - 1 – FC unit is busy FC is available (Default)
  reg 				fc_done;
  reg				fc_go;
  reg [X_LOG2_ROWS_NUM-1:0] 	cnn_bn;
  reg                         			   mem_intf_write_mem_ack;
  
  reg                             		   mem_intf_read_pic_mem_valid;
  reg                             		   mem_intf_read_pic_last;
  
  reg signed [31:0][7:0]               		   mem_intf_read_pic_mem_data;
  
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_pic_mem_last_valid ;
  
  reg                                              mem_intf_read_wgt_mem_valid;
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_wgt_last;
  reg signed [31:0][7:0]                           mem_intf_read_wgt_mem_data;
  reg                                              mem_intf_read_wgt_mem_last_valid;

  reg                                              mem_intf_read_bias_mem_valid;
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_bias_last;
  reg signed [31:0][7:0]                           mem_intf_read_bias_mem_data;
  reg                                              mem_intf_read_bias_mem_last_valid;
  

  reg signed [7:0] data [0:31] ;
  reg signed [7:0] weights [0:31];
  reg signed [16:0] bias ;
  reg signed [17:0] result [0:127];


  integer dta;
  integer wgt;
  integer b;
  integer res;
  integer scan;
always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;

  
  initial
    begin
      dta = $fopen("/project/tsmc65/users/shilodo1/mannix/software/fcc_mat_generator/data.txt", "r");
      wgt = $fopen("/project/tsmc65/users/shilodo1/mannix/software/fcc_mat_generator/weights.txt", "r");
      b   = $fopen("/project/tsmc65/users/shilodo1/mannix/software/fcc_mat_generator/bias.txt", "r");
      res = $fopen("/project/tsmc65/users/shilodo1/mannix/software/fcc_mat_generator/result.txt", "r");
	


      clk_enable = 1'b1;
      clk_config_tb   = 1'b0;
      RESET_VALUES();
      ASYNC_RESET();
	READ_RESULT();
//The task that start it all!
      TEST_128X128();
   
  
      $stop;
    end
  
  //Reading the data
  mem_intf_read mem_intf_read_pic();
   //assigning the Grant from memory to our's. 
  assign mem_intf_read_pic.mem_valid=mem_intf_read_pic_mem_valid;
  assign mem_intf_read_pic.last=mem_intf_read_pic_last;
  assign mem_intf_read_pic.mem_data=mem_intf_read_pic_mem_data;
  assign mem_intf_read_pic.mem_last_valid=mem_intf_read_pic_mem_last_valid;
  
  // mem_intf_read_pic.mem_req
  // mem_intf_read_pic.mem_start_addr
  // mem_intf_read_pic.mem_size_bytes   
                 
 
  //Reading the weights
  mem_intf_read mem_intf_read_wgt();
  
  assign mem_intf_read_wgt.mem_valid=mem_intf_read_wgt_mem_valid;
  assign mem_intf_read_wgt.last=mem_intf_read_wgt_last;
  assign mem_intf_read_wgt.mem_data=mem_intf_read_wgt_mem_data;
  assign mem_intf_read_wgt.mem_last_valid=mem_intf_read_wgt_mem_last_valid;
  
  // mem_intf_read_wgt.mem_req(),
  // mem_intf_read_wgt.mem_start_addr(),
  // mem_intf_read_wgt.mem_size_bytes() 
 
 //Reading the biases
  mem_intf_read mem_intf_read_bias();           
  assign mem_intf_read_bias.mem_valid=mem_intf_read_bias_mem_valid;
  assign mem_intf_read_bias.last=mem_intf_read_bias_last;
  assign mem_intf_read_bias.mem_data=mem_intf_read_bias_mem_data;
  assign mem_intf_read_bias.mem_last_valid=mem_intf_read_bias_mem_last_valid;


  mem_intf_write mem_intf_write();
                              assign mem_intf_write.mem_ack=mem_intf_write_mem_ack;
                 // //Outputs
	   	 // .mem_req(),
                 // .mem_start_addr(),
                 // .mem_size_bytes(),
                 // .last(),
                 // .mem_data(),
                 // .mem_last_valid()
                 // ); 
  

  
/*fcc #(

  .JUMP(JUMP),
 // .WORD_WIDTH(WORD_WIDTH),
 // .NUM_WORDS_IN_LINE(NUM_WORDS_IN_LINE),
  .ADDR_WIDTH(ADDR_WIDTH),
                       
  .MAX_BYTES_TO_RD(MAX_BYTES_TO_RD),
  .LOG2_MAX_BYTES_TO_RD(LOG2_MAX_BYTES_TO_RD),  
  .MAX_BYTES_TO_WR(MAX_BYTES_TO_WR),  
  .LOG2_MAX_BYTES_TO_WR(LOG2_MAX_BYTES_TO_WR),
  .MEM_DATA_BUS(MEM_DATA_BUS),

  .X_ROWS_NUM(X_ROWS_NUM),
  .X_COLS_NUM(X_COLS_NUM),
                     
  .X_LOG2_ROWS_NUM(X_LOG2_ROWS_NUM),
  .X_LOG2_COLS_NUM(X_LOG2_COLS_NUM), 
  

  .Y_ROWS_NUM(Y_ROWS_NUM),
  .Y_COLS_NUM(Y_COLS_NUM),
                     
  .Y_LOG2_ROWS_NUM(Y_LOG2_ROWS_NUM),
  .Y_LOG2_COLS_NUM(Y_LOG2_COLS_NUM)
*/
  fcc fcc_ins(
            .clk(clk),
            .rst_n(rst_n),

            .mem_intf_write(mem_intf_write),
            .mem_intf_read_pic(mem_intf_read_pic),
            .mem_intf_read_wgt(mem_intf_read_wgt),
	    .mem_intf_read_bias(mem_intf_read_bias),
            
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


   mem_intf_write_mem_ack=1'b0;
  
   mem_intf_read_pic_mem_valid=1'b0;
   mem_intf_read_pic_last=1'b0;
   mem_intf_read_pic_mem_data='d0;
   mem_intf_read_pic_mem_last_valid='d0; 
   
   mem_intf_read_wgt_mem_valid=1'b0;
   mem_intf_read_wgt_last=1'b0;
   mem_intf_read_wgt_mem_data='d0;
   mem_intf_read_wgt_mem_last_valid='d0; 
   
   mem_intf_read_bias_mem_valid=1'b0;
   mem_intf_read_bias_last=1'b0;
   mem_intf_read_bias_mem_data='d0;
   mem_intf_read_bias_mem_last_valid='d0;
		
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
//===================================================================
//task MEM_PIC_READ_REQ_FRST
//
//	inputs:
//		1) data - the data we want to give the pic at start
//		2) addr - the start addr
//===================================================================
integer m ;
  task MEM_PIC_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input signed [7:0] data [0:31] );//[0:31]);
  begin
    wait ((mem_intf_read_pic.mem_req==1'b1))//&&(mem_intf_read_pic.mem_start_addr==addr))
    @(posedge clk)
    for(m=0;m<32;m=m+1) begin
       mem_intf_read_pic_mem_data[m] = data[m] ; 
	end        
	mem_intf_read_pic_mem_last_valid=8'd31;
    
        mem_intf_read_pic_mem_valid=1'b1;  
  end

endtask // MEM_PIC_READ_REQ_FRST

//===================================================================
//task MEM_WGT_READ_REQ_FRST
//
//	inputs:
//		1) data - the data we want to give the pic at start
//		2) addr - the start addr
//===================================================================

  task MEM_WGT_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input signed [7:0] data [0:31] );
  begin
    wait ((mem_intf_read_wgt.mem_req==1'b1))//&&(mem_intf_read_wgt.mem_start_addr==addr))
      @(posedge clk)
    for(m=0;m<32;m=m+1) begin
       mem_intf_read_wgt_mem_data[m] = data[m] ; 
	end   
     //  mem_intf_read_wgt_mem_data = data ; 
        mem_intf_read_wgt_mem_last_valid=8'd31;
    
        mem_intf_read_wgt_mem_valid=1'b1;  
  end

endtask // MEM_PIC_READ_REQ_FRST

//===================================================================
//task MEM_PIC_READ_REQ
//
//	inputs:
//		1) data - the data we want to give the pic at start
//		2) addr - the start addr
//
//	Description:
//		same as the last one but here we wait 2 clk cycles to 
//		low gnt
//===================================================================
/*  task MEM_PIC_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
    begin
      wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr==addr))
        @(posedge clk)

      mem_intf_read_pic_mem_data[31:0]={32{data}}; 

      mem_intf_read_pic_mem_last_valid=8'd31;

      mem_intf_read_pic_mem_valid=1'b1;

      repeat (2) begin
        @ (posedge clk) ;
      end

      mem_intf_read_pic_mem_valid=1'b0;   
    end
  endtask // MEM_PIC_READ_REQ*/
  

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
 task MEM_BIAS_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [16:0] data);
    begin
      wait ((mem_intf_read_bias.mem_req==1'b1))//&&(mem_intf_read_bias.mem_start_addr==addr))
        @(posedge clk)

      mem_intf_read_bias_mem_data={data}; 

      mem_intf_read_bias_mem_last_valid=8'd31;

      mem_intf_read_bias_mem_valid=1'b1;
	repeat (2) begin
      @ (posedge clk) ;
    end
	mem_intf_read_bias_mem_valid=1'b0;
    end
  endtask // MEM_PIC_READ_REQ*/
//===========================================================================
integer k;
task READ_RESULT ();
 begin
	@(posedge clk) begin
		for (k=0;k<128;k=k+1)begin
		           scan=$fscanf(res,"%d\n",result[k]);
		 end
	  end
end
endtask
//===================================================================
//task MEM_WGT_READ_REQ
//
//	inputs:
//		1) data - the data we want to give the pic at start
//		2) addr - the start addr
//
//	Description:
//		same but for wgt
//===================================================================
/*  task MEM_WGT_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
  begin
    wait ((mem_intf_read_wgt.mem_req==1'b1)&&(mem_intf_read_wgt.mem_start_addr=={ADDR_WIDTH{1'b0}}))  
      mem_intf_read_wgt_mem_data[31:0]={32{data}};
      mem_intf_read_wgt_mem_valid = 1'b1;

    repeat (2) begin
      @ (posedge clk) ;
    end
//Need to verify if gnt de-asserted after 1 cycle or not
      mem_intf_read_pic_mem_valid=1'b0; 
      mem_intf_read_wgt_mem_valid=1'b0;
  end
  endtask // MEM_WGT_READ_REQ*/
//=================================================================================

reg [ADDR_WIDTH-1:0] address;
integer i,j;
///reg [255:0] data_tmp;
//reg [255:0] weights_tmp;
 
  task TEST_128X128();//input [ADDR_WIDTH-1:0] start_addr);
   begin
     fc_go = 1'b1;
     //i = 0;
     address = {ADDR_WIDTH{1'b0}};
repeat (128) begin //128
	@(posedge clk) begin
	i=0;
	scan=$fscanf(b,"%d\n",bias);
	MEM_BIAS_READ_REQ(address,bias);
repeat(4) begin
	for (j=0;j<32;j=j+1)begin
                   scan=$fscanf(dta,"%d\n",data[i+j]);
                   
		   scan=$fscanf(wgt,"%d\n",weights[i+j]);

	end

     //data_tmp ={data[i],data[i+1] ,data[i+2] ,data[i+3],data[i+4],data[i+5] ,data[i+6] ,data[i+7],data[i+8],data[i+9] ,data[i+10] ,data[i+11],data[i+12],data[i+13] ,data[i+14] ,data[i+15],data[i+16],data[i+17] ,data[i+18] ,data[i+19],data[i+20],data[i+21] ,data[i+22] ,data[i+23],data[i+24],data[i+25] ,data[i+26] ,data[i+27],data[i+28],data[i+29] ,data[i+30] ,data[i+31]};
    // MEM_PIC_READ_REQ_FRST(address,{data[i],data[i+1] ,data[i+2] ,data[i+3],data[i+4],data[i+5] ,data[i+6] ,data[i+7]});
     MEM_PIC_READ_REQ_FRST(address,data);
    // weights_tmp ={weights[i],weights[i+1] ,weights[i+2] ,weights[i+3],weights[i+4],weights[i+5] ,weights[i+6] ,weights[i+7],weights[i+8],weights[i+9] ,weights[i+10] ,weights[i+11],weights[i+12],weights[i+13] ,weights[i+14] ,weights[i+15],weights[i+16],weights[i+17] ,weights[i+18] ,weights[i+19],weights[i+20],weights[i+21] ,weights[i+22] ,weights[i+23],weights[i+24],weights[i+25] ,weights[i+26] ,weights[i+27],weights[i+28],weights[i+29] ,weights[i+30] ,weights[i+31]};
     MEM_WGT_READ_REQ_FRST(address,weights);
	#12.5
     mem_intf_read_pic_mem_valid=1'b0; 
     mem_intf_read_wgt_mem_valid=1'b0;
     address = address + 19'd32;
     i=i+32;
end
end
     //==================================================================================================================
    

	
end	 

end
$fclose(dta);
$fclose(wgt);
$fclose(b);
$fclose(res);
   endtask

    always @(posedge clk)
    begin
      if(mem_intf_write.mem_req) //&& mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
        begin
          mem_intf_write_mem_ack<=1'b1;
        end                 
      else
        begin 
          mem_intf_write_mem_ack<=1'b0;          
        end
    end
  endmodule
