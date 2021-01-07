//======================================================================================================
//
// Module: fcc_acc_tb
//
// Design Unit Owner : Dor Shilo 
//                    
// Original Author   : Dor Shilo and BIG credit to Nitzan
// Original Date     : 1-Jan-2020
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
  
  reg [31:0][7:0]                 		   mem_intf_read_pic_mem_data;
  
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_pic_mem_last_valid ;
  
  reg                                              mem_intf_read_wgt_mem_valid;
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_wgt_last;
  reg [31:0][7:0]                                  mem_intf_read_wgt_mem_data;
  reg                                              mem_intf_read_wgt_mem_last_valid;

  reg                                              mem_intf_read_bias_mem_valid;
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_bias_last;
  reg [31:0][7:0]                                  mem_intf_read_bias_mem_data;
  reg                                              mem_intf_read_bias_mem_last_valid;
  
always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;

  
  initial
    begin
      clk_enable = 1'b1;
      clk_config_tb   = 1'b0;
      RESET_VALUES();
      ASYNC_RESET();
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

  task MEM_PIC_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
  begin
    wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr==addr))
      @(posedge clk)
       mem_intf_read_pic_mem_data[31:0]={32{data}}; 
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

  task MEM_WGT_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
  begin
    wait ((mem_intf_read_wgt.mem_req==1'b1)&&(mem_intf_read_wgt.mem_start_addr==addr))
      @(posedge clk)
       mem_intf_read_wgt_mem_data[31:0]={32{data}}; 
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
  task MEM_PIC_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
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
  endtask // MEM_PIC_READ_REQ
  

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
  task MEM_BIAS_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
    begin
      wait ((mem_intf_read_bias.mem_req==1'b1))//&&(mem_intf_read_bias.mem_start_addr==addr))
        @(posedge clk)

      mem_intf_read_bias_mem_data[0]={32{data}}; 

      mem_intf_read_bias_mem_last_valid=8'd31;

      mem_intf_read_bias_mem_valid=1'b1;
	repeat (2) begin
      @ (posedge clk) ;
    end
	mem_intf_read_bias_mem_valid=1'b0;
//      mem_intf_read_bias_mem_valid=1'b0;   
    end
  endtask // MEM_PIC_READ_REQ
  
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
  task MEM_WGT_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
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
  endtask // MEM_WGT_READ_REQ
//===================================================================
//task FC_ACTION
//
//	inputs:
//		1) times - the data gets 4 bytes at a time from a 128x128 bytes matrix.
//		    	   
//
//	Description:
//		same as the last one but here we wait 2 clk cycles to 
//		low gnt
//===================================================================
  reg [7:0] data;
  reg [7:0] index;
  
  task FC_ACTION(input [15:0] times);
    begin
      data=8'd6;
      index=8'd1;
      repeat(times)
        begin
          if(mem_intf_write.mem_req) //&& mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
          mem_intf_write_mem_ack=1'b1;
          else
          mem_intf_write_mem_ack=1'b0;
          
          MEM_PIC_READ_REQ(index,data);
          MEM_PIC_READ_REQ(index+1'b1,data+1'b1);
          MEM_PIC_READ_REQ(index+2'b10,data+2'b10);
          MEM_PIC_READ_REQ(index+2'b11,data+2'b11);
          data=data+3'd4;
          index=index+3'd4;
          // if(mem_intf_write.mem_req) //&& mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
          // mem_intf_write_mem_ack=1'b1;
          // else
          // mem_intf_write_mem_ack=1'b0; 
        end
    end
  endtask

reg [ADDR_WIDTH-1:0] address;
  
  task TEST_128X128();//input [ADDR_WIDTH-1:0] start_addr);
   begin
     fc_go = 1'b1;
     address = {ADDR_WIDTH{1'b0}};
repeat (128) begin 
repeat(4) begin
     MEM_PIC_READ_REQ_FRST(address,8'd2);
     MEM_WGT_READ_REQ_FRST(address,8'd3);
     MEM_BIAS_READ_REQ(address,8'd9);
     mem_intf_read_pic_mem_valid=1'b0; 
     mem_intf_read_wgt_mem_valid=1'b0;
     address = address + 19'd32;
     //==============================================
    
//wait(mem_intf_write_mem_ack);
//#5
//    mem_intf_write_mem_ack = 1'b0;
end
end   
 //MEM_PIC_READ_REQ_FRST(8'd128,8'd4);
     // MEM_WGT_READ_REQ_FRST(8'd128,8'd6);
      //MEM_PIC_READ_REQ(fc_xm+2,8'd5);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP,8'd6);
     // MEM_PIC_READ_REQ(JUMP+fc_x_n,8'd7);
     // MEM_PIC_READ_REQ(JUMP+fc_x_n*2,8'd8);
     // MEM_PIC_READ_REQ(JUMP+fc_x_n*3,8'd9);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*2,8'd10);
     // MEM_PIC_READ_REQ(JUMP*2+fc_x_n,8'd11);
     // MEM_PIC_READ_REQ(JUMP*2+fc_x_n*2,8'd12);
     // MEM_PIC_READ_REQ(JUMP*2+fc_x_n*3,8'd13);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*3,8'd14);
     // MEM_PIC_READ_REQ(JUMP*3+fc_x_n,8'd15);
     // MEM_PIC_READ_REQ(JUMP*3+fc_x_n*2,8'd16);
     // MEM_PIC_READ_REQ(JUMP*3+fc_x_n*3,8'd17);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*4,8'd18);
     // MEM_PIC_READ_REQ(JUMP*4+fc_x_n,8'd19);
     // MEM_PIC_READ_REQ(JUMP*4+fc_x_n*2,8'd20);
     // MEM_PIC_READ_REQ(JUMP*4+fc_x_n*3,8'd21);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*5,8'd22);
     // MEM_PIC_READ_REQ(JUMP*5+fc_x_n,8'd23);
     // MEM_PIC_READ_REQ(JUMP*5+fc_x_n*2,8'd24);
     // MEM_PIC_READ_REQ(JUMP*5+fc_x_n*3,8'd25);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*6,8'd26);
     // MEM_PIC_READ_REQ(JUMP*6+fc_x_n,8'd27);
     // MEM_PIC_READ_REQ(JUMP*6+fc_x_n*2,8'd28);
     // MEM_PIC_READ_REQ(JUMP*6+fc_x_n*3,8'd29);
     // //==============================================
   //  FC_ACTION(32);



   
//    wait(mem_intf_write.mem_req && mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
//      mem_intf_write_mem_ack=1'b1;
//    $display("done");
    
// end
	end
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
