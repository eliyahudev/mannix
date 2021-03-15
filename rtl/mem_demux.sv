//======================================================================================================
//Module: mem_demux
//Description: get the data from the ddr/sw and send it to the appropriate sram
//the output can be to two srams or four srams
//Design Unit Owner : Simhi Gerner
//Original Author   : Simhi Gerner
//Original Date     : 12-Jan-2021
//======================================================================================================
//TODO the send the data to the right sram, now the data send to all instead for just the 
//two relevant srams - done 
module mem_demux 
	(
	input clk, // Clock
 	input rst_n, // Reset
	input [15:0][255:0] data_in,
	input data_valid, //must be valid just for one cycle
	input [18:0] base_addr,
	input last,
	input [3:0] num_of_last_valid,
	output logic [15:0] cs,
	output logic [15:0][255:0] data_out,
	output logic [15:0][18:0] addr_sram,
	output logic demux_busy
	);
	enum logic {IDLE, ACTIVE} state,next_state;
	logic done;
	logic out_to_four;
	logic [3:0]num_data_beat_out, num_data_beat_out_comb;
	logic [18:0] int_base_addr, r_base_addr;
	logic [15:0][255:0] int_data_in, r_data_in;
	logic [18:0] addr_plus_1, addr_plus_2;
	logic [15:0] cs_comb;
	logic [15:0][18:0] addr_sram_comb;
	logic [18:0] bank0_addr, bank1_addr, bank2_addr, bank3_addr;
	logic [3:0] bank0_index, bank1_index, bank2_index, bank3_index;

	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			num_data_beat_out<='0;
		end
		else if (data_valid)
				if (out_to_four)
					num_data_beat_out<=4'd4;
				else
					num_data_beat_out<=4'd2;					
			else
				if (out_to_four) 
					num_data_beat_out<=num_data_beat_out + 3'd4;
				else
					num_data_beat_out<=num_data_beat_out + 2'd2;

	assign done = out_to_four ? num_data_beat_out==4'd12 && state==ACTIVE : num_data_beat_out==4'd14 && state==ACTIVE;

	assign int_base_addr = data_valid ? base_addr : r_base_addr;
	assign int_data_in = data_valid ? data_in : r_data_in;
	//the shift because the [4:0] bits are in the 32B of the size of the address
	assign addr_plus_1 = int_base_addr + (num_data_beat_out + 1'b1)<<3'd5;
	assign addr_plus_2 = int_base_addr + (num_data_beat_out + 2'd2)<<3'd5;

	//if the 16th bit that represent two banks (one even and one odd) differnt, it mean that the addresses go through four banks
	//de-feature to the out_to_four, it's not work yet, a lot of work, a very little benefit. 
	assign out_to_four ='0; //addr_plus_1[16]!=addr_plus_2[16] && num_data_beat_out!=4'd14;
	assign num_data_beat_out_comb = data_valid ? 4'd0 : num_data_beat_out;

	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			demux_busy<='0;
		end
		else if (next_state==IDLE || done) begin
			demux_busy<=1'b0;
		end
			else
				demux_busy<=1'b1;
	
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			state<=IDLE;
		end
		else begin
			state<=next_state;
		end
	//transitions for the FSM
	always_comb 
		case (state)
			IDLE:
				if (data_valid)
					next_state=ACTIVE;
				else
					next_state=IDLE;
			ACTIVE:
				if (done)
					if (data_valid)
						next_state=ACTIVE;
					else
						next_state<=IDLE;
				else
					next_state=ACTIVE;
		endcase

	//sample the data in the first cycle
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			r_data_in<='0;
			r_base_addr='0;
		end
		else if (data_valid)begin
			r_data_in<=data_in;
			r_base_addr=base_addr;
		end
	//choose the bank
	always_comb
		begin
			bank0_addr = int_base_addr + (num_data_beat_out_comb)<<3'd5;
			bank1_addr = int_base_addr + (num_data_beat_out_comb+1'b1)<<3'd5;
			bank2_addr = int_base_addr + (num_data_beat_out_comb+2'd2)<<3'd5;
			bank3_addr = int_base_addr + (num_data_beat_out_comb+2'd3)<<3'd5;
			bank0_index = {bank0_addr[18:16],bank0_addr[5]};
			bank1_index = {bank1_addr[18:16],bank1_addr[5]};
			bank2_index = {bank2_addr[18:16],bank2_addr[5]};
			bank3_index = {bank3_addr[18:16],bank3_addr[5]};
		end
	//choose the addr
	always_comb begin
			addr_sram_comb='0;
			if (state==ACTIVE || next_state==ACTIVE) begin
			//the 15th bit and the 5th bit swap their location
			addr_sram_comb[bank0_index]={bank0_addr[18:16],bank0_addr[5],bank0_addr[15:6],bank0_addr[4:0]};
			addr_sram_comb[bank1_index]={bank1_addr[18:16],bank1_addr[5],bank1_addr[15:6],bank1_addr[4:0]};
			if (out_to_four)begin
				addr_sram_comb[bank2_index]={bank2_addr[18:16],bank2_addr[5],bank2_addr[15:6],bank2_addr[4:0]};
				addr_sram_comb[bank3_index]={bank3_addr[18:16],bank3_addr[5],bank3_addr[15:6],bank3_addr[4:0]};
			end
		end
	end

	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			addr_sram<='0;
		end
		else begin
			addr_sram<=addr_sram_comb;
		end
	//choose the cs by combinatorical logic - 2 or 4	
	always_comb
		begin
		cs_comb='0;
		if (state==ACTIVE ||next_state==ACTIVE) begin
				cs_comb[addr_sram_comb[bank0_index][18:15]]=1'b1;
				cs_comb[addr_sram_comb[bank1_index][18:15]]=1'b1;
				if (out_to_four) begin
					cs_comb[addr_sram_comb[bank2_index][18:15]]=1'b1;
					cs_comb[addr_sram_comb[bank3_index][18:15]]=1'b1;
				end
			end
		end

	//out the flop cs	
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			cs<='0;
		end
		else begin
			cs<=cs_comb;
		end
	//the data out
	genvar i;
	generate
		for (i=0; i < 16; i++) begin: loop
			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					data_out[i]<='0;
				end
				else if (out_to_four) begin
						if (cs_comb[i]==1'b1)
							data_out[i]=int_data_in[num_data_beat_out_comb+i[1:0]];//TODO fix this, it not always correct
					end
					else if (cs_comb[i]==1'b1)
						if (addr_sram_comb[bank0_index][15]==1'b0) begin //the first bank is even
							data_out[i]=int_data_in[num_data_beat_out_comb+i[0]];
						end
						else if (i[0]==1) //the first bank is odd
								data_out[i]=int_data_in[num_data_beat_out_comb];
							else
								data_out[i]=int_data_in[num_data_beat_out_comb+1];
					end
	endgenerate

				//assertions
				no_valid_in_active: assert property (@(posedge clk)disable iff (!rst_n) state==ACTIVE && !done |-> !data_valid);
endmodule

/*			if (next_state==ACTIVE)
				if (out_to_four)begin
					addr_sram_comb[num_data_beat_out_comb] = int_base_addr + (num_data_beat_out_comb)<<3'd5;
					addr_sram_comb[num_data_beat_out_comb+1'b1] = int_base_addr + (num_data_beat_out_comb+1'b1)<<3'd5;
					addr_sram_comb[num_data_beat_out_comb+2'd2] = int_base_addr + (num_data_beat_out_comb+2'd2)<<3'd5;
					addr_sram_comb[num_data_beat_out_comb+2'd3] = int_base_addr + (num_data_beat_out_comb+2'd3)<<3'd5;
					//the 15th bit and the 5th bit swap their location
					addr_sram_comb[num_data_beat_out_comb] = {addr_sram_comb[num_data_beat_out_comb][18:16],addr_sram_comb[num_data_beat_out_comb][5]
					,addr_sram_comb[num_data_beat_out_comb][14:6],addr_sram_comb[num_data_beat_out_comb][15],addr_sram_comb[num_data_beat_out_comb][4:0]};
					addr_sram_comb[num_data_beat_out_comb+1'b1] = {addr_sram_comb[num_data_beat_out_comb+1'b1][18:16],addr_sram_comb[num_data_beat_out_comb+1'b1][5]
					,addr_sram_comb[num_data_beat_out_comb+1'b1][14:6],addr_sram_comb[num_data_beat_out_comb+1'b1][15],addr_sram_comb[num_data_beat_out_comb+1'b1][4:0]};
					addr_sram_comb[num_data_beat_out_comb+2'd2] = {addr_sram_comb[num_data_beat_out_comb+2'd2][18:16],addr_sram_comb[num_data_beat_out_comb+2'd2][5]
					,addr_sram_comb[num_data_beat_out_comb+2'd2][14:6],addr_sram_comb[num_data_beat_out_comb+2'd2][15],addr_sram_comb[num_data_beat_out_comb+2'd2][4:0]};
					addr_sram_comb[num_data_beat_out_comb+2'd3] = {addr_sram_comb[num_data_beat_out_comb+2'd3][18:16],addr_sram_comb[num_data_beat_out_comb+2'd3][5]
					,addr_sram_comb[num_data_beat_out_comb+2'd3][14:6],addr_sram_comb[num_data_beat_out_comb+2'd3][15],addr_sram_comb[num_data_beat_out_comb+2'd3][4:0]};
				end
				else begin
					addr_sram_comb[num_data_beat_out_comb] = int_base_addr + (num_data_beat_out_comb)<<3'd5;
					addr_sram_comb[num_data_beat_out_comb+1'b1] = int_base_addr + (num_data_beat_out_comb+1'b1)<<3'd5;
					//the 15th bit and the 5th bit swap their location
					addr_sram_comb[num_data_beat_out_comb] = {addr_sram_comb[num_data_beat_out_comb][18:16],addr_sram_comb[num_data_beat_out_comb][5]
					,addr_sram_comb[num_data_beat_out_comb][14:6],addr_sram_comb[num_data_beat_out_comb][15],addr_sram_comb[num_data_beat_out_comb][4:0]};
					addr_sram_comb[num_data_beat_out_comb+1'b1] = {addr_sram_comb[num_data_beat_out_comb+1'b1][18:16],addr_sram_comb[num_data_beat_out_comb+1'b1][5]
					,addr_sram_comb[num_data_beat_out_comb+1'b1][14:6],addr_sram_comb[num_data_beat_out_comb+1'b1][15],addr_sram_comb[num_data_beat_out_comb+1'b1][4:0]};
				end
*/
