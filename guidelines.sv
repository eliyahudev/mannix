//======================================================================================================
//Module: guidelines
//Description: the basic guideline for arranged enviroment
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 27-Dec-2020
//======================================================================================================
 1. the reset is asynchronous. for example:
	always @(posedge clk or negedge rst_n)
    if(!rst_n)
        state <= IDLE;
    else
    	...

2. clock name: clk, reset name: rst_n - active low. for example:
	input clk, // Clock
 	input rst_n, // Reset

3. before any push , make sure everything pass compilation, run from rtl dir:
	irun -sv *.sv

4. there is tb dir, there will be the tb and also the <tb_name>.sh file that will contain the command for run the tb.

5. there is workspace dir from there to run the tests.

6. the descriptor of each mudile should be like this

7. names of signals in lowercase letter. names of parameters in uppercase letters.

8. names of moudlues should be with prefix like the unit. 
 for example, this is list of mem unit modules:
 vlsi1:gerners:~/project/mannix2/rtl>ls mem*
 mem_ctrl.sv  mem_intf_read.sv  mem_intf_write.sv  mem_mux_a.sv	mem_mux_b.sv  mem_sram.sv
 same should be for fcc, cnn, pool and active.

9. each module in separate file, with the same name like the module name.
