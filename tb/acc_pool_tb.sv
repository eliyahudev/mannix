//======================================================================================================
//
// Module: acc_pool_tb
//
// Design Unit Owner :Netanel Lalazar
//                    
//
//======================================================================================================

module acc_pool_tb ();


  parameter   CLK_PERIOD = 6.25; //80Mhz


  parameter JUMP_COL=1;
  parameter JUMP_ROW=1;
  parameter WORD_WIDTH=8;         //Simhi's parameter for memory  
  parameter NUM_WORDS_IN_LINE=32; //Simhi's parameter for memory  
  parameter ADDR_WIDTH=19;        //Simhi's parameter for memory                         

  parameter X_ROWS_NUM=128;   //Picture dim
  parameter X_COLS_NUM=128;   //Picture dim
                     
  parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  
  parameter Y_ROWS_NUM=8;  //Filter dim
  parameter Y_COLS_NUM=8;  //Filter dim
                     
  parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);

  reg         clk;
  reg         rst_n;
  reg         clk_config_tb;
  reg         clk_enable;

  reg        [7:0]  input_data [0:((X_COLS_NUM*X_ROWS_NUM)-1)];   //Register that contains the data from the input txt file.

  
  //====================      
  // Software Interface
  //====================		
  reg [ADDR_WIDTH-1:0]            sw_pool_addr_x;	// POOL Data window FIRST address
  reg [ADDR_WIDTH-1:0]            sw_pool_addr_y;	// POOL  weights window FIRST address
  reg [ADDR_WIDTH-1:0]            sw_pool_addr_z;	// POOL return address
  reg [X_LOG2_ROWS_NUM:0]       sw_pool_x_m;  	// POOL data matrix num of rows
  reg [X_LOG2_COLS_NUM:0]       sw_pool_x_n;	        // POOL data matrix num of columns
  reg [Y_LOG2_ROWS_NUM:0]       sw_pool_y_m;	        // POOL weight matrix num of rows
  reg [Y_LOG2_COLS_NUM:0]       sw_pool_y_n;	        // POOL weight matrix num of columns 
  wire                            pool_sw_busy_ind;	// An output to the software - 1 – POOL unit is busy POOL is available (Default)

  reg                             pool_go;   //From SW
  wire                            pool_done; //From SW

  reg                             mem_intf_write_mem_valid;  
  reg                             mem_intf_read_pic_mem_valid;
  reg                             mem_intf_read_pic_last;
  
  reg [31:0][7:0]                 mem_intf_read_pic_mem_data;
  
  reg [$clog2(NUM_WORDS_IN_LINE*WORD_WIDTH/8)-1:0] mem_intf_read_pic_mem_last_valid ;


  reg [7:0] calc_row;
  reg signed [31:0]       avrg;

  wire [31:0] data2write_out;
  

  reg signed [7:0] data [0:3] ;
  reg signed [7:0] weights [0:3];
  reg [7:0] results [0:15624];


  integer dta;
  integer res;
  integer scan;

always #CLK_PERIOD  clk_config_tb    = !clk_config_tb;  // Configurable 

assign clk = clk_enable ? clk_config_tb : 1'b0;

  
  initial
    begin
      dta = $fopen("/u/e2017/lalazan/Desktop/Final_project/mannix/txt_files/pool_data.txt", "r");
      res = $fopen("/u/e2017/lalazan/Desktop/Final_project/mannix/txt_files/pool_results.txt", "r");
      clk_enable      = 1'b1;
      clk_config_tb   = 1'b0;
      pool_go         = 1'b1;
      
      for (integer k=0;k<(X_ROWS_NUM*X_COLS_NUM);k=k+1)
        scan=$fscanf(dta,"%d\n",input_data[k]);
  

      for (integer r=0; r<((X_ROWS_NUM-3'd3)*(X_COLS_NUM-3'd3)); r=r+1)
          scan=$fscanf(res,"%d\n",results[r]);
          
      
      RESET_VALUES();
      ASYNC_RESET();
      TEST_128X128_8X8();
      pool_go=1'b0;
      #30;
      
      $stop;
    end
  
  
  mem_intf_read mem_intf_read_pic();
    
  assign mem_intf_read_pic.mem_valid=mem_intf_read_pic_mem_valid;
  assign mem_intf_read_pic.last=mem_intf_read_pic_last;
  assign mem_intf_read_pic.mem_data=mem_intf_read_pic_mem_data;
  assign mem_intf_read_pic.mem_last_valid=mem_intf_read_pic_mem_last_valid;
   
  mem_intf_write mem_intf_write();
  assign mem_intf_write.mem_ack=mem_intf_write_mem_valid;  

  
