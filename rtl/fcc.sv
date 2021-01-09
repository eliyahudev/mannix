//======================================================================================================
//
// Module: FCC
//
// Design Unit Owner : Dor Shilo 
//                    
// Original Author   : Dor Shilo 
// Original Date     : 3-Dec-2020
//
//======================================================================================================

module fcc (
		clk,
		rst_n,

		fc_sw_busy_ind,
		
		fc_addrx,
		fc_addry,
		fc_addrb,
		fc_addrz,
		fc_xm,
		fc_ym,
		fc_yn,
		cnn_bn,
		
		fc_go,
		fc_done,

		mem_intf_read_wgt,
		mem_intf_read_pic,
		mem_intf_read_bias,
		mem_intf_write,
		//last
			);
//======================================================================================================
//
// Inputs\Outputs
//
// Owner : Dor Shilo 
//                    
// Inputs:
//		1) fc_addrx - ADDR_WIDTH bits - Data Vector start address 			   - 0x0040
//		2) fc_addry - ADDR_WIDTH bits - Weights matrix start address    	           - 0x0044
//		3) fc_addrb - ADDR_WIDTH bits - Bias vector start address 		   	   - 0x
//		4) fc_xm    - X_LOG2_ROWS_NUM bits - Data vector input length 			   - 0x004B
//		5) fc_ym    - Y_LOG2_ROWS_NUM bits - Weights matrix input length 		   - 0x0050
//		6) fc_yn    - Y_LOG2_ROWS_NUM bits - Weights matrix input width		   	   - 0x0054
//		7) cnn_bn   - X_LOG2_ROWS_NUM bits - Bias vector input length			   - 0x0058
//		8) fc_go		- 1 bit   - Alerting the the adresses are in place	   - 0x
// 
// Outputs:
//		1) fc_addrz	        - ADDR_WIDTH bits - out matrix start address 		   - 0x0048
//		2) fc_done    	 	- 1 bit   - Alerting the FC system finished 	   - 0x
//		3) fc_sw_busy_ind;     - 1 bit   - Output of the software - 1 if the module is busy 
//
//======================================================================================================
// Changes
//		14\12\2020 - Dor :
//							1) changing all CAP letters to small one in inputs\outputs names
//							2) Adding a second read\write inteferance (one for weights and one for data)
//							3) Merging active and fcc
//							4) Adding a-synchronus rst_n signal
//							5) Building the state maching
//		1\01\2021 - Dor:
//							1) Adding reading for bias vector
//======================================================================================================

//======================================================================================================
//
// fc_algorithem
//
//	The module is a state machine:
//	  
//		1) IDLE - The module is waiting for signal fc_go = all adresses are in place.
//		2) REQ  - The module will put out a request for data and weighes and bias.
//				  The alfc_go here is to ask for an entire line of W and all the data - we will recive them 8 bytes of each .
//				  When the data/weights batches are ready - a gnt_data/gnt_weights signal will fc_go (ASSUMPTION - THEY fc_go UP AS ONE)
//		3) DP   - (=dotproduct) doing dot porduct parallel for the 8 bytes we have and saving the result.
//				   If we have 32 bytes ready it we will write to Z and reset counter and move back to request.
//				   If we finished requesting (fc_done is up) then write to Z and move to IDLE
//		4) ACT  - The final step - input is a DP data already summed (32 times) - ACT will use the "step function" type
//				-> if the data is positive - we write to MEM
//				   else - we write 0 to MEM.
//		
//
//      
//======================================================================================================
//======================================================================================================
	// HW accelerator Parameters
