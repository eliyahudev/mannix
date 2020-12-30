//======================================================================================================
//
// Module: dot_product
//
// Design Unit Owner : Dor Shilo & Nitzan Dabush
//                    
// Original Author   : Dor Shilo & Nitzan Dabush
// Original Date     : 22-Nov-2020
//
//======================================================================================================


module acc_cnn_tb ();

  parameter DEPTH=4;

  parameter   CLK_PERIOD = 6.25; //80Mhz


  parameter JUMP=1;
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
  

  reg         clk;
  reg         rst_n;
  reg         clk_config_tb;
  reg         clk_enable;

  
  //====================      
  // Software Interface
  //====================		
  reg [ADDR_WIDTH-1:0]            sw_cnn_addr_x;	// CNN Data window FIRST address
  reg [ADDR_WIDTH-1:0]            sw_cnn_addr_y;	// CNN  weights window FIRST address
  reg [ADDR_WIDTH-1:0]            sw_cnn_addr_z;	// CNN return address
  reg [X_LOG2_ROWS_NUM:0]       sw_cnn_x_m;  	// CNN data matrix num of rows
  reg [X_LOG2_COLS_NUM:0]       sw_cnn_x_n;	        // CNN data matrix num of columns
  reg [Y_LOG2_ROWS_NUM:0]       sw_cnn_y_m;	        // CNN weight matrix num of rows
  reg [Y_LOG2_COLS_NUM:0]       sw_cnn_y_n;	        // CNN weight matrix num of columns 
  wire                            cnn_sw_busy_ind;	// An output to the software - 1 – CNN unit is busy CNN is available (Default)

  reg                             mem_intf_write_mem_gnt;
  
  reg                             mem_intf_read_pic_mem_gnt;
  reg                             mem_intf_read_pic_last;
  
  reg [31:0][7:0]                 mem_intf_read_pic_mem_data;
  
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_pic_mem_last_valid ;
  
  reg                                              mem_intf_read_wgt_mem_gnt;
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_wgt_last;
  reg [31:0][7:0]                                  mem_intf_read_wgt_mem_data;
  reg                                              mem_intf_read_wgt_mem_last_valid;
  
