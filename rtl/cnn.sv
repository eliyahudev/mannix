//=====================================================================================================
//
// Module: cnn
//
// Design Unit Owner : Netanel Lalazar
//                    
// Original Author   : Netanel Lalazar
// Original Date     : 27-Nov-2020
//
//=====================================================================================================
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

  parameter X_ROWS_NUM=5;
  parameter X_COLS_NUM=5;
                     
  parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  

  parameter Y_ROWS_NUM=2;
  parameter Y_COLS_NUM=2;
                     
  parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);

  parameter IDLE=2'b00;
  parameter READ=2'b01;
  parameter CALC=2'b10;
  parameter WRITE=2'b11;
  
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
  input [X_LOG2_ROWS_NUM-1:0]       sw_cnn_x_m;  	// CNN data matrix num of rows
  input [X_LOG2_COLS_NUM-1:0]       sw_cnn_x_n;	        // CNN data matrix num of columns
  input [Y_LOG2_ROWS_NUM-1:0]       sw_cnn_y_m;	        // CNN weight matrix num of rows
  input [Y_LOG2_COLS_NUM-1:0]       sw_cnn_y_n;	        // CNN weight matrix num of columns 
  output reg                        cnn_sw_busy_ind;	// An output to the software - 1 – CNN unit is busy CNN is available (Default)

  reg [7:0]                        cut_data_pic [DP_DEPTH-1:0] ;                   
  reg [7:0]                        data_wgt [DP_DEPTH-1:0] ;
  wire [16:0]                       dp_res;
  
  reg [1:0]                         state;
  reg [1:0]                         nx_state;

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
             nx_state = WRITE;
        end
      
      WRITE:
        begin
          if(mem_intf_write.mem_gnt)
          nx_state = IDLE;
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
        mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
        mem_intf_write.mem_last_valid<= 1'b0;
        
        mem_intf_read_pic.mem_req<=1'b0;
        mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
        mem_intf_read_pic.mem_size_bytes<='d0; //TODO: change to num of bits

        mem_intf_read_wgt.mem_req<=1'b0;
        mem_intf_read_wgt.mem_start_addr<={ADDR_WIDTH{1'b0}};
        mem_intf_read_wgt.mem_size_bytes<='d0; //TODO: change to num of bits


        cut_data_pic[0]<= 8'd0;
        data_wgt[0]<= 8'd0;
        
      end
    else
      begin
        if(state==IDLE)
          begin
          end
        else if(state==READ)
          begin
            mem_intf_read_pic.mem_req <=1'b1;
            mem_intf_read_pic.mem_start_addr <= sw_cnn_addr_x;
            mem_intf_read_pic.mem_size_bytes <= DP_DEPTH;

            mem_intf_read_wgt.mem_req <=1'b1;
            mem_intf_read_wgt.mem_start_addr <= sw_cnn_addr_x;
            mem_intf_read_wgt.mem_size_bytes <= DP_DEPTH;
            end
        else if (state==CALC)
          begin
            cut_data_pic[0]<= mem_intf_read_pic.mem_data[7:0];
            data_wgt[0]<= mem_intf_read_wgt.mem_data[7:0];
            cut_data_pic[1]<= mem_intf_read_pic.mem_data[7:0];
            data_wgt[1]<= mem_intf_read_wgt.mem_data[7:0];
            cut_data_pic[2]<= mem_intf_read_pic.mem_data[7:0];
            data_wgt[2]<= mem_intf_read_wgt.mem_data[7:0];
            cut_data_pic[3]<= mem_intf_read_pic.mem_data[7:0];
            data_wgt[3]<= mem_intf_read_wgt.mem_data[7:0];
            end
        
      end    
  end
  
  dot_product_parallel #(.DEPTH(DP_DEPTH)) dp_pll_ins(.a(cut_data_pic), .b(data_wgt), .res(dp_res));                     


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
