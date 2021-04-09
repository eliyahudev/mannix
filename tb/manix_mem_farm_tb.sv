//======================================================================================================
// Module: manix_mem_farm_tb
// Description: basic tb for the memory:.
// Design Unit Owner : Simhi Gerner                   
// Original Author   : Simhi Gerner
// Original Date     : 13-Jan-2021
//======================================================================================================



module manix_mem_farm_tb ();

	parameter WORD_WIDTH=8;
	parameter NUM_WORDS_IN_LINE=32;
	parameter ADDR_WIDTH=19;
	logic clk;
	logic rst_n;
	//port for memory
	logic [31:0] read_addr_ddr;
	logic read_from_ddr;
	logic write_to_ddr;
	logic [31:0] write_addr_ddr;
	logic [4:0]  client_priority;
	logic [18:0] read_addr_sram;
	logic [18:0] write_addr_sram;
	logic odd;
	integer which_part, which_bank, which_addr,mem_start_addr_fixed;
	logic [16383:0][255:0] values_of_memory;
	logic mem_ack;
  
  	//interfaces
  	mem_intf_read mem_intf_read_wgt_fcc();
	mem_intf_read mem_intf_read_pic_fcc();
	mem_intf_read mem_intf_read_bias_fcc();
  	mem_intf_write mem_intf_write_fcc();
  	mem_intf_write mem_intf_write_pool();
  	mem_intf_read mem_intf_read_mx_pool();
  	mem_intf_write mem_intf_write_cnn();
  	mem_intf_read mem_intf_read_pic_cnn();
  	mem_intf_read mem_intf_read_wgt_cnn();
	mem_intf_read #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256))  read_ddr_req();
	mem_intf_write #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256)) write_ddr_req ();
	mem_intf_write #(.ADDR_WIDTH(32),.NUM_WORDS_IN_LINE(16), .WORD_WIDTH(256)) write_sw_req ();
 

	mannix_mem_farm i_mannix_mem_farm (
		.clk(clk),
		.rst_n(rst_n),
		.fcc_pic_r(mem_intf_read_pic_fcc),
		.fcc_wgt_r(mem_intf_read_wgt_fcc),
		.fcc_bias_r(mem_intf_read_bias_fcc),
		.cnn_pic_r(mem_intf_read_pic_cnn),
		.cnn_wgt_r(mem_intf_read_wgt_cnn),
		.pool_r(mem_intf_read_mx_pool),
		.fcc_w(mem_intf_write_fcc),
		.pool_w(mem_intf_write_pool),
		.cnn_w(mem_intf_write_cnn),
		.read_addr_ddr(read_addr_ddr),
		.read_from_ddr(read_from_ddr),
		.write_to_ddr(write_to_ddr),
		.write_addr_ddr(write_addr_ddr),
		.client_priority(client_priority),
		.read_ddr_req(read_ddr_req),
		.write_ddr_req(write_ddr_req),
		.read_addr_sram(read_addr_sram),
		.write_addr_sram(write_addr_sram),
		.write_sw_req(write_sw_req)
	);
 

	always #5 clk = !clk;

	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			mem_ack<='0;
		end
		else if(write_sw_req.mem_ack)
				mem_ack<=1'b1;
			else
				mem_ack<=1'b0;

	initial begin
		//initial values and reset
      	clk= 1'b1;
      	rst_n = 1'b0;
      	write_to_ddr=1'b0;
      	read_from_ddr=1'b0;
      	mem_intf_read_mx_pool.mem_req=0;
      	mem_intf_read_wgt_cnn.mem_req=0;
		mem_intf_read_mx_pool.mem_start_addr=0;
      	mem_intf_read_wgt_cnn.mem_start_addr=0;
      	read_ddr_req.mem_valid=1'b0;
      	write_addr_sram=0;
      	write_sw_req.mem_req=1'b0;
      	write_sw_req.last=1'b1;
      	write_sw_req.mem_last_valid = 1'b0;
      	#31 rst_n= 1'b1;
      	//send req and data
      	#19
