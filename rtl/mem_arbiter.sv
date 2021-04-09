// -------------------------------------------------------------------------
// File name		: mem_arbiter.sv 
// Title				: 
// Project      	: 
// Developers   	: gerners 
// Created      	: Sun Apr 04, 2021  09:09PM 
// Last modified  : 
// Description  	: 
// Notes        	: 
// Version			: 0.1
// ---------------------------------------------------------------------------
// Copyright 
// Confidential Proprietary 
// ---------------------------------------------------------------------------

module mem_arbiter #(
    parameter PORTS=16 //must be power of 2
    )
    (
	input clk,
	input rst_n,
    input [PORTS-1:0] req,
	output [PORTS-1:0] gnt
    );

	// Find priority - Start from LSB and count upwards, returns 0 when no bit set 
	// the function taken from: https://github.com/bmartini/verilog-arbiter/blob/master/src/arbiter.v
	function automatic [PORTS-1:0] fp (
        input [PORTS-1:0] in
    );
        reg     set;
        integer i;
        begin
            set = 1'b0;
            fp = 'b0;
            for (i = 0; i < PORTS; i = i + 1) begin
                if (in[i] & ~set) begin
                    set = 1'b1;
                    fp[i] = 1'b1;
                end
            end
        end
    endfunction

	logic [$clog2(PORTS)-1:0] current_first;
	logic [PORTS*2-1:0] req_double, fp_double;
	logic [PORTS-1:0] req_to_fp;

	always @(posedge clk or negedge rst_n)
			if (!rst_n) begin
					current_first<='0;
			end
			else if (current_first == PORTS-1)begin 
				current_first<='0;
			end
				else
					current_first<=current_first+1'b1;

	//rotate to the right - shift to right while the most right bits will placed in the MSB
	assign req_double = {req,req};
	assign req_to_fp = req_double[current_first+PORTS-1 -:PORTS];
	//rotate back to the left
	assign fp_double = {fp(req_to_fp),fp(req_to_fp)};
	assign gnt = fp_double[2*PORTS-1-current_first -: PORTS];

endmodule
		