always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;

  
  initial
    begin
      clk_enable = 1'b1;
      clk_config_tb   = 1'b0;
      RESET_VALUES();
      ASYNC_RESET();
      TEST_32X32_4X4();
      // wait (mem_intf_read_pic.mem_req==1'b1)
      // @(posedge clk)
      //  mem_intf_read_pic_mem_data[3:0]={8'd2,8'd2,8'd2,8'd2}; 
      //  mem_intf_read_pic_mem_data[7:4]={8'd3,8'd3,8'd3,8'd3};
      //  mem_intf_read_pic_mem_data[11:8]={8'd4,8'd4,8'd4,8'd4};
      //  mem_intf_read_pic_mem_data[15:12]={8'd5,8'd5,8'd5,8'd5};
      //  mem_intf_read_pic_mem_data[19:16]={8'd6,8'd6,8'd6,8'd6}; 
      //  mem_intf_read_pic_mem_data[23:20]={8'd7,8'd7,8'd7,8'd7};
      //  mem_intf_read_pic_mem_data[27:24]={8'd8,8'd8,8'd8,8'd8};
      //  mem_intf_read_pic_mem_data[31:28]={8'd9,8'd9,8'd9,8'd9};
      
      //  mem_intf_read_pic_mem_gnt=1'b1;
       
      //  mem_intf_read_wgt_mem_data={8'd2,8'd2,8'd2,8'd2};  
      //  mem_intf_read_wgt_mem_gnt=1'b1;

      //  // mem_intf_read_pic_mem_data={8'd2,8'd2,8'd2,8'd2};  
       
      //  // mem_intf_read_wgt_mem_data={8'd2,8'd2,8'd2,8'd2};  
       
      // wait(mem_intf_write.mem_req)
      //  mem_intf_write_mem_gnt=1'b1;
      //   $display("done");
      // #12.5;
      //  mem_intf_read_pic_mem_data[3:0]={8'd10,8'd10,8'd10,8'd10}; 
      //  mem_intf_read_pic_mem_data[7:4]={8'd11,8'd11,8'd11,8'd11};
      //  mem_intf_read_pic_mem_data[11:8]={8'd12,8'd12,8'd12,8'd12};
      //  mem_intf_read_pic_mem_data[15:12]={8'd13,8'd13,8'd13,8'd13};
      //  mem_intf_read_pic_mem_data[19:16]={8'd14,8'd14,8'd14,8'd14}; 
      //  mem_intf_read_pic_mem_data[23:20]={8'd15,8'd15,8'd15,8'd15};
      //  mem_intf_read_pic_mem_data[27:24]={8'd16,8'd16,8'd16,8'd16};
      //  mem_intf_read_pic_mem_data[31:28]={8'd17,8'd17,8'd17,8'd17};
      
      //  wait (mem_intf_read_pic.mem_req==1'b1)
      // @(posedge clk)

 
      //  //mem_intf_read_pic_mem_data={8'd3,8'd3,8'd3,8'd3};  
      //  mem_intf_read_pic_mem_gnt=1'b1;
      //  mem_intf_read_pic_mem_data[1]={8'd3,8'd3,8'd3,8'd3}; 
      //  mem_intf_read_wgt_mem_data={8'd3,8'd3,8'd3,8'd3};  
      //  mem_intf_read_wgt_mem_gnt=1'b1;
 
       
      // wait(mem_intf_write.mem_req && mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
      //  mem_intf_write_mem_gnt=1'b1;
      //   $display("done");
  
      $stop;
    end
  
  
  mem_intf_read mem_intf_read_pic();
    
  assign mem_intf_read_pic.mem_gnt=mem_intf_read_pic_mem_gnt;
  assign mem_intf_read_pic.last=mem_intf_read_pic_last;
  assign mem_intf_read_pic.mem_data=mem_intf_read_pic_mem_data;
  assign mem_intf_read_pic.mem_last_valid=mem_intf_read_pic_mem_last_valid;
  
  // mem_intf_read_pic.mem_req
  // mem_intf_read_pic.mem_start_addr
  // mem_intf_read_pic.mem_size_bytes   
                 
 

  mem_intf_read mem_intf_read_wgt();
  
  assign mem_intf_read_wgt.mem_gnt=mem_intf_read_wgt_mem_gnt;
  assign mem_intf_read_wgt.last=mem_intf_read_wgt_last;
  assign mem_intf_read_wgt.mem_data=mem_intf_read_wgt_mem_data;
  assign mem_intf_read_wgt.mem_last_valid=mem_intf_read_wgt_mem_last_valid;
  
  // mem_intf_read_wgt.mem_req(),
  // mem_intf_read_wgt.mem_start_addr(),
  // mem_intf_read_wgt.mem_size_bytes() 
                    



  mem_intf_write mem_intf_write();
                              assign mem_intf_write.mem_gnt=mem_intf_write_mem_gnt;
                 // //Outputs
	   	 // .mem_req(),
                 // .mem_start_addr(),
                 // .mem_size_bytes(),
                 // .last(),
                 // .mem_data(),
                 // .mem_last_valid()
                 // ); 
  

  
