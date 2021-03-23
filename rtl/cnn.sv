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
            mem_intf_read_bias,
            
            cnn_sw_busy_ind,
            sw_cnn_addr_bias,
            sw_cnn_addr_x,
            sw_cnn_addr_y,
            sw_cnn_addr_z,
            sw_cnn_x_m,   
            sw_cnn_x_n,
            sw_cnn_y_m,
            sw_cnn_y_n,

            sw_cnn_go,
            sw_cnn_done,
            
            //Debug
            data2write_out,
            activation_out_smpl

            );
  
  parameter DP_DEPTH=4;
  parameter ADDR_WIDTH=19; //TODO: check width
  // parameter MAX_BYTES_TO_RD=20;
  // parameter LOG2_MAX_BYTES_TO_RD=$clog2(MAX_BYTES_TO_RD);
  
  // parameter MAX_BYTES_TO_WR=5;  
  // parameter LOG2_MAX_BYTES_TO_WR=$clog2(MAX_BYTES_TO_WR);
  // parameter MEM_DATA_BUS=128;
  parameter BYTES_TO_WRITE=4;

  parameter X_ROWS_NUM=128;
  parameter X_COLS_NUM=128;
                     
  parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  

  parameter Y_ROWS_NUM=4;
  parameter Y_COLS_NUM=4;
                     
  parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);
  
  parameter JUMP_COL=1;
  parameter JUMP_ROW=1;


