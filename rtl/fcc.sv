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
		mem_intf_write,
		last
			);
//======================================================================================================
//
// Inputs\Outputs
//
// Owner : Dor Shilo 
//                    
// Inputs:
//		1) fc_addrx - 32 bits - Data Vector start address 			   - 0x0040
//		2) fc_addry - 32 bits - Weights matrix start address    	           - 0x0044
//		3) fc_addrb - 32 bits - Bias vector start address 		   	   - 0x
//		4) fc_xm    - 32 bits - Data vector input length 			   - 0x004B
//		5) fc_ym    - 32 bits - Weights matrix input length 			   - 0x0050
//		6) fc_yn    - 32 bits - Weights matrix input width		   	   - 0x0054
//		7) cnn_bn   - 32 bits - Bias vector input length			   - 0x0058
//		8) fc_go		- 1 bit   - Alerting the the adresses are in place	   - 0x
// 
// Outputs:
//		1) fc_addrz	        - 32 bits - Z matrix start address 		   - 0x0048
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
//======================================================================================================

//======================================================================================================
//
// Alfc_gorithem
//
//	The module is a state machine:
//	  
//		1) IDLE - The module is waiting for signal fc_go = all adresses are in place.
//		2) REQ  - The module will put out a request for data and weighes.
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
  input 		clk;

  input [31:0] 		fc_addrx; 
  input [31:0] 		fc_addry;
  input [31:0] 		fc_addrb;
  input [31:0] 		fc_xm;
  input [31:0] 		fc_ym;
  input [31:0] 		fc_yn;
  input [31:0] 		cnn_bn;
  input 		fc_go;
  
  input 		rst_n;
   

  output [31:0] 	fc_addrz;
  output reg		fc_done;
  output reg            fc_sw_busy_ind;
//======================================================================================================
	// HW accelerator Parameters
//======================================================================================================
	  parameter ADDR_WIDTH=12; //TODO: check width
	 // parameter MAX_BYTES_TO_RD=20;
	 // parameter LOG2_MAX_BYTES_TO_RD=$clog2(MAX_BYTES_TO_RD);  
	 //parameter MAX_BYTES_TO_WR=5;  
	 //parameter LOG2_MAX_BYTES_TO_WR=$clog2(MAX_BYTES_TO_WR);
	 // parameter MEM_DATA_BUS=128;

	  parameter DP_DEPTH = 4;
//======================================================================================================
// Data and weights simulation 
//======================================================================================================
  reg [7:0] mem_data   [DP_DEPTH-1:0]; //Simulating the memory data - 8 values of 8 bit
  reg [7:0] mem_wgt    [DP_DEPTH-1:0];//Simulating the memory weights - 8x8 values of 8 bit
  


//======================================================================================================
// Interface instanciation 
//======================================================================================================
// -----Weights-----
 mem_intf_read.client_read 	mem_intf_read_wgt ;
//  -----Data-----
 mem_intf_read.client_read 	mem_intf_read_pic ;
//  -----Write-----
 mem_intf_write.client_write 	mem_intf_write  ;
// -----last-------
mem_intf_write.client_read 	last  ;

	


//======================================================================================================
// Grants
//======================================================================================================


//======================================================================================================
//sm allocation
//======================================================================================================
 parameter IDLE = 2'b00;
 parameter REQ  = 2'b01;
 parameter DP   = 2'b10;
 parameter ACT  = 2'b11;
 reg [1:0] state,next_state; // state
 reg [$clog2(32) - 1 : 0] counter_32; //counting 32 dot product 

////====================================================================================================
//SM states and moves
//======================================================================================================

wire [16:0] dp_res;
dot_product_parallel #(.DEPTH(DP_DEPTH)) 
dp_pll_ins(.a(mem_data), .b(mem_wgt), .res(dp_res)); 
reg [17:0] data_out_sum ;