cnn cnn_ins(
            .clk(clk),
            .rst_n(rst_n),

            .mem_intf_write(mem_intf_write),
            .mem_intf_read_pic(mem_intf_read_pic),
            .mem_intf_read_wgt(mem_intf_read_wgt),
            
            .cnn_sw_busy_ind(cnn_sw_busy_ind),
            .sw_cnn_addr_x(sw_cnn_addr_x),
            .sw_cnn_addr_y(sw_cnn_addr_y),
            .sw_cnn_addr_z(sw_cnn_addr_z),
            .sw_cnn_x_m(sw_cnn_x_m),   
            .sw_cnn_x_n(sw_cnn_x_n),
            .sw_cnn_y_m(sw_cnn_y_m),
            .sw_cnn_y_n(sw_cnn_y_n)

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


   mem_intf_write_mem_gnt=1'b0;
  
   mem_intf_read_pic_mem_gnt=1'b0;
   mem_intf_read_pic_last=1'b0;
   mem_intf_read_pic_mem_data='d0;
   mem_intf_read_pic_mem_last_valid='d0; 
   
   mem_intf_read_wgt_mem_gnt=1'b0;
   mem_intf_read_wgt_last=1'b0;
   mem_intf_read_wgt_mem_data='d0;
   mem_intf_read_wgt_mem_last_valid='d0; 
   
  
		
     sw_cnn_addr_x={ADDR_WIDTH{1'b0}};	// CNN Data window FIRST address
     sw_cnn_addr_y={ADDR_WIDTH{1'b0}};	// CNN  weights window FIRST address
     sw_cnn_addr_z={ADDR_WIDTH{1'b0}};	// CNN return address
    // sw_cnn_x_m={X_LOG2_ROWS_NUM{1'b0}};  	// CNN data matrix num of rows
    // sw_cnn_x_n={X_LOG2_COLS_NUM{1'b0}};	        // CNN data matrix num of columns
    // sw_cnn_y_m={Y_LOG2_ROWS_NUM{1'b0}};	        // CNN weight matrix num of rows
    // sw_cnn_y_n={Y_LOG2_COLS_NUM{1'b0}};	        // CNN weight matrix num of columns
    sw_cnn_x_m='d32;  	// CNN data matrix num of rows
    sw_cnn_x_n='d32;	        // CNN data matrix num of columns
    sw_cnn_y_m='d4;	        // CNN weight matrix num of rows
    sw_cnn_y_n='d4;	        // CNN weight matrix num of columns
    
   
      
    end
  endtask // ASYNC_RESET

  

  // task CREATE_MATRIX_SQUARE (input [7:0] size_d,input [7:0] size_w);
  //     begin                       
  //     int i,j;
  //     reg [7:0] count_mx_d;
  //     reg [7:0] count_mx_w;
      
  //     count_mx_d=8'd0;
  //     for(i=0;i<(size_d*size_d);i++)
  //       begin
  //         matrix_data_pre[i]=count_mx_d;
  //         count_mx_d=count_mx_d+1;
  //                    end
      

  //     count_mx_w=8'd0;
  //     for(j=0;j<(size_w*size_w);j++)
  //       begin
  //         matrix_weight_pre[j]=count_mx_w;
  //         count_mx_w=count_mx_w+1;
  //       end
      
  //   end
  //   endtask

 task TEST_32X32_4X4();
  begin
    wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr=={ADDR_WIDTH{1'b0}}))
      @(posedge clk)
        mem_intf_read_pic_mem_data[3:0]={8'd2,8'd2,8'd2,8'd2}; 
    // mem_intf_read_pic_mem_data[7:4]={8'd3,8'd3,8'd3,8'd3};
    // mem_intf_read_pic_mem_data[11:8]={8'd4,8'd4,8'd4,8'd4};
    // mem_intf_read_pic_mem_data[15:12]={8'd5,8'd5,8'd5,8'd5};
    mem_intf_read_pic_mem_last_valid=5'd15;
    
    mem_intf_read_pic_mem_gnt=1'b1;

    wait ((mem_intf_read_wgt.mem_req==1'b1)&&(mem_intf_read_wgt.mem_start_addr=={ADDR_WIDTH{1'b0}}))  
      mem_intf_read_wgt_mem_data[3:0]={8'd2,8'd2,8'd2,8'd2};
    // mem_intf_read_wgt_mem_data[7:4]={8'd2,8'd2,8'd2,8'd2};
    // mem_intf_read_wgt_mem_data[11:8]={8'd2,8'd2,8'd2,8'd2};
    // mem_intf_read_wgt_mem_data[15:12]={8'd2,8'd2,8'd2,8'd2};
    mem_intf_read_wgt_mem_gnt=1'b1;

    repeat (2) begin
    @ (posedge clk) ;
   end

    mem_intf_read_pic_mem_gnt=1'b0; 
    mem_intf_read_wgt_mem_gnt=1'b0; 
    // wait(mem_intf_write.mem_req)
    //  mem_intf_write_mem_gnt=1'b1;
    //   $display("done");
    
    wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr=={ADDR_WIDTH{1'b0}}+sw_cnn_x_n))
      @(posedge clk)
    
        //#12.5;
       mem_intf_read_pic_mem_data[3:0]={8'd3,8'd3,8'd3,8'd3}; 
    //    mem_intf_read_pic_mem_data[3:0]={8'd10,8'd10,8'd10,8'd10}; 
    // mem_intf_read_pic_mem_data[7:4]={8'd11,8'd11,8'd11,8'd11};
    // mem_intf_read_pic_mem_data[11:8]={8'd12,8'd12,8'd12,8'd12};
    // mem_intf_read_pic_mem_data[15:12]={8'd13,8'd13,8'd13,8'd13};
    // mem_intf_read_pic_mem_data[19:16]={8'd14,8'd14,8'd14,8'd14}; 
    // mem_intf_read_pic_mem_data[23:20]={8'd15,8'd15,8'd15,8'd15};
    // mem_intf_read_pic_mem_data[27:24]={8'd16,8'd16,8'd16,8'd16};
    // mem_intf_read_pic_mem_data[31:28]={8'd17,8'd17,8'd17,8'd17};
    mem_intf_read_pic_mem_last_valid=3'd4;

    mem_intf_read_pic_mem_gnt=1'b1;

   repeat (2) begin
    @ (posedge clk) ;
   end

      mem_intf_read_pic_mem_gnt=1'b0; 
    
    // wait(mem_intf_write.mem_req)
    //     mem_intf_write_mem_gnt=1'b1;
    //      $display("done");

    wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr=={ADDR_WIDTH{1'b0}}+sw_cnn_x_n*2))
      @(posedge clk)
    //     mem_intf_read_pic_mem_data[3:0]={8'd2,8'd2,8'd2,8'd2}; 
    // mem_intf_read_pic_mem_data[7:4]={8'd3,8'd3,8'd3,8'd3};
    mem_intf_read_pic_mem_data[3:0]={8'd4,8'd4,8'd4,8'd4};
    // mem_intf_read_pic_mem_data[15:12]={8'd5,8'd5,8'd5,8'd5};
    // mem_intf_read_pic_mem_last_valid=5'd15;
    
    mem_intf_read_pic_mem_gnt=1'b1;

     repeat (2) begin
    @ (posedge clk) ;
   end

      mem_intf_read_pic_mem_gnt=1'b0; 

    // wait(mem_intf_write.mem_req)
    //    mem_intf_write_mem_gnt=1'b1;
    //     $display("done");
    
    wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr=={ADDR_WIDTH{1'b0}}+sw_cnn_x_n*3))
      @(posedge clk)   
    //     mem_intf_read_pic_mem_data[3:0]={8'd10,8'd10,8'd10,8'd10}; 
    // mem_intf_read_pic_mem_data[7:4]={8'd11,8'd11,8'd11,8'd11};
    // mem_intf_read_pic_mem_data[11:8]={8'd12,8'd12,8'd12,8'd12};
    // mem_intf_read_pic_mem_data[15:12]={8'd13,8'd13,8'd13,8'd13};
    mem_intf_read_pic_mem_data[3:0]={8'd5,8'd5,8'd5,8'd5};
    //mem_intf_read_pic_mem_last_valid=5'd15;
    mem_intf_read_pic_mem_gnt=1'b1;
  repeat (2) begin
    @ (posedge clk) ;
   end
    
      mem_intf_read_pic_mem_gnt=1'b0; 
    
    wait(mem_intf_write.mem_req && mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
      mem_intf_write_mem_gnt=1'b1;
    $display("done");
    
  end
   endtask
  

  endmodule

