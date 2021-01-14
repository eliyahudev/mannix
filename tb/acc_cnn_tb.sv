//======================================================================================================
//
// Module: acc_cnn_tb
//
// Design Unit Owner : Nitzan Dabush
//                    
// Original Author   : Nitzan Dabush
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

  reg [7:0] calc_row;
  
  
always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;

  
  initial
    begin
      clk_enable = 1'b1;
      clk_config_tb   = 1'b0;
      RESET_VALUES();
      ASYNC_RESET();
      TEST_128X128_4X4();
      $stop;
    end
  
  
  mem_intf_read mem_intf_read_pic();
    
  assign mem_intf_read_pic.mem_gnt=mem_intf_read_pic_mem_gnt;
  assign mem_intf_read_pic.last=mem_intf_read_pic_last;
  assign mem_intf_read_pic.mem_data=mem_intf_read_pic_mem_data;
  assign mem_intf_read_pic.mem_last_valid=mem_intf_read_pic_mem_last_valid;
   

  mem_intf_read mem_intf_read_wgt();
  
  assign mem_intf_read_wgt.mem_gnt=mem_intf_read_wgt_mem_gnt;
  assign mem_intf_read_wgt.last=mem_intf_read_wgt_last;
  assign mem_intf_read_wgt.mem_data=mem_intf_read_wgt_mem_data;
  assign mem_intf_read_wgt.mem_last_valid=mem_intf_read_wgt_mem_last_valid;
  

  mem_intf_write mem_intf_write();
                              assign mem_intf_write.mem_gnt=mem_intf_write_mem_gnt;  

  
cnn #(

  .JUMP(JUMP),
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

      )cnn_ins(
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

    calc_row <=8'd0;
    
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
    sw_cnn_x_m='d128;  	// CNN data matrix num of rows
    sw_cnn_x_n='d128;	        // CNN data matrix num of columns
    sw_cnn_y_m='d4;	        // CNN weight matrix num of rows
    sw_cnn_y_n='d4;	        // CNN weight matrix num of columns
    
   
      
    end
  endtask // ASYNC_RESET


  task MEM_PIC_READ_REQ_FRST (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
  begin
    wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr==addr))
      @(posedge clk)
        mem_intf_read_pic_mem_data[3:0]={data,data,data,data}; 
        mem_intf_read_pic_mem_last_valid=3'd3;
    
        mem_intf_read_pic_mem_gnt=1'b1;  
  end
endtask // MEM_PIC_READ_REQ_FRST

  task MEM_PIC_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
    begin
      wait ((mem_intf_read_pic.mem_req==1'b1)&&(mem_intf_read_pic.mem_start_addr==addr))
        @(posedge clk)

      mem_intf_read_pic_mem_data[3:0]={data,data,data,data}; 

      mem_intf_read_pic_mem_last_valid=3'd3;

      mem_intf_read_pic_mem_gnt=1'b1;

      repeat (2) begin
        @ (posedge clk) ;
      end

      mem_intf_read_pic_mem_gnt=1'b0;   
    end
  endtask // MEM_PIC_READ_REQ
  

  task MEM_WGT_READ_REQ (input [ADDR_WIDTH-1:0] addr, input [7:0] data);
  begin
    wait ((mem_intf_read_wgt.mem_req==1'b1)&&(mem_intf_read_wgt.mem_start_addr=={ADDR_WIDTH{1'b0}}))  
      mem_intf_read_wgt_mem_data[3:0]={data,data,data,data};
      mem_intf_read_wgt_mem_gnt=1'b1;

    repeat (2) begin
      @ (posedge clk) ;
    end
