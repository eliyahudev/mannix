//======================================================================================================
//
// Module: cnn
//
// Design Unit Owner : Netanel Lalazar
//                    
// Original Author   : Netanel Lalazar
// Original Date     : 27-Nov-2020
//
//======================================================================================================
module cnn (
            clk,
            rst_n,

            mem_intf_write,
            mem_intf_read_pic,
            mem_intf_read_wgt,
            
            cnn_sw_busy_ind,
            sw_cnn_addr_x,
            sw_cnn_addr_y,
            sw_cnn_addr_z,
            sw_cnn_x_m,   
            sw_cnn_x_n,
            sw_cnn_y_m,
            sw_cnn_y_n,

            );
  
  parameter DP_DEPTH=4;
  parameter ADDR_WIDTH=19; //TODO: check width
  parameter MAX_BYTES_TO_RD=20;
  parameter LOG2_MAX_BYTES_TO_RD=$clog2(MAX_BYTES_TO_RD);  
  parameter MAX_BYTES_TO_WR=5;  
  parameter LOG2_MAX_BYTES_TO_WR=$clog2(MAX_BYTES_TO_WR);
  parameter MEM_DATA_BUS=128;
  parameter BYTES_TO_WRITE=4;

  parameter X_ROWS_NUM=128;
  parameter X_COLS_NUM=128;
                     
  parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  

  parameter Y_ROWS_NUM=4;
  parameter Y_COLS_NUM=4;
                     
  parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);

  parameter IDLE=3'b000;
  parameter READ=3'b001;
  parameter CALC=3'b010;  
  parameter SHIFT=3'b011;
  parameter WRITE=3'b100;
  
  parameter JUMP_COL=1;
  parameter JUMP_ROW=1;
  
  input  clk;	//clock
  input  rst_n;	//reset negative
  
  //====================  
  //  Memory Interfaces
  //==================== 
  mem_intf_write.client_write          mem_intf_write;
  
  mem_intf_read.client_read            mem_intf_read_pic;
  mem_intf_read.client_read            mem_intf_read_wgt;
  
  //====================      
  // Software Interface
  //====================		
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_x;	// CNN Data window FIRST address
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_y;	// CNN  weights window FIRST address
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_z;	// CNN return address
  input [X_LOG2_ROWS_NUM:0]       sw_cnn_x_m;  	// CNN data matrix num of rows
  input [X_LOG2_COLS_NUM:0]       sw_cnn_x_n;	        // CNN data matrix num of columns
  input [Y_LOG2_ROWS_NUM:0]       sw_cnn_y_m;	        // CNN weight matrix num of rows
  input [Y_LOG2_COLS_NUM:0]       sw_cnn_y_n;	        // CNN weight matrix num of columns 
  output reg                        cnn_sw_busy_ind;	// An output to the software - 1 – CNN unit is busy CNN is available (Default)

  reg [7:0]                        cut_data_pic [DP_DEPTH-1:0] ;                   
  reg [7:0]                        data_wgt [DP_DEPTH-1:0] ;
  reg [ADDR_WIDTH-1:0]             current_read_addr;
  reg [ADDR_WIDTH-1:0]             current_row_start_addr;
  wire [16:0]                       dp_res;
  
  reg [2:0]                         state;
  reg [2:0]                         nx_state;

  reg [7:0]                         counter_calc;
  reg                               last_byte_of_bus;
  reg [3:0]                         calc_line; //Calculate the index of line out of the calculation of single window
  reg [7:0]                         window_cols_index; //Index of window out of single matrix. used for multiplication of 'JUMP_COL'.
  reg [7:0]                         window_rows_index; //Index of window out of single matrix. used for multiplication of 'JUMP_ROW'.
  
