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
  //parameter BYTES_TO_WRITE=4;

  parameter X_ROWS_NUM=128;
  parameter X_COLS_NUM=128;
                     
  localparam X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  localparam X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  

  parameter Y_ROWS_NUM=4;
  parameter Y_COLS_NUM=4;
                     
  localparam Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  localparam Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);
  
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
  output                            sw_cnn_done;        //Output to Software to inform on end of calculation

  //========================== Debug ==============================
  output reg signed [31:0]                    data2write_out;    //Output for debug onlt - outputs the result of each window calculation before activation.
  output reg        [7:0]                     activation_out_smpl;
  //===============================================================
  reg        [7:0]                 cut_data_pic [0:DP_DEPTH-1] ; //Single byte to send to dot_product from the picture matrix (big one)                 
  reg signed [7:0]                 data_wgt [0:DP_DEPTH-1] ;     //Single byte to send to dot_product from the weight matrix  (small one)
  //reg [ADDR_WIDTH-1:0]             current_read_addr;            //Calculation of read addr from memory. 
  reg [ADDR_WIDTH-1:0]             current_row_start_addr;
  wire signed [31:0]               dp_res;                       //Output of dot_product unit. 

  reg [7:0]                         counter_calc;   //For now it is only 0 or 1. it should be used for multiple calculations on the same data bus
  reg [3:0]                         calc_line;         //Calculate the index of line out of the calculation of single window
  reg [7:0]                         window_cols_index; //Index of window out of single matrix. used for multiplication of 'JUMP_COL'.
  reg [7:0]                         window_rows_index; //Index of window out of single matrix. used for multiplication of 'JUMP_ROW'.
  reg [6:0]                         calc_load_of_wr_bus; //In order to calc when to write-when the data write bus is full. 

  reg signed [31:0]                 data2write;        
  reg signed [31:0]                 data2activation;
  reg signed [31:0][7:0]            wgt_mem_data;     //Small memory for the weights
  reg signed [31:0][7:0]            wgt_mem_data_smpl;     //Small memory for the weights

  wire [31:0]                       shift_last;  //How many bits to shift when last writing happens
  wire [7:0]                        activation_out;
  reg                               first_read_of_weights; //In order to read only once the weights matrix and the bias value per 1 Picture matrix
  reg                               first_read_of_pic; 
  reg                               first_read_of_bias;
  reg                               read_pic_data_vld;
  reg                               read_wgt_data_vld;
  reg                               read_bias_data_vld;
  wire                              read_condition;
  reg [ADDR_WIDTH-1:0]              calc_addr_to_wr; //Calc the current addr to write to
  reg [31:0]                        sample_bias_val; 
  wire                              last_window_calc;
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
        if(calc_line=='d0 && (state==READ))
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
          else if(read_pic_data_vld && read_wgt_data_vld && read_bias_data_vld)
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
         // if(((calc_line==4'd0)&&((calc_load_of_wr_bus==6'd33)))||((calc_line==Y_COLS_NUM-1'd1)&&(window_cols_index==X_COLS_NUM-Y_COLS_NUM+1))) 
	if(((calc_line==4'd0)&&((calc_load_of_wr_bus==6'd33)))||((calc_line==Y_COLS_NUM-1'd1)&&(window_rows_index==X_ROWS_NUM-Y_ROWS_NUM+1))) 
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
         nx_state = IDLE; 
        end
      
      endcase
      
      end // else: !if(!rst_n)
    end
  
//=======================================================================================================

assign read_condition = (state==READ);   
assign mem_intf_read_wgt.mem_req =(mem_intf_read_wgt.mem_valid )? 1'b0 : ( read_condition && first_read_of_weights )? 1'b1: 1'b0;
assign mem_intf_read_wgt.mem_start_addr  = (mem_intf_read_wgt.mem_req && first_read_of_weights)? sw_cnn_addr_y : {ADDR_WIDTH{1'b0}};
assign mem_intf_read_wgt.mem_size_bytes  = (mem_intf_read_wgt.mem_req && first_read_of_weights)? DP_DEPTH*DP_DEPTH      : {ADDR_WIDTH{1'b0}};


//assign mem_intf_read_pic.mem_req = (mem_intf_read_pic.mem_valid)? 1'b0 : read_condition? 1'b1: 1'b0;
//assign mem_intf_read_pic.mem_req = (mem_intf_read_pic.mem_valid)? 1'b0 : (read_condition && first_read_of_pic) ? 1'b1 :(state==CALC)? 1'b1: 1'b0;    
assign mem_intf_read_pic.mem_req = (mem_intf_read_pic.mem_valid)? 1'b0 : (mem_intf_read_pic.mem_req)? 1'b1 : (read_condition && first_read_of_pic) ? 1'b1 :(state==CALC)? 1'b1: 1'b0;    
assign mem_intf_read_pic.mem_size_bytes = mem_intf_read_pic.mem_req ? DP_DEPTH : {ADDR_WIDTH{1'b0}};


assign mem_intf_read_bias.mem_req = (mem_intf_read_bias.mem_valid )? 1'b0 : (read_condition && first_read_of_bias )? 1'b1: 1'b0;
assign mem_intf_read_bias.mem_start_addr = (mem_intf_read_bias.mem_req && first_read_of_bias)? sw_cnn_addr_bias : {ADDR_WIDTH{1'b0}};
assign mem_intf_read_bias.mem_size_bytes = (mem_intf_read_bias.mem_req && first_read_of_bias)? 'd4 : {ADDR_WIDTH{1'b0}}; 

assign mem_intf_write.mem_req        = mem_intf_write.mem_ack ? 1'b0: (state==WRITE)? 1'b1 : 1'b0;
assign mem_intf_write.mem_start_addr = (state==WRITE)? calc_addr_to_wr :{ADDR_WIDTH{1'b0}};
assign mem_intf_write.mem_size_bytes = (state==WRITE)? calc_load_of_wr_bus-1'b1 :{ADDR_WIDTH{1'b0}};
//=======================================================================================================
  
always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        counter_calc<=8'd0;     
		first_read_of_pic<=1'b1;
        first_read_of_weights<=1'b1;
        first_read_of_bias<=1'b1;
        calc_addr_to_wr <=sw_cnn_addr_z; //CHECK THAT VALUE IS AVILABLE AT THIS POINT
	//	wgt_mem_data <= 'd0;
	//	wgt_mem_data_smpl<= 'd0;
		wgt_mem_data <= '{32{'d0}};
	wgt_mem_data_smpl<= '{32{'d0}};

      end
    else
      begin
       if(state==IDLE)
	   begin
        counter_calc<=8'd0;     
		first_read_of_pic<=1'b1;
        first_read_of_weights<=1'b1;
        first_read_of_bias<=1'b1;
        calc_addr_to_wr <=sw_cnn_addr_z; //CHECK THAT VALUE IS AVILABLE AT THIS POINT
		//wgt_mem_data <= 'd0;
	//	wgt_mem_data_smpl<= 'd0;
	wgt_mem_data <= '{32{'d0}};
	wgt_mem_data_smpl<= '{32{'d0}};
	   end
           
        else if((state==READ)&&              (~((window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line>=Y_COLS_NUM-1'd1))))   
          begin

		if(first_read_of_pic && mem_intf_read_pic.mem_valid) 
			  first_read_of_pic<=1'b0;

           
            if(first_read_of_weights && mem_intf_read_wgt.mem_valid) 
			begin
                first_read_of_weights<=1'b0;
                wgt_mem_data<=mem_intf_read_wgt.mem_data;
				wgt_mem_data_smpl<=mem_intf_read_wgt.mem_data;
			end
		//	else if (read_wgt_data_vld && (calc_line==4'd0))
		//	begin
			//	wgt_mem_data_smpl<=wgt_mem_data;
		//	end

 
            if(mem_intf_read_bias.mem_valid)
              first_read_of_bias<=1'b0;

            
            counter_calc<=8'd0;

         //   if((calc_line==4'd0)&&(counter_calc==8'd0))
       //  if(mem_intf_read_wgt.mem_valid)
          //    wgt_mem_data<=mem_intf_read_wgt.mem_data;
            
                                 
            end
        else if (state==CALC)
          begin
			if(calc_line==DP_DEPTH)
			begin
	          wgt_mem_data<=wgt_mem_data_smpl;
			end
			else
			begin
            wgt_mem_data<=wgt_mem_data>>(DP_DEPTH*8);
	     	end
            counter_calc<=counter_calc+1'b1;

          end 
        else if (state==WRITE && mem_intf_write.mem_ack)
          begin
            calc_addr_to_wr <= calc_addr_to_wr+calc_load_of_wr_bus-1'd1;
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
        else if (state==IDLE)
			begin
			 cut_data_pic[c]<= 8'd0;
             data_wgt[c]<= 8'd0;
			end
		else
          begin
            if(mem_intf_read_pic.mem_valid)
              begin
                cut_data_pic[c]<= mem_intf_read_pic.mem_data[c];
              end
          //  if(mem_intf_read_wgt.mem_valid)
		  if(read_wgt_data_vld && (state==READ))
              begin
                 data_wgt[c]<= wgt_mem_data[c];
				//data_wgt[c]<= mem_intf_read_wgt.mem_data[c];
              end
          end
      end // always @ (posedge clk or negedge rst_n)
    end
endgenerate  
  
  dot_product_parallel #(.DEPTH(DP_DEPTH)) dp_pll_ins(.a(cut_data_pic), .b(data_wgt), .res(dp_res));                     

  always @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
          calc_line <= 4'd0;
          window_cols_index<=8'd1;
          window_rows_index<=8'd1;
          current_row_start_addr<={ADDR_WIDTH{1'b0}};
        end
      else
        begin
          if(state==IDLE)
          begin
			calc_line <= 4'd0;  
            mem_intf_read_pic.mem_start_addr <= sw_cnn_addr_x;
            window_cols_index<=8'd1;
            window_rows_index<=8'd1;  
            current_row_start_addr<={ADDR_WIDTH{1'b0}};
          end
          else if((window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line==Y_ROWS_NUM))
            begin
              mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
              calc_line <= 4'd0;
              current_row_start_addr<={ADDR_WIDTH{1'b0}};            
              end
          else if(window_cols_index==X_COLS_NUM-Y_COLS_NUM+2)
            begin
              current_row_start_addr<=X_ROWS_NUM*window_rows_index;
              mem_intf_read_pic.mem_start_addr<=X_ROWS_NUM*window_rows_index;
              window_rows_index<=window_rows_index+1'b1;
              window_cols_index<=8'd1;
              end           
          else if((calc_line==Y_COLS_NUM-1'b1)&&(state==READ))
            begin
              mem_intf_read_pic.mem_start_addr<=current_row_start_addr+JUMP_COL*window_cols_index;
              //calc_line <= 4'd0;
			  calc_line <= calc_line+1'b1;
              window_cols_index<=window_cols_index+1'b1;   ///TODO: zero when end of matrix
            end
			else if (calc_line==Y_COLS_NUM)
			begin
				calc_line <= 4'd0;
			end
          
          //else if (state==SHIFT)
			  else if (nx_state==CALC)
            begin
              mem_intf_read_pic.mem_start_addr<=mem_intf_read_pic.mem_start_addr+sw_cnn_x_n;
              calc_line <= calc_line+1'b1;
            end
        end
    end


  always @(posedge clk or negedge rst_n)
  begin
	   if(!rst_n)
			sample_bias_val <= 32'd0;
		else if(state==IDLE)
            sample_bias_val <= 32'd0;
		else if(mem_intf_read_bias.mem_valid)
			sample_bias_val <= mem_intf_read_bias.mem_data[3:0];
  end

assign last_window_calc = ((state==WRITE) &&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(calc_load_of_wr_bus<6'd33)&&(mem_intf_write.mem_ack));
assign sw_cnn_done = (state==IDLE)? 1'b0 : (last_window_calc)? 1'b1 : 1'b0;

  always @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          cnn_sw_busy_ind<=1'b0;
        //  sw_cnn_done<=1'b0;
        end
      else
        begin
          if(state==IDLE)
            begin
              cnn_sw_busy_ind<=1'b0;
           //   sw_cnn_done<=1'b0;
            end
          else if((state==WRITE) &&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(calc_load_of_wr_bus<6'd33))        
            begin
              cnn_sw_busy_ind<=1'b0;
           //   sw_cnn_done<=1'b1;
            end
          else if(sw_cnn_go==1'b1)
            begin
              cnn_sw_busy_ind<=1'b1;  
            end
          else
            cnn_sw_busy_ind<=1'b1; 
        end
    end // always @ (posedge clk or negedge rst_n)

  assign shift_last=({3'b0,(6'd33-calc_load_of_wr_bus-1'd1)})<<3;      

  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
       mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
       data2write<=32'd0; 
      end
    else if (state==IDLE)
		begin
         mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
         data2write<=32'd0; 
		end
    else
      begin
        if((state==WRITE) &&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(window_cols_index==(X_COLS_NUM-Y_COLS_NUM+1))&&(calc_load_of_wr_bus<6'd33)&&(mem_intf_write.mem_req==1'b0))
          begin
            mem_intf_write.mem_data<= mem_intf_write.mem_data>>shift_last;
            end        
        else if((state==READ) && (calc_line==4'd0)&&(calc_load_of_wr_bus!=6'd33))
          begin
           mem_intf_write.mem_data<= mem_intf_write.mem_data>>8;
            end
        else if(((calc_line==4'd0)&&(state==READ)))
        //else if (calc_line==4'd0) 
	 // else if (calc_line==Y_ROWS_NUM)
		begin
        mem_intf_write.mem_data[31] <= activation_out;
         data2write<=32'd0;
		// data2write<=data2write+dp_res;   
            end
        else if (state==SHIFT)   
          begin  
         data2write<=data2write+dp_res;  
		// mem_intf_write.mem_data[31] <= activation_out;
         //data2write<=32'd0;

          end
        else if((state==WRITE) && (mem_intf_write.mem_ack==1'b1))
          begin
          mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
            end
      end
  end // always @ (posedge clk or negedge rst_n)

//  assign data2activation = (calc_line==Y_ROWS_NUM && (read_bias_data_vld) )? (data2write + sample_bias_val) : 32'd0;
 assign data2activation = (calc_line==4'd0 && (read_bias_data_vld) && (state==READ) )? (data2write + sample_bias_val) : 32'd0;

                           
 activation activation_ins (.in(data2activation), .out(activation_out));

  always @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          calc_load_of_wr_bus <= 6'd1;
        end
      else if (state==IDLE)
          calc_load_of_wr_bus <= 6'd1;
	  else
        begin
          if(((state==WRITE)&&(window_rows_index==8'd1)&&(calc_load_of_wr_bus<6'd33))||(state==IDLE))
            begin
            calc_load_of_wr_bus <= 6'd1;   
            end 
          else if(((calc_load_of_wr_bus==6'd33)&&(state==WRITE)&&(mem_intf_write.mem_ack==1'd1)))
            calc_load_of_wr_bus <= 6'd0;
          else if(calc_line==Y_COLS_NUM)
            calc_load_of_wr_bus <= calc_load_of_wr_bus+1'd1;
          
        end
    end // always @ (posedge clk or negedge rst_n)

  
 always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        read_pic_data_vld<=1'b0;
        read_wgt_data_vld<=1'b0;
        read_bias_data_vld<=1'b0;
      end
    else if(state==IDLE)
		begin
        read_pic_data_vld<=1'b0;
        read_wgt_data_vld<=1'b0;
        read_bias_data_vld<=1'b0;
		end
	else
      begin
        if(mem_intf_read_pic.mem_valid==1'b1)
          read_pic_data_vld<=1'b1;        
        else if(state==CALC)
          read_pic_data_vld<=1'b0;

        if(mem_intf_read_wgt.mem_valid==1'b1)
          read_wgt_data_vld<=1'b1;
        else if(mem_intf_read_wgt.mem_req==1'b1)
          read_wgt_data_vld<=1'b0;

        if(mem_intf_read_bias.mem_valid==1'b1)
          read_bias_data_vld<=1'b1;
        else if(mem_intf_read_bias.mem_req==1'b1)
          read_bias_data_vld<=1'b0;
 

      end
  end // always @ (posedge clk or negedge rst_n)


  
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
