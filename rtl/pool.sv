//======================================================================================================
//
// Module: pool
//
// Description: probably supports only square filter
//
//======================================================================================================

module pool 
		#(   
			parameter ADDR_WIDTH=19,        //Simhi's parameter for memory                       
			//parameter BYTES_TO_WRITE=32,

			parameter X_ROWS_NUM=128,   //Picture dim
			parameter X_COLS_NUM=128,   //Picture dim  
			
			parameter Y_ROWS_NUM=8,  //Filter dim
			parameter Y_COLS_NUM=8,  //Filter dim

			parameter JUMP_COL=1,
 			parameter JUMP_ROW=1,
			parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM),
			parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM),
			
			parameter  Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM),
			parameter  Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM)			
			
			)(
			
                input 		clk,			//clock
                input 		rst_n,			//reset negative
	  	
  		//Debug
 		output reg signed [31:0]         data2write_out,    //Output for debug only - outputs the result of each window calculation before activation. 
    
	// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==       
	// Software Interface
	// ==  ==  ==  ==  ==  ==  ==  ==  ==  == 		
			input [ADDR_WIDTH-1:0]            sw_pool_addr_x,	//POOL Data matrix FIRST address
			input [ADDR_WIDTH-1:0]            sw_pool_addr_z,	//POOL return address
			
			input [X_LOG2_ROWS_NUM:0]    sw_pool_x_m,  	//POOL data matrix num of rows
			input [X_LOG2_COLS_NUM:0]    sw_pool_x_n,	//POOL data matrix num of columns
			
			input [Y_LOG2_ROWS_NUM:0]     sw_pool_y_m,	//POOL filter size - rows
			input [Y_LOG2_COLS_NUM:0]     sw_pool_y_n,	//POOL filter size - columns 
			
			input 		sw_pool_go, //SW indication to start calculation 
			output reg	sw_pool_done,		//Design indication to SW that calculation is done.
			output reg 	pool_sw_busy_ind,	//An output to the software: 1 if POOL unit is busy and 0 if POOL is available (Default)
			
	// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==   
	//  Memory Interfaces (structs)
	// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  

			mem_intf_write.client_write          mem_intf_write,
			mem_intf_read.client_read            mem_intf_read_pic
			
			);


  

//################################################################################################################################################################


// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == =
//                              FSM STATES
// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == =

  typedef
    enum logic [2:0]
      {
       IDLE  = 3'h0,
       READ  = 3'h1,
       CALC  = 3'h2,
       SHIFT = 3'h3,
       WRITE = 3'h4 } t_states;

  t_states state,nx_state; // define 2 variables of type "t_states"


// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == =
//                              Interface
// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == =  

    reg [7:0]                         cut_data_pic [0:7] ;	 	// 8 numbers - the data from one memory call
	reg [ADDR_WIDTH-1:0]              current_row_start_addr;
	wire [7:0]              	  	  sort_res;                       //Output of sort unit to find max. 

	reg [7:0]                         counter_calc;   //For now it is only 0 or 1. it should be used for multiple calculations on the same data bus
	reg [3:0]                         calc_line;         //Calculate the index of line out of the calculation of single window
	reg [7:0]                         window_cols_index; //Index of window out of single matrix. used for multiplication of 'JUMP_COL'.
	reg [7:0]                         window_rows_index; //Index of window out of single matrix. used for multiplication of 'JUMP_ROW'.
 
	reg                               read_pic_data_vld;
	reg [6:0]                         calc_load_of_wr_bus; //In order to calc when to write - when the data write bus is full.
reg first_read_of_pic; //in order to rise the request in READ state only at the first time 
reg [ADDR_WIDTH-1:0]              calc_addr_to_wr; //Calc the current addr to write to
reg last_window_calc;
// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
//   For Debug Only !!!
// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
	always @(posedge clk or negedge rst_n) begin
		if(~rst_n)
			data2write_out <= 32'd0;
		else if(calc_line == Y_ROWS_NUM)
			data2write_out <= sort_res; 
	     	else
			data2write_out <= 32'd0;
	end
  
// ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 


//=======================================================================================================

assign read_condition = (state==READ);   

assign mem_intf_read_pic.mem_req = (mem_intf_read_pic.mem_valid)? 1'b0 : (read_condition && first_read_of_pic) ? 1'b1 :(state==CALC)? 1'b1: 1'b0;    
assign mem_intf_read_pic.mem_size_bytes = mem_intf_read_pic.mem_req ? Y_COLS_NUM : {ADDR_WIDTH{1'b0}};//TODO:CHECK WITH SIMHI IF NEEDED


assign mem_intf_write.mem_req        = mem_intf_write.mem_ack ? 1'b0: (state==WRITE)? 1'b1 : 1'b0;
assign mem_intf_write.mem_start_addr = (state==WRITE)? calc_addr_to_wr :{ADDR_WIDTH{1'b0}};
assign mem_intf_write.mem_size_bytes = (state==WRITE)? calc_load_of_wr_bus-1'b1 :{ADDR_WIDTH{1'b0}};
//=======================================================================================================


	reg [7:0]	buffer [0:7] ; 		// 8 numbers - buff to write to
	reg [7:0]       sort_data [0:7] ; 	// 8 numbers - which numbers to sort now

		assign sort_data = (calc_line  ==  4'd8) ? buffer : cut_data_pic ; // mux sort_8 input

		always @(posedge clk or negedge rst_n)begin // flip flops of buff 		
			if(!rst_n)begin
				buffer[0] <= 8'd0;
				buffer[1] <= 8'd0;
				buffer[2] <= 8'd0;
				buffer[3] <= 8'd0;
				buffer[4] <= 8'd0;
				buffer[5] <= 8'd0;
				buffer[6] <= 8'd0;
				buffer[7] <= 8'd0;
			end 
			// flip flops of buff : 
			//improvement// buffer[calc_line] <= sort_res
			else if(calc_line == 4'd0) buffer[0] <= sort_res;
			else if(calc_line == 4'd1) buffer[1] <= sort_res;
			else if(calc_line == 4'd2) buffer[2] <= sort_res;
			else if(calc_line == 4'd3) buffer[3] <= sort_res;
			else if(calc_line == 4'd4) buffer[4] <= sort_res;
			else if(calc_line == 4'd5) buffer[5] <= sort_res;
			else if(calc_line == 4'd6) buffer[6] <= sort_res;
			else if(calc_line == 4'd7) buffer[7] <= sort_res;
					
		end // always

	sort_8 sort_8_ins( .num1(sort_data[0][7:0]), .num2(sort_data[1][7:0]), .num3(sort_data[2][7:0]), .num4(sort_data[3][7:0]),
		.num5(sort_data[4][7:0]), .num6(sort_data[5][7:0]), .num7(sort_data[6][7:0]), .num8(sort_data[7][7:0]), .big(sort_res) );   
  
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
			  if(sw_pool_go ==  1'b1)
			   nx_state = READ;
			  else
			   nx_state = IDLE; 
			end
				
		      READ:
			begin
			  if((window_cols_index == (X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index == (X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line == Y_ROWS_NUM)) //If end of calculation
			     nx_state = WRITE; 
			  else if(read_pic_data_vld)
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
			  if(((calc_line == 4'd0)&&((calc_load_of_wr_bus == 6'd33)))||((calc_line == Y_COLS_NUM-1'd1)&&(window_rows_index == X_ROWS_NUM-Y_ROWS_NUM+1))) //8 is num of DW in data BUS. TODO: change the num of cycles until write!!!
			    begin
			     nx_state = WRITE; 
			    end
			  
			  else
				nx_state = READ; // another calc
			end
		      
		      WRITE:
			begin
			  if(sw_pool_done)
					nx_state = IDLE;
			  else if(mem_intf_write.mem_ack) // the data was written 
					nx_state = READ;
			  else // the data was NOT written 
					nx_state = WRITE;
			end
		      
		      default:
			begin
			end
		      
		      endcase
		      
		      end // else: !if(!rst_n)
		    end

		 
		always @(posedge clk or negedge rst_n) // ask data memory and 
		  begin
		    if(!rst_n)
		      begin
			pool_sw_busy_ind <= 1'b0;
			       
                        first_read_of_pic<=1'b1;
			counter_calc<=8'd0;
			
		       	cut_data_pic[0]<= 8'd0;
			cut_data_pic[1]<= 8'd0;
			cut_data_pic[2]<= 8'd0;
			cut_data_pic[3]<= 8'd0;
			cut_data_pic[4]<= 8'd0;
			cut_data_pic[5]<= 8'd0;
			cut_data_pic[6]<= 8'd0;
			cut_data_pic[7]<= 8'd0;
                        calc_addr_to_wr <=sw_pool_addr_z; //CHECK THAT VALUE IS AVILABLE AT THIS POINT
			
		      end
		    else
		      begin
if(state==IDLE)
begin
pool_sw_busy_ind <= 1'b0;
			       
 first_read_of_pic<=1'b1;
			counter_calc<=8'd0;
			
		       	cut_data_pic[0]<= 8'd0;
			cut_data_pic[1]<= 8'd0;
			cut_data_pic[2]<= 8'd0;
			cut_data_pic[3]<= 8'd0;
			cut_data_pic[4]<= 8'd0;
			cut_data_pic[5]<= 8'd0;
			cut_data_pic[6]<= 8'd0;
			cut_data_pic[7]<= 8'd0;
calc_addr_to_wr <=sw_pool_addr_z; //CHECK THAT VALUE IS AVILABLE AT THIS POINT

end
else if (state==READ)
begin
if(first_read_of_pic && mem_intf_read_pic.mem_valid) 
			  first_read_of_pic<=1'b0;
end

			else if (state == CALC)
			  begin
			    mem_intf_read_pic.mem_data <= mem_intf_read_pic.mem_data >> 32;
			    counter_calc<=counter_calc+1'b1;
			    
			    cut_data_pic[0]<= mem_intf_read_pic.mem_data[0];
			    cut_data_pic[1]<= mem_intf_read_pic.mem_data[1];
			    cut_data_pic[2]<= mem_intf_read_pic.mem_data[2];
			    cut_data_pic[3]<= mem_intf_read_pic.mem_data[3];
			    cut_data_pic[4]<= mem_intf_read_pic.mem_data[4];
			    cut_data_pic[5]<= mem_intf_read_pic.mem_data[5];
			    cut_data_pic[6]<= mem_intf_read_pic.mem_data[6];
			    cut_data_pic[7]<= mem_intf_read_pic.mem_data[7];

			  end // if (state == CALC)	
else if (state==WRITE && mem_intf_write.mem_ack)
          begin
            calc_addr_to_wr <= sw_pool_addr_z+calc_addr_to_wr+calc_load_of_wr_bus-1'd1;
            end		
			
		      end    
		  end // always @ (posedge clk or negedge rst_n)

		always @(posedge clk or negedge rst_n)
		    begin
		      if(!rst_n)
			begin
			  mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
			  calc_line <= {Y_ROWS_NUM{1'b0}}; 
			  window_cols_index<=8'd1;
			  window_rows_index<=8'd1;
			  current_row_start_addr<={ADDR_WIDTH{1'b0}};
			end
		      else
			begin
			  if(state == IDLE)
			  begin
			    mem_intf_read_pic.mem_start_addr <= sw_pool_addr_x;
			    window_cols_index<=8'd1;
			    window_rows_index<=8'd1;   
			  end
			  else if((window_cols_index == (X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index == (X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line == Y_ROWS_NUM))
			    begin
			      mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
			      calc_line <= 4'd0;
			      // window_cols_index<=8'd1;
			      // window_rows_index<=8'd1;
			      current_row_start_addr<={ADDR_WIDTH{1'b0}};            
			      end
			  else if(window_cols_index == X_COLS_NUM-Y_COLS_NUM+2)//2)
			    begin
			      current_row_start_addr<=X_ROWS_NUM*window_rows_index;
			      mem_intf_read_pic.mem_start_addr<=X_ROWS_NUM*window_rows_index;
			      window_rows_index<=window_rows_index+1'b1;
			      window_cols_index<=8'd1;
			      end           
			  //else if(calc_line == Y_COLS_NUM)
			else if((calc_line==Y_COLS_NUM-1'b1)&&(state==READ))
			    begin
			      mem_intf_read_pic.mem_start_addr<=current_row_start_addr+JUMP_COL*window_cols_index;
			     // calc_line <= 4'd0;
				calc_line <= calc_line+1'b1;
			      window_cols_index<=window_cols_index+1'b1;   ///TODO: zero when end of matrix
			    end
			  
			 // else if((state == SHIFT && counter_calc == Y_ROWS_NUM) || (state == READ && counter_calc == 1))  //The first one never happens, second one does. 
				else if(calc_line==Y_COLS_NUM)
				begin
				calc_line <= 4'd0;
				end
			else if(nx_state==CALC)
			    begin
			      mem_intf_read_pic.mem_start_addr<=mem_intf_read_pic.mem_start_addr+sw_pool_x_n;
			      calc_line <= calc_line+1'b1;
			    end

			  // if (state == WRITE)
			  //  window_cols_index<=8'd1; 
			end
		    end
			
		assign last_window_calc = ((state==WRITE) &&(window_rows_index==(X_ROWS_NUM-Y_ROWS_NUM+1))&&(window_cols_index==(X_COLS_NUM- Y_COLS_NUM+1)) && (calc_load_of_wr_bus<6'd33) &&(mem_intf_write.mem_ack));

		assign sw_pool_done = (state==IDLE)? 1'b0 : (last_window_calc)? 1'b1 : 1'b0;

		  always @(posedge clk or negedge rst_n) begin // manage busy & done
		    
		      if(!rst_n)begin
			  pool_sw_busy_ind <= 1'b0;
			//  sw_pool_done <= 1'b0;
			end
		      else begin
			if(state == IDLE) begin
			      pool_sw_busy_ind <= 1'b0;
			     // sw_pool_done <= 1'b0;
			    end    //              cols 					rows 						last calc  
			  else if((window_cols_index == (X_COLS_NUM-Y_COLS_NUM+1))&&(window_rows_index == (X_ROWS_NUM-Y_ROWS_NUM+1))&&(calc_line == Y_ROWS_NUM))
			    begin // done with calc
			      pool_sw_busy_ind  <=  1'b0;
			    //  sw_pool_done <= 1'b1;
			    end
			  else if(sw_pool_go == 1'b1)
				pool_sw_busy_ind <= 1'b1;  
			end // !if !rst_n
		    end // always - manage busy & done

		 
		  // shift_last is not defined !  // assign shift_last = ((6'd33-calc_load_of_wr_bus-1'd1) << 3);      

		  always @(posedge clk or negedge rst_n) // assign data2write & intf_write.mem_data
		  begin
		    if(!rst_n)
		      begin
		       mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
			//data2write <= 32'd0; 
		      end
		    else begin
			/* shift_last is not defined !  //if((state == WRITE) &&(window_rows_index == (X_ROWS_NUM-Y_ROWS_NUM+1)) && (window_cols_index == (X_COLS_NUM-Y_COLS_NUM+1)) && (calc_load_of_wr_bus<6'd33) && (mem_intf_write.mem_req == 1'b0))
			  begin
			   // shift_last is not defined !  // mem_intf_write.mem_data<= mem_intf_write.mem_data>>shift_last;//((6'd33-calc_load_of_wr_bus-1'd1)<<3);  
			    end else */       
			 if((state == CALC) && (calc_line == 4'd0)&&(calc_load_of_wr_bus != 6'd33))
			  begin
			   mem_intf_write.mem_data<= mem_intf_write.mem_data>>8;
			    end
			else if((calc_line == Y_COLS_NUM))// && (window_cols_index!=8'd8))
			  begin
			    mem_intf_write.mem_data[31] <= sort_res; 
			   // data2write <= sort_res;
			    end
			else if (state == SHIFT) // at end of 1 filter   
			  begin  
			   // data2write <= sort_res;                    
			    //mem_intf_write.mem_data[3:0]<=mem_intf_write.mem_data[3:0]+dp_res;
			  end

			    // if(mem_intf_write.mem_data[0] > 'd127)
			    // mem_intf_write.mem_data[0] <= 'd127;//TODO: change to num of bits
			    // else if (mem_intf_write.mem_data[0] < -'d128)
			    // mem_intf_write.mem_data[0] <= -'d128;   
			

			else if((state == WRITE) && (mem_intf_write.mem_ack == 1'b1))
			  begin
			  mem_intf_write.mem_data <= 'd0;//TODO: change to num of bits
			 // data2write <= 32'd0;
			    end
		      end // !reset
		  end // always @ (posedge clk or negedge rst_n)

		//  assign data2activation = (calc_line == Y_ROWS_NUM)? (data2write + mem_intf_read_bias.mem_data[3:0]) : 32'd0;
				           
		// activation activation_ins (.in(data2activation), .out(activation_out));

		  always @(posedge clk or negedge rst_n)
		    begin
		      if(!rst_n)
			begin
			  calc_load_of_wr_bus <= 6'd1;
			end
		      else
			begin
			  if(((state == WRITE)&&(window_rows_index == 8'd1)&&(calc_load_of_wr_bus<6'd33))||(state == IDLE))
			    begin
			    calc_load_of_wr_bus <= 6'd1;   
			    end 
			  else if((calc_load_of_wr_bus == 6'd33)&&(state == WRITE)&&(mem_intf_write.mem_ack==1'd1))// || ((window_cols_index == X_COLS_NUM-Y_COLS_NUM+2)))
			    calc_load_of_wr_bus <= 6'd0;
			  else if(calc_line == Y_COLS_NUM)
			    calc_load_of_wr_bus <= calc_load_of_wr_bus+1'd1;
			  
			end
		    end // always @ (posedge clk or negedge rst_n)

		  
 always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        read_pic_data_vld<=1'b0;
      end
    else if(state==IDLE)
		begin
        read_pic_data_vld<=1'b0;
		end
	else
      begin
        if(mem_intf_read_pic.mem_valid==1'b1)
          read_pic_data_vld<=1'b1;        
        else if(state==CALC)
          read_pic_data_vld<=1'b0;

      end
  end // always @ (posedge clk or negedge rst_n)

		 
		  always @(posedge clk or negedge rst_n) // states
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