always @(*)
  begin
     if(!rst_n)
      begin      
        nx_state = IDLE;        
      end
    else
      begin
    case(state)
      IDLE:
        begin
         nx_state = READ; 
        end
      READ:
        begin
          if(mem_intf_read_pic.mem_gnt==1'b1)
             nx_state = CALC;
          else
             nx_state = READ; 
        end
      
      // WAIT_GNT:
      //   begin
      //     if(mem_intf_read_pic.mem_gnt==1'b1)
      //        nx_state = CALC;
      //     else
      //        nx_state = WAIT_GNT; 
      //   end
      CALC:
        begin
          nx_state = SHIFT;
          end
      SHIFT:
        begin
          //if(counter_calc==Y_ROWS_NUM*Y_COLS_NUM)
          if(((window_cols_index%8)==8'd0)&&(calc_line==4'd0)) //8 is num of DW in data BUS
            begin
             nx_state = WRITE; 
            end
          
         // if(last_byte_of_bus)
          else
             nx_state = READ;
         // else
           // begin
           //   nx_state = CALC;
            //  end
        end
      
      WRITE:
        begin
          if(mem_intf_write.mem_gnt)
          nx_state = READ;
          else
          nx_state = WRITE;
        end
      
      default:
        begin
        end
      
      endcase
      
      end // else: !if(!rst_n)
    end
  
 
always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        cnn_sw_busy_ind <= 1'b0;
        
        mem_intf_write.mem_req <= 1'b0;
        mem_intf_write.mem_start_addr <= {ADDR_WIDTH{1'b0}};
        mem_intf_write.mem_size_bytes <= 'd0;  //TODO: change to num of bits
        mem_intf_write.last<= 1'b0;
     //   mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
        mem_intf_write.mem_last_valid<= 1'b0;
        
        mem_intf_read_pic.mem_req<=1'b0;
        mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
        mem_intf_read_pic.mem_size_bytes<='d0; //TODO: change to num of bits

        mem_intf_read_wgt.mem_req<=1'b0;
        mem_intf_read_wgt.mem_start_addr<={ADDR_WIDTH{1'b0}};
        mem_intf_read_wgt.mem_size_bytes<='d0; //TODO: change to num of bits

        counter_calc<=8'd0;
        
        cut_data_pic[0]<= 8'd0;
        data_wgt[0]<= 8'd0;
        cut_data_pic[1]<= 8'd0;
        data_wgt[1]<= 8'd0;
        cut_data_pic[2]<= 8'd0;
        data_wgt[2]<= 8'd0;
        cut_data_pic[3]<= 8'd0;
        data_wgt[3]<= 8'd0;


        
        last_byte_of_bus<=1'b0;
        //calc_line<=4'd0;
        
      end
    else
      begin
        if(state==IDLE)
          begin
            mem_intf_read_pic.mem_start_addr <= sw_cnn_addr_x;            
          end
        else if(state==READ)
          begin
            mem_intf_read_pic.mem_req <=1'b1;
            mem_intf_read_pic.mem_start_addr <= current_read_addr;
            mem_intf_read_pic.mem_size_bytes <= DP_DEPTH;

            mem_intf_read_wgt.mem_req <=1'b1;
            mem_intf_read_wgt.mem_start_addr <= sw_cnn_addr_x;
            mem_intf_read_wgt.mem_size_bytes <= DP_DEPTH;
            last_byte_of_bus<=1'b0;
            counter_calc<=8'd0;
            
            if(mem_intf_write.mem_gnt)
              begin
                mem_intf_write.mem_req<=1'b0;
                end
            end
        else if (state==CALC)
          begin
            //   begin
                mem_intf_read_pic.mem_req <=1'b0;
                mem_intf_read_wgt.mem_req <=1'b0;
             //   end
            mem_intf_read_pic.mem_data<=mem_intf_read_pic.mem_data>>32;
            counter_calc<=counter_calc+1'b1;
            
            cut_data_pic[0]<= mem_intf_read_pic.mem_data[0];
            data_wgt[0]<= mem_intf_read_wgt.mem_data[7:0];
            cut_data_pic[1]<= mem_intf_read_pic.mem_data[1];
            data_wgt[1]<= mem_intf_read_wgt.mem_data[7:0];
            cut_data_pic[2]<= mem_intf_read_pic.mem_data[2];
            data_wgt[2]<= mem_intf_read_wgt.mem_data[7:0];
            cut_data_pic[3]<= mem_intf_read_pic.mem_data[3];
            data_wgt[3]<= mem_intf_read_wgt.mem_data[7:0];

            // if(calc_line==Y_COLS_NUM)
            //   begin
            //   calc_line <= 4'd0;
            //   end
            // else
            //   calc_line <= calc_line+1'b1;
           // mem_intf_write.mem_data<=mem_intf_write.mem_data<<8;//-1'b1);
            
            if(counter_calc==1)//DP_DEPTH-1)
              begin
                last_byte_of_bus<=1'b1;
                end
          end // if (state==CALC)
        else if (state==SHIFT)
          begin
            // if(calc_line==Y_COLS_NUM)
            //   mem_intf_write.mem_data <= mem_intf_write.mem_data<<32;
            // else                           
            // mem_intf_write.mem_data[0]<=mem_intf_write.mem_data[0]+dp_res; //mem_intf_write.mem_data<=mem_intf_write.mem_data<<(counter_calc-1'b1);
            end
        else if (state==WRITE)
          begin
            mem_intf_write.mem_start_addr <=sw_cnn_addr_z;
            mem_intf_write.mem_req<=1'b1;
            mem_intf_write.mem_size_bytes<=BYTES_TO_WRITE;
            //mem_intf_write.mem_data
            //mem_intf_write.mem_data<=dp_res;
            // if(mem_intf_write.mem_gnt==1'b1)
            //   begin
            //     mem_intf_read_pic.mem_start_addr <= mem_intf_read_pic.mem_start_addr + mem_intf_write.mem_size_bytes;
            //     end
            end
        
      end    
  end
  
  dot_product_parallel #(.DEPTH(DP_DEPTH)) dp_pll_ins(.a(cut_data_pic), .b(data_wgt), .res(dp_res));                     

  always @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          current_read_addr<={ADDR_WIDTH{1'b0}};
          calc_line <= 4'd0;
          window_cols_index<=8'd1;
          window_rows_index<=8'd1;
          current_row_start_addr<={ADDR_WIDTH{1'b0}};
        end
      else
        begin
          if(window_cols_index==X_COLS_NUM-2)
            begin
              current_row_start_addr<=X_ROWS_NUM*window_rows_index;
              current_read_addr<=X_ROWS_NUM*window_rows_index;
              window_rows_index<=window_rows_index+1'b1;
              window_cols_index<=8'd1;
              end           
          else if(calc_line==Y_COLS_NUM)
            begin
              current_read_addr<=current_row_start_addr+JUMP_COL*window_cols_index;
              calc_line <= 4'd0;
              window_cols_index<=window_cols_index+1'b1;   ///TODO: zero when end of matrix
            end
          
          else if((state==SHIFT && counter_calc==DP_DEPTH) || (state==READ && counter_calc==1))
            begin
              current_read_addr<=current_read_addr+sw_cnn_x_n;
              calc_line <= calc_line+1'b1;
            end

          // if (state==WRITE)
          //  window_cols_index<=8'd1; 
        end
    end


  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
       mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits 
      end
    else
      begin
        if((calc_line==Y_COLS_NUM) && (window_cols_index!=8'd8))
          mem_intf_write.mem_data <= mem_intf_write.mem_data<<32;
        else if (state==SHIFT)                          
          mem_intf_write.mem_data[3:0]<=mem_intf_write.mem_data[3:0]+dp_res;
        else if((state==WRITE) && (mem_intf_write.mem_gnt==1'b1))
          mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
      end
  end

  
  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        state <= IDLE;
      end
    else
      begin
        state <= nx_state;
      end
  end





  
endmodule

