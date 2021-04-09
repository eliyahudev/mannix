//======================================================================================================
// Module: mem_arbiter_tb
// Description: basic tb for the arbiter:.
// Design Unit Owner : Simhi Gerner                   
// Original Author   : Simhi Gerner
// Original Date     : 13-Jan-2021
//======================================================================================================



module mem_arbiter_tb ();

	parameter PORTS=16;
	logic clk;
	logic rst_n;
	//port for memory
	logic [PORTS-1:0] req, gnt;
	 

	mem_arbiter  i_mem_arbiter (
		.clk(clk),
		.rst_n(rst_n),
		.req(req),
		.gnt(gnt)
	);
 

	always #5 clk = !clk;

	
	initial begin
		$monitor("time=%3d, rst_n=%b, req=%h, gnt=%h \n",$time,rst_n,req,gnt);
		//initial values and reset
      	clk= 1'b1;
      	rst_n = 1'b0;
		req = 1'b0;
		#15 rst_n=1'b1;
		#5 req[0]=1'b1;
		#10 req[1]=1'b1;
		#20 req=16'hfff0;
		#10 req=16'hffff;
		#200
      	$finish();
    end
 
  endmodule
