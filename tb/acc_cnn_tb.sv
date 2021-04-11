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

module acc_cnn_tb ();

  parameter DEPTH=4;

  parameter   CLK_PERIOD = 6.25; //80Mhz


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

  parameter X_ROWS_NUM=28;
  parameter X_COLS_NUM=28;
                     
  parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  

  parameter Y_ROWS_NUM=5;
  parameter Y_COLS_NUM=5;
                     
  parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);

  parameter DP_DEPTH=5;

  reg         clk;
  reg         rst_n;
  reg         clk_config_tb;
  reg         clk_enable;

  reg        [7:0]  a_data [0:((X_COLS_NUM*X_ROWS_NUM)-1)];
  reg signed [7:0]  w_data [0:((Y_COLS_NUM*Y_ROWS_NUM)-1)];
  
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

always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;

  
  initial
    begin

      dta = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/data.txt", "r");
      wgt = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/weights.txt", "r");
      res_real = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/res_real.txt", "r");
      res = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/results_after_activation.txt", "r");
      
      // dta = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/128x128/data.txt", "r");
      // wgt = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/128x128/weights.txt", "r");
      // res_real = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/128x128/res_real.txt", "r");
      // res = $fopen("/nfs/site/stod/areas/d/w.dabushni.102/PROJECT_4TH_YEAR/128x128/results_after_activation.txt", "r");
      
      clk_enable = 1'b1;
      clk_config_tb   = 1'b0;
      cnn_go=1'b1;
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
      
      avrg=sum_res_real/15625;
      
      
      RESET_VALUES();
      ASYNC_RESET();
      @(posedge clk)
      cnn_go=1'b0;
      TEST_128X128_4X4();
      //cnn_go=1'b0;
      #100;
      
      $stop;
    end
  
  
  mem_intf_read mem_intf_read_pic();
    
  assign mem_intf_read_pic.mem_valid=mem_intf_read_pic_mem_gnt;
  assign mem_intf_read_pic.last=mem_intf_read_pic_last;
  assign mem_intf_read_pic.mem_data=mem_intf_read_pic_mem_data;
  assign mem_intf_read_pic.mem_last_valid=mem_intf_read_pic_mem_last_valid;
   

  mem_intf_read mem_intf_read_wgt();
  
  assign mem_intf_read_wgt.mem_valid=mem_intf_read_wgt_mem_gnt;
  assign mem_intf_read_wgt.last=mem_intf_read_wgt_last;
  assign mem_intf_read_wgt.mem_data=mem_intf_read_wgt_mem_data;
  assign mem_intf_read_wgt.mem_last_valid=mem_intf_read_wgt_mem_last_valid;

  mem_intf_read mem_intf_read_bias();
  
  assign mem_intf_read_bias.mem_valid=mem_intf_read_bias_mem_gnt;
  assign mem_intf_read_bias.last=mem_intf_read_bias_last;
  assign mem_intf_read_bias.mem_data=mem_intf_read_bias_mem_data;
  assign mem_intf_read_bias.mem_last_valid=mem_intf_read_bias_mem_last_valid;  

  
  

  mem_intf_write mem_intf_write();
                              assign mem_intf_write.mem_ack=mem_intf_write_mem_gnt;  

  
cnn #(
  .DP_DEPTH(DP_DEPTH),
  .JUMP_COL(JUMP_COL),
  .JUMP_ROW(JUMP_ROW),    
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
 
   
  
     sw_cnn_addr_bias={ADDR_WIDTH{1'b0}}; // CNN Bias value address 		
     sw_cnn_addr_x={ADDR_WIDTH{1'b0}};	// CNN Data window FIRST address
     sw_cnn_addr_y={ADDR_WIDTH{1'b0}};	// CNN  weights window FIRST address
     sw_cnn_addr_z={ADDR_WIDTH{1'b0}};	// CNN return address
    sw_cnn_x_m=X_ROWS_NUM;  	        // CNN data matrix num of rows
    sw_cnn_x_n=X_COLS_NUM;	        // CNN data matrix num of columns
    sw_cnn_y_m=Y_ROWS_NUM;	        // CNN weight matrix num of rows
    sw_cnn_y_n=Y_COLS_NUM;	        // CNN weight matrix num of columns
    
   
      
    end
  endtask // ASYNC_RESET

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
  

  task MEM_WGT_READ_REQ (input [ADDR_WIDTH-1:0] addr, input signed [7:0] data [0:((Y_COLS_NUM*Y_ROWS_NUM)-1)]);
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
     MEM_PIC_READ_REQ_FRST({ADDR_WIDTH{1'b0}},Y_ROWS_NUM);
     MEM_WGT_READ_REQ({ADDR_WIDTH{1'b0}},w_data);
     MEM_BIAS_READ_REQ(sw_cnn_addr_bias,avrg); 
     //==============================================
      MEM_PIC_READ_REQ(sw_cnn_x_n,Y_ROWS_NUM);
      MEM_PIC_READ_REQ(sw_cnn_x_n*2,Y_ROWS_NUM);
      MEM_PIC_READ_REQ(sw_cnn_x_n*3,Y_ROWS_NUM);
      MEM_PIC_READ_REQ(sw_cnn_x_n*4,Y_ROWS_NUM);
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

  ///for DOR:
  // // repeat(32)
  // begin
  //   <TASK NAME>;
  //   end

  endmodule