//Need to verify if gnt de-asserted after 1 cycle or not
      mem_intf_read_pic_mem_gnt=1'b0; 
      mem_intf_read_wgt_mem_gnt=1'b0;
  end
  endtask // MEM_WGT_READ_REQ

  reg [7:0] data;
  reg [7:0] index;
  reg [ADDR_WIDTH-1:0] start_line_addr;
  
  task WINDOWS_IN_RAW(input [15:0] times , input [7:0] row_num);
    begin
      data=8'd6;
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
          
          MEM_PIC_READ_REQ(start_line_addr+JUMP*index,data);
          MEM_PIC_READ_REQ(start_line_addr+JUMP*index+sw_cnn_x_n,data+1'b1);
          MEM_PIC_READ_REQ(start_line_addr+JUMP*index+sw_cnn_x_n*2,data+2'b10);
          MEM_PIC_READ_REQ(start_line_addr+JUMP*index+sw_cnn_x_n*3,data+2'b11);
          data=data+3'd4;
          index=index+1'b1;

        end
    end
  endtask


  
    
  task TEST_128X128_4X4();//input [ADDR_WIDTH-1:0] start_addr);
   begin
     MEM_PIC_READ_REQ_FRST({ADDR_WIDTH{1'b0}},8'd2);
     MEM_WGT_READ_REQ({ADDR_WIDTH{1'b0}},8'd2);
     //==============================================
      MEM_PIC_READ_REQ(sw_cnn_x_n,8'd3);
      MEM_PIC_READ_REQ(sw_cnn_x_n*2,8'd4);
      MEM_PIC_READ_REQ(sw_cnn_x_n*3,8'd5);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP,8'd6);
     // MEM_PIC_READ_REQ(JUMP+sw_cnn_x_n,8'd7);
     // MEM_PIC_READ_REQ(JUMP+sw_cnn_x_n*2,8'd8);
     // MEM_PIC_READ_REQ(JUMP+sw_cnn_x_n*3,8'd9);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*2,8'd10);
     // MEM_PIC_READ_REQ(JUMP*2+sw_cnn_x_n,8'd11);
     // MEM_PIC_READ_REQ(JUMP*2+sw_cnn_x_n*2,8'd12);
     // MEM_PIC_READ_REQ(JUMP*2+sw_cnn_x_n*3,8'd13);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*3,8'd14);
     // MEM_PIC_READ_REQ(JUMP*3+sw_cnn_x_n,8'd15);
     // MEM_PIC_READ_REQ(JUMP*3+sw_cnn_x_n*2,8'd16);
     // MEM_PIC_READ_REQ(JUMP*3+sw_cnn_x_n*3,8'd17);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*4,8'd18);
     // MEM_PIC_READ_REQ(JUMP*4+sw_cnn_x_n,8'd19);
     // MEM_PIC_READ_REQ(JUMP*4+sw_cnn_x_n*2,8'd20);
     // MEM_PIC_READ_REQ(JUMP*4+sw_cnn_x_n*3,8'd21);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*5,8'd22);
     // MEM_PIC_READ_REQ(JUMP*5+sw_cnn_x_n,8'd23);
     // MEM_PIC_READ_REQ(JUMP*5+sw_cnn_x_n*2,8'd24);
     // MEM_PIC_READ_REQ(JUMP*5+sw_cnn_x_n*3,8'd25);
     // //==============================================
     // MEM_PIC_READ_REQ(JUMP*6,8'd26);
     // MEM_PIC_READ_REQ(JUMP*6+sw_cnn_x_n,8'd27);
     // MEM_PIC_READ_REQ(JUMP*6+sw_cnn_x_n*2,8'd28);
     // MEM_PIC_READ_REQ(JUMP*6+sw_cnn_x_n*3,8'd29);
     // //==============================================
        WINDOWS_IN_RAW(124,calc_row);
         calc_row=calc_row+1'b1;
         $monitor("end %d row at %0t",calc_row,$time);
  
     for(integer i=1;i<128;i++)
       begin
         WINDOWS_IN_RAW(125,calc_row);
         calc_row=calc_row+1'b1;
         $monitor("end %d row at %0t",calc_row,$time);         
       end


   
    // wait(mem_intf_write.mem_req && mem_intf_read_pic.mem_start_addr==mem_intf_read_pic.mem_size_bytes)
    //   mem_intf_write_mem_gnt=1'b1;
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
    end

  endmodule
