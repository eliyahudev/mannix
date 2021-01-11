module fifo 
	#(parameter FIFO_DEPTH=16 ,
	FIFO_WIDTH=8,
	RD_ADDR=$clog2(FIFO_DEPTH))
	(
 	input clk, // Clock
 	input rst_n, // Reset
 	// Write Port
	input write_en, // Write enable
	input [FIFO_WIDTH-1:0] data_in, // FIFO Input Data
 	output empty, // FIFO empty indication
	// Read Port
	output logic [RD_ADDR-1:0]cnt,
	input read_en, // Read enable
	output full, // FIFO full indication
	output reg [FIFO_WIDTH-1:0] data_out // FIFO Output Data
	); 
	logic [FIFO_DEPTH-1:0][FIFO_WIDTH-1:0] mem;
	logic [RD_ADDR-1:0] count,rptr,wptr;

	//count
	always_ff @(posedge clk)
		if (!rst_n)begin
			count<='0;
			rptr<='0;
			wptr<='0;
//			data_out<='0;
		end
		else begin
			count<=count + write_en - read_en;
			if (write_en)
				if(wptr==FIFO_DEPTH-1)
					wptr<='0;
				else 
					wptr<=wptr+1'b1;
			if (read_en)begin
//				data_out<=mem[rptr];
				if(rptr==FIFO_DEPTH-1)
					rptr<='0;
				else
					rptr<=rptr+1'b1;
			end	
		end

//write
	always_ff @(posedge clk)
		if (write_en)
			mem[wptr]<= data_in;
	assign full = (count==FIFO_DEPTH) ? 1 : 0;
	assign data_out=mem[rptr];
	assign empty = (count==0) ? 1 : 0;
	assign cnt = count;

endmodule

		