//////////////////////////////////////////////////////////
//             part 1                 					//
//writing to addresses 0-15 the values 0-15 respectively//
//////////////////////////////////////////////////////////
		//send req and data
		write_sw_req.mem_req=1'b1;
		write_sw_req.mem_start_addr=1'b0;
		$display("writing to addresses 0-15 the values 0-15 respectively");
		for (int j=0; j < 16; j++) begin
			write_sw_req.mem_data[j]=j;
		end
	
		wait (write_sw_req.mem_ack==1'b1) @(posedge clk)
		write_sw_req.mem_req=1'b0; 
		#130
		$display("check for correct values");
		for (int i=0; i < 16; i++) begin
			if (i[0]==0)
				odd=0;
			else
				odd=1;
			which_part= i/2048;
			which_bank=which_part*2+odd;
			which_addr=((i+write_sw_req.mem_start_addr)%2048-odd)/2;
			//check for fail
			if (manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:255]!=write_sw_req.mem_data[i])begin
				$display("TEST FAIL\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
				$finish();
			end
			else
				$display("check passed\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
		end
		$display("PASS");
////////////////////////////////////////////
//                 part 2                 //
//writing to addresses 1-16 random numbers//
////////////////////////////////////////////
		#10
		//send req and data
		write_sw_req.mem_req=1'b1;
		write_sw_req.mem_start_addr=1'b1;
		$display("writing to addresses 1-16 random numbers");
		for (int j=0; j < 16; j++) begin
			write_sw_req.mem_data[j]=$urandom;
		end
	
		wait (write_sw_req.mem_ack==1'b1) @(posedge clk)
		write_sw_req.mem_req=1'b0; 
		#130
		$display("check for correct values");
		for (int i=0; i < 16; i++) begin
			if ((i+write_sw_req.mem_start_addr)%2==0)
				odd=0;
			else
				odd=1;
			which_part= (i+write_sw_req.mem_start_addr)/2048;
			which_bank=which_part*2+odd;
			which_addr=((i+write_sw_req.mem_start_addr)%2048-odd)/2;
			//check for fail
			if (manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:255]!=write_sw_req.mem_data[i])begin
				$display("TEST FAIL\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
				$finish();
			end
			else
				$display("check passed\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
		end
		$display("PASS");
/////////////////////////////////////////////////////////////////
//                         part 3                              //
//writing to addresses 2045-2060 the values 0-15 respectively //
////////////////////////////////////////////////////////////////
		#10
		//send req and data
		write_sw_req.mem_req=1'b1;
		write_sw_req.mem_start_addr=2045;
		$display("writing to addresses 2045-2060 the values 0-15 respectively");
		for (int j=0; j < 16; j++) begin
			write_sw_req.mem_data[j]=j;
		end
	
		wait (write_sw_req.mem_ack==1'b1) @(posedge clk)
		write_sw_req.mem_req=1'b0; 
		#130
		$display("check for correct values");
		for (int i=0; i < 16; i++) begin
			if ((i+write_sw_req.mem_start_addr)%2==0)
				odd=0;
			else
				odd=1;
			which_part= (i+write_sw_req.mem_start_addr)/2048;
			which_bank=which_part*2+odd;
			which_addr=((i+write_sw_req.mem_start_addr)%2048-odd)/2;
			//check for fail
			if (manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:255]!=write_sw_req.mem_data[i])begin
				$display("TEST FAIL\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
				$finish();
			end
			else
				$display("check passed\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
		end
		$display("PASS");
///////////////////////////////////////////////////////////////////////////////////////////
//                                        part 4                                         //
// writing to addresses 2045-2076 the values 0-31 respectively req after req immedietly //
//////////////////////////////////////////////////////////////////////////////////////////
		#10
		//send req and data
		write_sw_req.mem_req=1'b1;
		write_sw_req.mem_start_addr=2045;
		$display("writing to addresses 2045-2076 the values 0-31 respectively req after req immedietly");
		for (int j=0; j < 16; j++) begin
			write_sw_req.mem_data[j]=j;
			values_of_memory[j]=write_sw_req.mem_data[j];
		end
		wait (mem_ack) @(posedge clk)
		write_sw_req.mem_start_addr=write_sw_req.mem_start_addr+16;
		for (int j=0; j < 16; j++) begin
			write_sw_req.mem_data[j]=j+16;
			values_of_memory[16+j]=write_sw_req.mem_data[j];
		end
		write_sw_req.mem_req=1'b1;
		wait (mem_ack) @(posedge clk)
		write_sw_req.mem_req=1'b0;
		#130
		$display("check for correct values");
		for (int i=0; i < 32; i++) begin
			if ((i+write_sw_req.mem_start_addr-16)%2==0)
				odd=0;
			else
				odd=1;
			which_part= (i+write_sw_req.mem_start_addr-16)/2048;
			which_bank=which_part*2+odd;
			which_addr=((i+write_sw_req.mem_start_addr-16)%2048-odd)/2;
			//check for fail
			if (manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:255]!=values_of_memory[i])begin
				$display("TEST FAIL\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,values_of_memory[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
				$finish();
			end
			else
				$display("check passed\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,values_of_memory[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
		end
		$display("PASS");
////////////////////////////////////////////////////////////////////////////////////
//                                part 5                                          //
// writing to all the memory start from addr 0 with numbers in increasing order   //
////////////////////////////////////////////////////////////////////////////////////
		#10
		//send req and data
		write_sw_req.mem_req=1'b1;
		write_sw_req.mem_start_addr=0;
		$display("writing to all the memory start from addr 0 with numbers in increasing order");
		for (int i=0; i < 1023; i++) begin
			for (int j=0; j < 16; j++) begin
				write_sw_req.mem_data[j]=i*16+j;
				values_of_memory[i*16+j]=write_sw_req.mem_data[j];
			end
			wait (write_sw_req.mem_ack==1'b1) @(posedge clk)
			write_sw_req.mem_start_addr=write_sw_req.mem_start_addr+16;
		end
			for (int j=0; j < 16; j++) begin
				write_sw_req.mem_data[j]=1023*16+j;
				values_of_memory[1023*16+j]=write_sw_req.mem_data[j];
			end
			write_sw_req.mem_req=1'b1;
			wait (write_sw_req.mem_ack==1'b1) @(posedge clk)
			write_sw_req.mem_req=1'b0;
			#130
			$display("check for correct values");
		for (int i=0; i < 16384; i++) begin
			if ((i+write_sw_req.mem_start_addr)%2==0)
				odd=0;
			else
				odd=1;
			which_part= (i+write_sw_req.mem_start_addr)/2048;
			which_bank=which_part*2+odd;
			which_addr=((i+write_sw_req.mem_start_addr)%2048-odd)/2;
			//check for fail
			if (manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:255]!=write_sw_req.mem_data[i])begin
				$display("TEST FAIL\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
				$finish();
			end
			else
				$display("check passed\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
		end
		$display("PASS");
/////////////////////////////////////////////////////////////////////////////
//                                    part 6                               //
//   writing to all the memory (except the first and the 15 last addresses)// 
//  start from addr 1 with numbers in increasing order                     //
/////////////////////////////////////////////////////////////////////////////
/*
		#10
		//send req and data
		write_sw_req.mem_req=1'b1;
		write_sw_req.mem_start_addr=1'b1;
		mem_start_addr_fixed=write_sw_req.mem_start_addr;
		$display("writing to all the memory (except the first and the 15 last addresses) start from addr 1 with numbers in increasing order");
		for (int i=0; i < 1022; i++) begin
			for (int j=0; j < 16; j++) begin
				write_sw_req.mem_data[j]=i*16+j;
				values_of_memory[i*16+j]=write_sw_req.mem_data[j];
			end
			wait (write_sw_req.mem_ack==1'b1) @(posedge clk)
			write_sw_req.mem_start_addr=write_sw_req.mem_start_addr+16;
		end
			for (int j=0; j < 16; j++) begin
				write_sw_req.mem_data[j]=1022*16+j;
				values_of_memory[1022*16+j]=write_sw_req.mem_data[j];
			end
			write_sw_req.mem_req=1'b1;
			wait (write_sw_req.mem_ack==1'b1) @(posedge clk)
			write_sw_req.mem_req=1'b0;
			#130
			$display("check for correct values");
		for (int i=0; i < 16368; i++) begin
			if ((i+mem_start_addr_fixed)%2==0)
				odd=0;
			else
				odd=1;
			which_part= (i+mem_start_addr_fixed)/2048;
			which_bank=which_part*2+odd;
			which_addr=((i+mem_start_addr_fixed)%2048-odd)/2;
			//check for fail
			if (manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:255]!=values_of_memory[i])begin
				$display("TEST FAIL\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,values_of_memory[i],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
				$finish();
			end
			else
				$display("check passed\nloop=%d bank=%d, addr=%d \n expected:%d, actual:%d",
				i,which_bank,which_addr,write_sw_req.mem_data[i][31:0],manix_mem_farm_tb.i_mannix_mem_farm.debug_mem[which_bank][which_addr*256+:31]);
		end
		$display("PASS");
		*/
		$display("TEST PASS");
      	$finish();
    end
 
  endmodule