////====================================================================================================
//SM states and moves
//======================================================================================================
 always @(*) begin
	case (state)
	  IDLE: begin
		if(fc_go)
			begin
				next_state = REQ;
			end		
		else
			begin
				next_state = IDLE;
			end
		end//IDLE
	REQ: begin
		   	if((read_w.gnt)&&(read_d.gnt))
   				begin 
					next_state = DP;
				end
			else 
				begin
					next_state = REQ;
				end

		  end//REQ	

	DP: begin
		 if (counter_32 == {$clog2(32) - 1 , 1'd0 })
				begin
					next_state = REQ;
				end	
		else
			if (counter_32 == 6'd32  )
				begin
					next_state = ACT;
				end		
		else
				next_state = DP;
		end
	ACT: begin
			next_state = (~mem_intf_write.mem_gnt) ? ACT : (fc_done ? IDLE : DP) ;		 
	     end

 endcase
end
 //----------SM-------------------------------------------------------------------
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
			data_out_sum <= 32'd0;
			counter_32 = {$clog2(32) - 1 ,1'd0} ;
		 	fc_sw_busy_ind <= 1'b0;

			mem_intf_write.mem_req <= 1'b0;
			mem_intf_write.mem_start_addr <= {ADDR_WIDTH{1'b0}};
			mem_intf_write.mem_size_bytes <= 'd0; 			//NOT DETRMINED YET 
			mem_intf_write.last<= 1'b0;
			mem_intf_write.mem_data <= 8'd0;			// Assuming each data is 8 bits
			mem_intf_write.mem_last_valid<= 1'b0;
			//------PIC-------
			mem_intf_read_pic.mem_req<=1'b0;
			mem_intf_read_pic.mem_start_addr<={ADDR_WIDTH{1'b0}};
			mem_intf_read_pic.mem_size_bytes<='d0; 			// NOT DETERMINED YET

			mem_intf_read_wgt.mem_req<=1'b0;
			mem_intf_read_wgt.mem_start_addr<={ADDR_WIDTH{1'b0}};
			mem_intf_read_wgt.mem_size_bytes<='d0; 			// NOT DETERMINED YET
		end
 	else if(state == IDLE)	
		begin	
			//Do nothing
		end
	else if(state == REQ )
		begin
			// initiallize data
			mem_intf_read_pic.mem_req <=1'b1;
			mem_intf_read_pic.mem_start_addr <= fc_addrx;
			mem_intf_read_pic.mem_size_bytes <= DP_DEPTH;
			// initiallize weights
			mem_intf_read_wgt.mem_req <=1'b1;
			mem_intf_read_wgt.mem_start_addr <= fc_addrx;
			mem_intf_read_wgt.mem_siSze_bytes <= DP_DEPTH;			

			//request data and weights
			mem_data    <= mem_intf_read_pic.mem_req;
			mem_wgt <= mem_intf_read_wgt.mem_req;
	
		end
		
        else if(state == DP) 
			begin
	  	                    mem_data[0]<= mem_intf_read_pic.mem_data[7:0];
          			    mem_wgt[0]<= mem_intf_read_wgt.mem_data[7:0];

         		 	    mem_data[1]<= mem_intf_read_pic.mem_data[7:0];
				    mem_wgt[1]<= mem_intf_read_wgt.mem_data[7:0];

				    mem_data[2]<= mem_intf_read_pic.mem_data[7:0];
				    mem_wgt[2]<= mem_intf_read_wgt.mem_data[7:0];

				    mem_data[3]<= mem_intf_read_pic.mem_data[7:0];
				    mem_wgt[3] <= mem_intf_read_wgt.mem_data[7:0];
				//dot product doing his calculation and putting them in data_out
				data_out_sum <= data_out_sum + dp_res;
				//if (fc_done_dp) begin
					counter_32 <= counter_32 + {$clog2(32) - 1 ,1'd1};
				//end

			end	
        else if(state == ACT) 
			begin	
				if (last) begin
					fc_done <= 1'b1;
					mem_intf_write.data_out_sum ;
					end
				else if (data_out_sum > 32'd0) begin
					mem_intf_write.data_out_sum ;//Not sure how to write out yet
					end

				else begin
					//?mem_data <= 32'd0;
					mem_intf_write.data_out_sum ;//TODO - change to mem_data of zero ;
				end

			counter_32 <= {$clog2(32) - 1 ,1'd0};

			end	

	end
endmodule