pool #(
  .JUMP_COL(JUMP_COL),
  .JUMP_ROW(JUMP_ROW),    
  .ADDR_WIDTH(ADDR_WIDTH),
                       
  .X_ROWS_NUM(X_ROWS_NUM),
  .X_COLS_NUM(X_COLS_NUM),
                     
  .X_LOG2_ROWS_NUM(X_LOG2_ROWS_NUM),
  .X_LOG2_COLS_NUM(X_LOG2_COLS_NUM), 
  

  .Y_ROWS_NUM(Y_ROWS_NUM),
  .Y_COLS_NUM(Y_COLS_NUM),
                     
  .Y_LOG2_ROWS_NUM(Y_LOG2_ROWS_NUM),
  .Y_LOG2_COLS_NUM(Y_LOG2_COLS_NUM)

      )pool_ins(
            .clk(clk),
            .rst_n(rst_n),

            .mem_intf_write(mem_intf_write),
            .mem_intf_read_pic(mem_intf_read_pic),
            
            .pool_sw_busy_ind(pool_sw_busy_ind),
            .sw_pool_addr_x(sw_pool_addr_x),
            .sw_pool_addr_z(sw_pool_addr_z),
            .sw_pool_x_m(sw_pool_x_m),   
            .sw_pool_x_n(sw_pool_x_n),
            .sw_pool_y_m(sw_pool_y_m),
            .sw_pool_y_n(sw_pool_y_n),
               
            .sw_pool_go(pool_go),
            .sw_pool_done(pool_done),
               //Debug
            .data2write_out(data2write_out)   

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

    calc_row =8'd0;
    
    mem_intf_write_mem_valid=1'b0;
    
    mem_intf_read_pic_mem_valid=1'b0;
    mem_intf_read_pic_last=1'b0;
    mem_intf_read_pic_mem_data='d0;
    mem_intf_read_pic_mem_last_valid='d0; 

    $monitor("RESET_VALUES\n");
    sw_pool_addr_x={ADDR_WIDTH{1'b0}};	// POOL Data window FIRST address
    sw_pool_addr_y={ADDR_WIDTH{1'b0}};	// POOL  weights window FIRST address
    sw_pool_addr_z={ADDR_WIDTH{1'b0}};	// POOL return address
    sw_pool_x_m=X_ROWS_NUM;  	        // POOL data matrix num of rows
    sw_pool_x_n=X_COLS_NUM;	        // POOL data matrix num of columns
    sw_pool_y_m=Y_ROWS_NUM;	        // POOL weight matrix num of rows
    sw_pool_y_n=Y_COLS_NUM;	        // POOL weight matrix num of columns
             
    end
  endtask // ASYNC_RESET

  integer j; 

  task MEM_PIC_READ_REQ (input [ADDR_WIDTH-1:0] addr,input [7:0] num_of_bytes );// input signed [7:0] data [0:3]);
    begin
      wait ((mem_intf_read_pic.mem_req == 1'b1)&&(mem_intf_read_pic.mem_start_addr == addr))
        @(posedge clk)
          for(j=0;j<num_of_bytes;j++)
            begin            
              mem_intf_read_pic_mem_data[j]=input_data[addr+j];
              end

           mem_intf_read_pic_mem_last_valid=num_of_bytes-1'b1;

      mem_intf_read_pic_mem_valid=1'b1;

      repeat (1) begin
        @ (posedge clk) ;
      end

      mem_intf_read_pic_mem_valid=1'b0;   
    end
  endtask // MEM_PIC_READ_REQ




  //reg [7:0] data;
  reg [7:0] index;
  reg [ADDR_WIDTH-1:0] start_line_addr;
  reg [31:0]           index_res;
  integer              u;
  
  task WINDOWS_IN_RAW(input [15:0] times , input [7:0] row_num);
    begin
      if(row_num == 8'd0)
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
          for(u=0;u<Y_ROWS_NUM;u++) begin
              MEM_PIC_READ_REQ( start_line_addr + JUMP_ROW * index + sw_pool_x_n * u , Y_ROWS_NUM);
           end
          
        //  data=data+3'd4;
          index=index+1'b1;
          wait(data2write_out == results[index_res]); // netaTODO
          $display ("index: %d, Value res: %d , RTL val: %d \n",index_res,results[index_res],data2write_out) ;
          if(results[index_res] == data2write_out)
            $display("Yay");
            else
              $display("Boo");
          // $monitor ("index: %d equal, Value: %d",index ,results[(row_num*(8'd125))+(index-1'd1)]);
        end
    end
  endtask


  
  integer   q; 

  task TEST_128X128_8X8();
    begin 
	for(q=0; q < Y_ROWS_NUM ; q++) begin
              MEM_PIC_READ_REQ( q * sw_pool_x_n , Y_ROWS_NUM);
           end
	  
 	wait(data2write_out == results[0]) 
        $monitor ("index: 0 equal, Value: %d",results[0]); 


       WINDOWS_IN_RAW(X_ROWS_NUM-Y_ROWS_NUM,calc_row);
          calc_row=calc_row+1'b1;
          $monitor("finished %d row at %0t",calc_row,$time);
  
        for(integer i=1;i<(X_ROWS_NUM-Y_ROWS_NUM+1);i++)
        begin
          WINDOWS_IN_RAW(X_ROWS_NUM-Y_ROWS_NUM+1,calc_row);
          calc_row = calc_row+1'b1;
          $monitor("finished %d row at %0t",calc_row,$time);            
        end

    $display("done");
    
  end
   endtask

  always @(posedge clk) begin// mem valid vld
    
      if(mem_intf_write.mem_req) //&& mem_intf_read_pic.mem_start_addr == mem_intf_read_pic.mem_size_bytes)
          mem_intf_write_mem_valid<=1'b1; 
               
      else
          mem_intf_write_mem_valid<=1'b0; 
         
    end // always @ (posedge clk)



  endmodule