//======================================================================================================
  parameter DP_DEPTH=32;
  parameter ADDR_WIDTH=19; //TODO: check width
  parameter MAX_BYTES_TO_RD=20;
  parameter LOG2_MAX_BYTES_TO_RD=$clog2(MAX_BYTES_TO_RD);  
  parameter MAX_BYTES_TO_WR=5;  
  parameter LOG2_MAX_BYTES_TO_WR=$clog2(MAX_BYTES_TO_WR);
  parameter MEM_DATA_BUS=128;
  parameter BYTES_TO_WRITE=32;

  parameter X_ROWS_NUM=128;
  parameter X_COLS_NUM=1;
                     
  parameter X_LOG2_ROWS_NUM =$clog2(X_ROWS_NUM);
  parameter X_LOG2_COLS_NUM =$clog2(X_COLS_NUM); 
  

  parameter Y_ROWS_NUM=128;
  parameter Y_COLS_NUM=128;
                     
  parameter Y_LOG2_ROWS_NUM =$clog2(Y_ROWS_NUM);
  parameter Y_LOG2_COLS_NUM =$clog2(Y_COLS_NUM);
  parameter CNT_32_MAX = 4; //needts to be fc_yn/32 
//======================================================================================================
//Output parameters
//======================================================================================================
parameter NUM_RELU_DESCALE_BITS = 5;
parameter MAX_RELU_VAL = 1<<NUM_RELU_DESCALE_BITS;


  	 
//======================================================================================================
	// HW accelerator I/O
//======================================================================================================
  input 		clk;

  input [ADDR_WIDTH-1:0] 		fc_addrx; 
  input [ADDR_WIDTH-1:0] 		fc_addry;
  input [ADDR_WIDTH-1:0]	 	fc_addrb;
  input [X_LOG2_ROWS_NUM-1:0] 		fc_xm;
  input [Y_LOG2_ROWS_NUM-1:0] 		fc_ym;
  input [Y_LOG2_COLS_NUM-1:0] 		fc_yn;
  input [X_LOG2_ROWS_NUM-1:0] 		cnn_bn;
  input 				fc_go;
  input 				rst_n;
   

  input [ADDR_WIDTH-1:0] 	fc_addrz;
  output reg			fc_done;
  output reg           		fc_sw_busy_ind;
  reg [ADDR_WIDTH-1:0]          current_read_addr;

//======================================================================================================
// Data and weights simulation 
//======================================================================================================
  reg signed [7:0] mem_wgt    [DP_DEPTH-1:0]; //Simulating the memory weights - 8x8 values of 8 bit
  reg signed [7:0] mem_bias ;
  reg signed [7:0] mem_data  [DP_DEPTH-1:0]; 

                
//======================================================================================================
// Interface instanciation 
//======================================================================================================
// -----Weights-----
 mem_intf_read.client_read 	mem_intf_read_wgt ;
//  -----Data-----
 mem_intf_read.client_read 	mem_intf_read_pic ;
//  -----Bias-----
 mem_intf_read.client_read 	mem_intf_read_bias ;
//  -----Write-----
 mem_intf_write.client_write 	mem_intf_write  ;
// -----last-------
//mem_intf_write.client_read 	last  ;

	
//======================================================================================================
//sm allocation
//======================================================================================================
 parameter IDLE = 2'b00;
 parameter REQ  = 2'b01;
 parameter DP   = 2'b10;
 parameter ACT  = 2'b11;
 reg [1:0] state,next_state; // state
 reg [CNT_32_MAX-1 : 0] counter_32; //counting 32 dot product 
 reg [Y_LOG2_ROWS_NUM - 1:0] counter_line;//counting on which line we are on

//====================================================================================================
// DP instanciation
//======================================================================================================

wire [16:0] dp_res;
dot_product_parallel #(.DEPTH(DP_DEPTH)) dp_pll_ins(.a(mem_data), .b(mem_wgt), .res(dp_res)); 
reg [17:0] data_out_sum ;
reg fc_done_dp;