//===============================================================================
//                              FSM STATES
//===============================================================================

  typedef
    enum logic [2:0]
      {
       IDLE  = 3'h0,
       READ  = 3'h1,
       CALC  = 3'h2,
       SHIFT = 3'h3,
       WRITE = 3'h4 } t_states;

  t_states state,nx_state;
//===============================================================================

//===============================================================================
//                              Interface
//===============================================================================  
  input  clk;	//clock
  input  rst_n;	//reset negative
  
  //====================  
  //  Memory Interfaces
  //==================== 
  mem_intf_write.client_write          mem_intf_write;
  
  mem_intf_read.client_read            mem_intf_read_pic;
  mem_intf_read.client_read            mem_intf_read_wgt;
  mem_intf_read.client_read            mem_intf_read_bias;
  
  //====================      
  // Software Interface
  //====================
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_bias; 	// CNN Bias value address	
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_x;	// CNN Data window FIRST address
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_y;	// CNN  weights window FIRST address
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_z;	// CNN return address
  input [X_LOG2_ROWS_NUM:0]         sw_cnn_x_m;  	// CNN data matrix num of rows
  input [X_LOG2_COLS_NUM:0]         sw_cnn_x_n;	        // CNN data matrix num of columns
  input [Y_LOG2_ROWS_NUM:0]         sw_cnn_y_m;	        // CNN weight matrix num of rows
  input [Y_LOG2_COLS_NUM:0]         sw_cnn_y_n;	        // CNN weight matrix num of columns 
  output reg                        cnn_sw_busy_ind;	// An output to the software - 1 – CNN unit is busy CNN is available (Default)

  input                             sw_cnn_go;          //Input from Software to start calculation
  output reg                        sw_cnn_done;        //Output to Softare to inform on end of calculation

  //Debug
  output reg signed [31:0]                    data2write_out;    //Output for debug onlt - outputs the result of each window calculation before activation.
  output reg        [7:0]                     activation_out_smpl;

  reg        [7:0]                 cut_data_pic [0:DP_DEPTH-1] ; //Single byte to send to dot_product from the picture matrix (big one)                 
  reg signed [7:0]                 data_wgt [0:DP_DEPTH-1] ;     //Single byte to send to dot_product from the weight matrix  (small one)
  reg [ADDR_WIDTH-1:0]             current_read_addr;            //Calculation of read addr from memory. 
  reg [ADDR_WIDTH-1:0]             current_row_start_addr;
  wire signed [31:0]               dp_res;                       //Output of dot_product unit. 

  reg [7:0]                         counter_calc;   //For now it is only 0 or 1. it should be used for multiple calculations on the same data bus
  reg                               last_byte_of_bus;
  reg [3:0]                         calc_line;         //Calculate the index of line out of the calculation of single window
  reg [7:0]                         window_cols_index; //Index of window out of single matrix. used for multiplication of 'JUMP_COL'.
  reg [7:0]                         window_rows_index; //Index of window out of single matrix. used for multiplication of 'JUMP_ROW'.

  reg signed [31:0]                 data2write;        
  reg signed [31:0]                 data2activation;
  reg signed [31:0][7:0]            wgt_mem_data;     //Small memory for the weights

  wire [7:0]                        activation_out;
  //reg  [7:0]                        activation_out_smpl;
  reg                               first_read_of_weights; //In order to read only once the weights matrix and the bias value per 1 Picture matrix


//============================================
//   For Debug Only !!!
//============================================
  always @(posedge clk or negedge rst_n)
    begin
      if(~rst_n)
        begin
          data2write_out<=32'd0;
          activation_out_smpl<=8'd0;
        end      
      else
        if(calc_line==Y_ROWS_NUM)
          begin
            data2write_out<= data2write;
            activation_out_smpl<=activation_out;
          end
        else
          begin
            data2write_out<=32'd0;
            activation_out_smpl<=8'd0;
          end
    end
  
//============================================

  
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
          if(sw_cnn_go==1'b1)
           nx_state = READ;
          else
           nx_state = IDLE; 
        end
      READ:
        begin
          if((window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line==Y_ROWS_NUM)) //If end of calculation
             nx_state = WRITE; 
          else if(mem_intf_read_pic.mem_valid==1'b1)// && mem_intf_read_wgt.mem_valid==1'b1)
             nx_state = CALC;
          else
             nx_state = READ; 
        end
      
      CALC:
        begin
          nx_state = SHIFT;
          end
      SHIFT:
        begin
          if((calc_line==4'd0)&&(((window_cols_index%33)==8'd0)||(window_cols_index==X_COLS_NUM-Y_COLS_NUM+1))) //8 is num of DW in data BUS. TODO: change the num of cycles until write!!!
            begin
             nx_state = WRITE; 
            end
          
          else
             nx_state = READ;
        end
      
      WRITE:
        begin
          if(sw_cnn_done)
          nx_state = IDLE;
          else if(mem_intf_write.mem_ack)
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
        mem_intf_write.mem_last_valid<= 1'b0;
        
        mem_intf_read_pic.mem_req<=1'b0;
        mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
        mem_intf_read_pic.mem_size_bytes<='d0; //TODO: change to num of bits

        mem_intf_read_wgt.mem_req<=1'b0;
        mem_intf_read_wgt.mem_start_addr<={ADDR_WIDTH{1'b0}};
        mem_intf_read_wgt.mem_size_bytes<='d0; //TODO: change to num of bits

        mem_intf_read_bias.mem_req<=1'b0;
        mem_intf_read_bias.mem_start_addr<={ADDR_WIDTH{1'b0}};
        mem_intf_read_bias.mem_size_bytes<='d0; //TODO: change to num of bits
          

        counter_calc<=8'd0;
        
        // cut_data_pic[0]<= 8'd0;
        // data_wgt[0]<= 8'd0;
        // cut_data_pic[1]<= 8'd0;
        // data_wgt[1]<= 8'd0;
        // cut_data_pic[2]<= 8'd0;
        // data_wgt[2]<= 8'd0;
        // cut_data_pic[3]<= 8'd0;
        // data_wgt[3]<= 8'd0;

        // cut_data_pic[0:DP_DEPTH-1]<={DP_DEPTH{8'd0}};
        // data_wgt[0:DP_DEPTH-1]<={DP_DEPTH{8'd0}}; 
        

        first_read_of_weights<=1'b1;


        
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
            //mem_intf_read_pic.mem_start_addr <= current_read_addr;
            mem_intf_read_pic.mem_size_bytes <= DP_DEPTH;

            if(first_read_of_weights)
              begin
                mem_intf_read_wgt.mem_req <=1'b1;
                mem_intf_read_wgt.mem_start_addr <= sw_cnn_addr_x;
                mem_intf_read_wgt.mem_size_bytes <= DP_DEPTH;

                mem_intf_read_bias.mem_req <=1'b1;
                mem_intf_read_bias.mem_start_addr <= sw_cnn_addr_bias;
                mem_intf_read_bias.mem_size_bytes <= 'd1; //TODO: CHANGE TO ACTUAL WIDTH
                first_read_of_weights<=1'b0;
              end
            else
              begin
                mem_intf_read_wgt.mem_req <=1'b0;
                mem_intf_read_wgt.mem_start_addr <= {ADDR_WIDTH{1'b0}};
                mem_intf_read_wgt.mem_size_bytes <= 'd0;  //TODO: CHANGE TO ACTUAL WIDTH

                mem_intf_read_bias.mem_req <=1'b1;
                mem_intf_read_bias.mem_start_addr <= {ADDR_WIDTH{1'b0}};
                mem_intf_read_bias.mem_size_bytes <= 'd0;  //TODO: CHANGE TO ACTUAL WIDTH
                end
            
            
            last_byte_of_bus<=1'b0;
            counter_calc<=8'd0;

            if((calc_line==4'd0)&&(counter_calc==8'd0))
              wgt_mem_data<=mem_intf_read_wgt.mem_data;
            
            
            if(mem_intf_write.mem_ack)
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
            wgt_mem_data<=wgt_mem_data>>(DP_DEPTH*8);
            counter_calc<=counter_calc+1'b1;

            //Put in other always block!
            // cut_data_pic[0]<= mem_intf_read_pic.mem_data[0];
            // data_wgt[0]<= wgt_mem_data[0];
            // cut_data_pic[1]<= mem_intf_read_pic.mem_data[1];
            // data_wgt[1]<= wgt_mem_data[1];
            // cut_data_pic[2]<= mem_intf_read_pic.mem_data[2];
            // data_wgt[2]<= wgt_mem_data[2];
            // cut_data_pic[3]<= mem_intf_read_pic.mem_data[3];
            // data_wgt[3]<= wgt_mem_data[3];

                      
            if(counter_calc==1)//DP_DEPTH-1)
              begin
                last_byte_of_bus<=1'b1;
                end
          end // if (state==CALC)
        else if (state==WRITE)
          begin
            mem_intf_write.mem_start_addr <=sw_cnn_addr_z;
            mem_intf_write.mem_req<=1'b1;
            mem_intf_write.mem_size_bytes<=BYTES_TO_WRITE;
            end
        
      end    
  end // always @ (posedge clk or negedge rst_n)

  genvar c;

  generate
    for (c = 0; c < DP_DEPTH; c = c + 1) 
      begin : generate_loop
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
          begin
            cut_data_pic[c]<= 8'd0;
            data_wgt[c]<= 8'd0;
          end
        else if(state==CALC)
          begin
            cut_data_pic[c]<= mem_intf_read_pic.mem_data[c];
            data_wgt[c]<= wgt_mem_data[c];
          end
      end
    end
endgenerate  
  
  dot_product_parallel #(.DEPTH(DP_DEPTH)) dp_pll_ins(.a(cut_data_pic), .b(data_wgt), .res(dp_res));                     

  always @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          //current_read_addr<={ADDR_WIDTH{1'b0}};
          mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
          calc_line <= 4'd0;
          window_cols_index<=8'd1;
          window_rows_index<=8'd1;
          current_row_start_addr<={ADDR_WIDTH{1'b0}};
        end
      else
        begin
          if((window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line==Y_ROWS_NUM))
            begin
              //current_read_addr<={ADDR_WIDTH{1'b0}};
              mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
              calc_line <= 4'd0;
              window_cols_index<=8'd1;
              window_rows_index<=8'd1;
              current_row_start_addr<={ADDR_WIDTH{1'b0}};            
              end
          else if(window_cols_index==X_COLS_NUM-Y_COLS_NUM+2)//2)
            begin
              current_row_start_addr<=X_ROWS_NUM*window_rows_index;
              mem_intf_read_pic.mem_start_addr<=X_ROWS_NUM*window_rows_index;
              //current_read_addr<=X_ROWS_NUM*window_rows_index;
              window_rows_index<=window_rows_index+1'b1;
              window_cols_index<=8'd1;
              end           
          else if(calc_line==Y_COLS_NUM)
            begin
              //current_read_addr<=current_row_start_addr+JUMP_COL*window_cols_index;
              mem_intf_read_pic.mem_start_addr<=current_row_start_addr+JUMP_COL*window_cols_index;
              calc_line <= 4'd0;
              window_cols_index<=window_cols_index+1'b1;   ///TODO: zero when end of matrix
            end
          
          else if((state==SHIFT && counter_calc==DP_DEPTH) || (state==READ && counter_calc==1))  //The first one never happens, second one does. 
            begin
              //current_read_addr<=current_read_addr+sw_cnn_x_n;
              mem_intf_read_pic.mem_start_addr<=mem_intf_read_pic.mem_start_addr+sw_cnn_x_n;
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
          cnn_sw_busy_ind<=1'b0;
          sw_cnn_done<=1'b0;
        end
      else
        begin
          if(state==IDLE)
            begin
              cnn_sw_busy_ind<=1'b0;
              sw_cnn_done<=1'b0;
            end
          else if((window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line==4'd4))
            begin
              cnn_sw_busy_ind<=1'b0;
              sw_cnn_done<=1'b1;
            end
          else if(sw_cnn_go==1'b1)
            begin
              cnn_sw_busy_ind<=1'b1;  
            end
        end
    end // always @ (posedge clk or negedge rst_n)

               

  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
       mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
        data2write<=32'd0; 
      end
    else
      begin
        if((state==CALC) && (calc_line==4'd0)&&(window_cols_index!=8'd33))
          begin
           mem_intf_write.mem_data<= mem_intf_write.mem_data<<8;
            end
        else if((calc_line==Y_COLS_NUM))// && (window_cols_index!=8'd8))
          begin
          mem_intf_write.mem_data[0] <= activation_out;//mem_intf_write.mem_data<<32;
          data2write<=32'd0;
            end
        else if (state==SHIFT)   
          begin  
            data2write<=data2write+dp_res;                    
            //mem_intf_write.mem_data[3:0]<=mem_intf_write.mem_data[3:0]+dp_res;
          end

            // if(mem_intf_write.mem_data[0] > 'd127)
            // mem_intf_write.mem_data[0] <= 'd127;//TODO: change to num of bits
            // else if (mem_intf_write.mem_data[0] < -'d128)
            // mem_intf_write.mem_data[0] <= -'d128;   
        

        else if((state==WRITE) && (mem_intf_write.mem_ack==1'b1))
          begin
          mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
          //data2write<=32'd0;
            end
      end
  end // always @ (posedge clk or negedge rst_n)

  assign data2activation = (calc_line==Y_ROWS_NUM)? (data2write + mem_intf_read_bias.mem_data[3:0]) : 32'd0;
                           
 activation activation_ins (.in(data2activation), .out(activation_out));
  
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
  end // always @ (posedge clk or negedge rst_n)







  
endmodule