////====================================================================================================
//SM states and moves
//======================================================================================================
 always @(*) begin
	case (state)
	  IDLE: begin
		if((fc_go)&&(!fc_done))
			begin
				next_state = REQ;
			end		
		else
			begin
				next_state = IDLE;
			end
		end//IDLE

	REQ: begin
			if(fc_done) begin
				next_state = IDLE;
			end
			else if (counter_32 == (CNT_32_MAX) )
				begin
					next_state = ACT;
				end

		else if((mem_intf_read_pic.mem_valid==1'b1) && (mem_intf_read_wgt.mem_valid==1'b1))//&& (mem_intf_read_bias.mem_valid == 1'b1))
   				begin 
					next_state = DP;
				end
			else 
				begin
					next_state = REQ;
				end

		  end//REQ	

	DP: begin
		if(fc_done) begin
			next_state = IDLE;
		end
		else if ((counter_32 != CNT_32_MAX) && (fc_done_dp == 1'b1))
				begin
					next_state = REQ;
				end		
		else
				next_state = DP;
		end
	ACT: begin
			next_state = (~mem_intf_write.mem_ack) ? ACT : (fc_done ? IDLE : DP) ;		 
	     end

 endcase
end
 //----------Reset state-------------------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        state <= IDLE;
      end
    else
      begin
        state <= next_state;
      end
  end


 //-----------State actions--------------------------------------------------------
always @(posedge clk or negedge rst_n)
  begin
	if(!rst_n) //-----------rst_n actions----------
		begin
			
			fc_done <= 1'b0;
			data_out_sum <= 32'd0;					//The sum we write
			counter_32 = {CNT_32_MAX{1'b0}} ;	//Counter
		 	fc_sw_busy_ind <= 1'b0;					//FC is busy
		end
 	else if(state == IDLE)	
		begin	//Do nothing
			mem_intf_read_pic.mem_start_addr <= fc_addrx; //passing the real value of the adress
			mem_intf_read_wgt.mem_start_addr <= fc_addry;
		end
end//IDLE - always

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		begin
			current_read_addr<={ADDR_WIDTH{1'b0}};
			fc_done_dp <= 1'b0;
			//------PIC-------
			mem_intf_read_pic.mem_req<=1'b0;
			mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
			mem_intf_read_pic.mem_size_bytes<={DP_DEPTH{1'd0}}; 
			//------WGT-------
			mem_intf_read_wgt.mem_req<=1'b0;
			mem_intf_read_wgt.mem_start_addr<={ADDR_WIDTH{1'b0}};
			mem_intf_read_wgt.mem_size_bytes<={DP_DEPTH{1'd0}}; 	
			//------BIAS-------
			mem_intf_read_bias.mem_req<=1'b0;
			mem_intf_read_bias.mem_start_addr<={ADDR_WIDTH{1'b0}};
			mem_intf_read_bias.mem_size_bytes<={DP_DEPTH{1'd0}}; 		
		end		
	else if(state == REQ )
		begin
			fc_done_dp <= 1'b0;
			if(counter_32 == {CNT_32_MAX{1'b0}}) begin
			// initiallize bias - do only once every line
			mem_intf_read_bias.mem_req <=1'b1;
			mem_intf_read_bias.mem_start_addr <= fc_addrb;
			mem_intf_read_bias.mem_size_bytes <= DP_DEPTH;
			end
		
			// initiallize data
			mem_intf_read_pic.mem_req <=1'b1;
			mem_intf_read_pic.mem_start_addr <= current_read_addr; //The adress to start from!
			mem_intf_read_pic.mem_size_bytes <= DP_DEPTH;
			// initiallize weights
			mem_intf_read_wgt.mem_req <=1'b1;
			mem_intf_read_wgt.mem_start_addr <= current_read_addr;
			mem_intf_read_wgt.mem_size_bytes <= DP_DEPTH;
			if(fc_done_dp) begin
				counter_32 <= counter_32 + 1'd1;
				data_out_sum <= data_out_sum + dp_res;
				current_read_addr<=current_read_addr + 8'd32;
				//current_read_addr<=current_read_addr + 19'd32;
			end
	
		end
	end//REQ -always

//=========================================================================
//DP:
//	as of right now we get 32 bytes evety time 
//=========================================================================
 always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		begin //TODO - change the data<=mem_data using Udi
			mem_data[0]<= 8'd0;
			mem_data[1]<= 8'd0;
			mem_data[2]<= 8'd0;	
			mem_data[3]<= 8'd0;
			mem_wgt[0]<= 8'd0;
			mem_wgt[1]<= 8'd0;
			mem_wgt[2]<= 8'd0;	
			mem_wgt[3]<= 8'd0;
		end	
        else if(state == DP) 
			begin

               			    mem_intf_read_pic.mem_req <=1'b0;
               			    mem_intf_read_wgt.mem_req <=1'b0;

				    mem_bias<= mem_intf_read_bias.mem_data[7:0];

	  	                    mem_data[0]<= mem_intf_read_pic.mem_data[0];
          			    mem_wgt[0]<= mem_intf_read_wgt.mem_data[0];

         		 	    mem_data[1]<= mem_intf_read_pic.mem_data[1];
				    mem_wgt[1]<= mem_intf_read_wgt.mem_data[1];

				    mem_data[2]<= mem_intf_read_pic.mem_data[2];
				    mem_wgt[2]<= mem_intf_read_wgt.mem_data[2];

				    mem_data[3]<= mem_intf_read_pic.mem_data[3];
				    mem_wgt[3] <= mem_intf_read_wgt.mem_data[3];

	  	                    mem_data[4]<= mem_intf_read_pic.mem_data[4];
          			    mem_wgt[4]<= mem_intf_read_wgt.mem_data[4];

         		 	    mem_data[5]<= mem_intf_read_pic.mem_data[5];
				    mem_wgt[5]<= mem_intf_read_wgt.mem_data[5];

				    mem_data[6]<= mem_intf_read_pic.mem_data[6];
				    mem_wgt[6]<= mem_intf_read_wgt.mem_data[6];

				    mem_data[7]<= mem_intf_read_pic.mem_data[7];
				    mem_wgt[7] <= mem_intf_read_wgt.mem_data[7];

	  	                    mem_data[8]<= mem_intf_read_pic.mem_data[8];
          			    mem_wgt[8]<= mem_intf_read_wgt.mem_data[8];

         		 	    mem_data[9]<= mem_intf_read_pic.mem_data[9];
				    mem_wgt[9]<= mem_intf_read_wgt.mem_data[9];

				    mem_data[10]<= mem_intf_read_pic.mem_data[10];
				    mem_wgt[10]<= mem_intf_read_wgt.mem_data[10];

				    mem_data[11]<= mem_intf_read_pic.mem_data[11];
				    mem_wgt[11] <= mem_intf_read_wgt.mem_data[11];

	  	                    mem_data[12]<= mem_intf_read_pic.mem_data[12];
          			    mem_wgt[12]<= mem_intf_read_wgt.mem_data[12];

         		 	    mem_data[13]<= mem_intf_read_pic.mem_data[13];
				    mem_wgt[13]<= mem_intf_read_wgt.mem_data[13];

				    mem_data[14]<= mem_intf_read_pic.mem_data[14];
				    mem_wgt[14]<= mem_intf_read_wgt.mem_data[14];

				    mem_data[15]<= mem_intf_read_pic.mem_data[15];
				    mem_wgt[15] <= mem_intf_read_wgt.mem_data[15];

	  	                    mem_data[16]<= mem_intf_read_pic.mem_data[16];
          			    mem_wgt[16]<= mem_intf_read_wgt.mem_data[16];

         		 	    mem_data[17]<= mem_intf_read_pic.mem_data[17];
				    mem_wgt[17]<= mem_intf_read_wgt.mem_data[17];

				    mem_data[18]<= mem_intf_read_pic.mem_data[18];
				    mem_wgt[18]<= mem_intf_read_wgt.mem_data[18];

				    mem_data[19]<= mem_intf_read_pic.mem_data[19];
				    mem_wgt[19] <= mem_intf_read_wgt.mem_data[19];

	  	                    mem_data[20]<= mem_intf_read_pic.mem_data[20];
          			    mem_wgt[20]<= mem_intf_read_wgt.mem_data[20];

         		 	    mem_data[21]<= mem_intf_read_pic.mem_data[21];
				    mem_wgt[21]<= mem_intf_read_wgt.mem_data[21];

				    mem_data[22]<= mem_intf_read_pic.mem_data[22];
				    mem_wgt[22]<= mem_intf_read_wgt.mem_data[22];

				    mem_data[23]<= mem_intf_read_pic.mem_data[23];
				    mem_wgt[23] <= mem_intf_read_wgt.mem_data[23];

	  	                    mem_data[24]<= mem_intf_read_pic.mem_data[24];
          			    mem_wgt[24]<= mem_intf_read_wgt.mem_data[24];

         		 	    mem_data[25]<= mem_intf_read_pic.mem_data[25];
				    mem_wgt[25]<= mem_intf_read_wgt.mem_data[25];

				    mem_data[26]<= mem_intf_read_pic.mem_data[26];
				    mem_wgt[26]<= mem_intf_read_wgt.mem_data[26];

				    mem_data[27]<= mem_intf_read_pic.mem_data[27];
				    mem_wgt[27] <= mem_intf_read_wgt.mem_data[27];

	  	                    mem_data[28]<= mem_intf_read_pic.mem_data[28];
          			    mem_wgt[28]<= mem_intf_read_wgt.mem_data[28];

         		 	    mem_data[29]<= mem_intf_read_pic.mem_data[29];
				    mem_wgt[29]<= mem_intf_read_wgt.mem_data[29];

				    mem_data[30]<= mem_intf_read_pic.mem_data[30];
				    mem_wgt[30]<= mem_intf_read_wgt.mem_data[30];

				    mem_data[31]<= mem_intf_read_pic.mem_data[31];
				    mem_wgt[31] <= mem_intf_read_wgt.mem_data[31];

			
				    fc_done_dp <= 1'b1;
				  

			end
	end//DP -always

//=========================================================================
//ACT:
//	as of right now we get 4 bytes evety time - TODO - change to 32
//=========================================================================
 always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		begin
			mem_intf_write.mem_req <= 1'b0;			
			mem_intf_write.mem_start_addr <= {ADDR_WIDTH{1'b0}};    // First address is zero
			mem_intf_write.mem_size_bytes <= {DP_DEPTH{1'd0}}; 	
			mem_intf_write.mem_data <= 32'd0; 
			counter_line <= {Y_LOG2_ROWS_NUM{1'b0}};
		end	
        else if(state == ACT) 
			begin	
			    mem_intf_write.mem_start_addr <=fc_addrz;
			    mem_intf_write.mem_req<=1'b1;
			    mem_intf_write.mem_size_bytes<=BYTES_TO_WRITE;
			    mem_intf_write.mem_last_valid<= 1'b0;				
				if (data_out_sum + mem_bias > MAX_RELU_VAL) begin 
					mem_intf_write.mem_data<= MAX_RELU_VAL>>NUM_RELU_DESCALE_BITS;
				end
				else if (data_out_sum + mem_bias < 32'd0) begin
					mem_intf_write.mem_data <= {(32-NUM_RELU_DESCALE_BITS){1'd0}};
				end
				else begin
					mem_intf_write.mem_data<= (data_out_sum + mem_bias)>>NUM_RELU_DESCALE_BITS;
				end
		if (mem_intf_write.mem_ack) begin
			counter_32 <= {CNT_32_MAX{1'd0}};
			data_out_sum<=17'd0;
			counter_line <= counter_line+1'b1;
			mem_intf_write.mem_req<=1'b0;
			if (counter_line == Y_ROWS_NUM-1)
				begin
					fc_done <= 1'b1;
				end
			else
				begin
					fc_done <= 1'b0; 
				end	
		end	
	 end
	end//ACT -always



  always @(posedge clk or negedge rst_n) begin
	if (state!=IDLE)
		fc_sw_busy_ind<=1'b1;
	else
		fc_sw_busy_ind<=1'b0;
  end
endmodule
