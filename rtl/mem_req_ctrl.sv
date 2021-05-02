// -------------------------------------------------------------------------
// File name		: mem_req_ctrl.sv 
// Title				: 
// Project      	: 
// Developers   	: gerners 
// Created      	: Thu Apr 08, 2021  09:16PM 
// Last modified  : 
// Description  	: 
//				   There is an FSM that determine the following things:
//				   Which sram(s) the address belongs to.
//				   If to send one or two requests (when the address doesn’t align with the start of the line).
//				   If the data that come from the sram should be shifted to the right.
//				   In case of read data that does not align, the remaining data stored in the temp_buf
//				   If the required data stored in the temp_buf.
//				   When the data ready (can be full bus of 32 bytes or part of the bus with unknown bytes).
//				   When the data was written (ack).
//				   When there is a need to write to less than full line, read requests sent with mask.
//				   When there are two requests to the srams from one client request, because the requests are to different srams, the requests will sent simultaneously.
// Notes        	: 
// Version			: 0.2
// ---------------------------------------------------------------------------
// Copyright 
// Confidential Proprietary 
// ---------------------------------------------------------------------------
`include "mem_intf.svh"
module mem_req_ctrl 
	(
	// outputs, inputs
	input clk,
	input rst_n,
	input req_ctrl_in_s [15:0] intf_in, //struct with the input of the read and/or write interface
	input [15:0] [15:0] gnt, //the gnt that return from the arbiter
	input [15:0][255:0] data_in,// the data that come from, the srams
	output logic [15:0][255:0] data_out, //the data that sent to the srams
	output logic [15:0] req_sram, //activate the appropriate sram (cs). of course, that just after gnt.
	output req_ctrl_out_s [15:0] intf_out, //struct with the output of the read and/or write interface
	output logic [15:0][15:0] req, //the reqs that sent to the srams, every req_ctrl (there is 16) can send req to each of the srams
	output logic [15:0] mask_enable, // is the srams should use in mask for writing
	output logic [15:0][255:0] mask, //the mask in resulotion of bits
	output logic [15:0][18:0] addr_to_sram, // the addr that sent to the sram after adjusting to the memory structure
	output logic [15:0] read, write // is read or write from the sram
	);

	// -------------------------------------------------------------------------
	//  declarations
	// -------------------------------------------------------------------------
	/*AUTOLOGIC*/
	logic [15:0] read_prior; //is read or write in priority
	logic [15:0][3:0] which_sram, read_sram, write_sram, which_sram_sec; //wich number of the sram the addres belong to, sec - second req 
	logic [15:0][3:0] which_sram_s, which_sram_sec_s; //sample these signal for map the data when it's come
	logic [15:0] two_read_req, two_write_req;//is two req neccessery
	logic [15:0] data_read_align, data_read_align_s, data_write_align; //is the addr aligned with the start od the line
	logic [15:0][511:0] temp_buf; //temporary buf, conatain the data that came from the sram and not written to the clients
	logic [15:0][5:0] num_bytes_temp_buf,num_bytes_temp_buf_prev; //the number of the bytes that stored ib the temp_buf
	logic [15:0][18:0] addr_temp_buf,addr_temp_buf_prev;//the address that stored in the temp_buf
	logic [15:0] req_data_stored_temp_buf, req_data_stored_temp_buf_s;//is the data for the first req exsist in the temp_buf
	logic [15:0] two_read_req_need_one; //there are two req for the memory but the data for the first req exsit in the temp_buf
	logic [15:0] first_read_gnt, first_write_gnt, second_read_gnt, second_write_gnt;// pulse when the gnt came or the data for the first read request exist in the temp_buf
	logic [15:0] first_read_gnt_s, first_write_gnt_s, second_read_gnt_s, second_write_gnt_s;//sampling the gnt for use in the next cycle
	logic [15:0][1:0] read_gnt_cnt, read_gnt_cnt_s, write_gnt_cnt; //counter of the gnt : plus 1 for the first_req, plus 2 for the second req  
	logic [15:0][255:0] first_data_out, second_data_out; //the data to send to the srams 
	logic [15:0][8:0] num_bytes_first_data_out, num_bytes_second_data_out; //the num of bytes that should the be write. //FIXME -reduce to [5:0] and fix the << in the code 
	logic [15:0] new_read_req, new_write_req; //pulse when new req is appear
	logic [15:0][18:0] start_addr_s; //sampling the start adress to read for the memory that come from the clients
	logic [15:0][255:0] mask_sec; //the mask for the request to the second sram.
	//states for the FSM - ONE/TWO is the number of the banks that involve in the request (just by the addrees, not by the data that stored in the temp_buf)
	typedef enum logic [2:0] {IDLE, READ_ONE, READ_TWO, WRITE_ONE, WRITE_TWO} fsm;
	fsm [15:0] state, next_state;

	// signals for better readability
	logic [15:0] read_mem_req, write_mem_req, read_mem_valid, write_mem_ack;
	logic [15:0][18:0] read_mem_start_addr, write_mem_start_addr, read_mem_size_bytes, write_mem_size_bytes;
	logic [15:0][18:0] read_mem_start_addr_s, write_mem_start_addr_s, read_mem_size_bytes_s, write_mem_size_bytes_s;
	logic [15:0][31:0][7:0] read_mem_data, write_mem_data;

	logic [15:0][18:0] second_addr_write, second_addr_read; //the address plus 32 - the 4:0 bits don't care even to the addr that came to the sram 



	
	/*AUTOWIRE*/
	/*AUTOREG*/
	genvar i;
	generate
		for (i=0; i < 16; i++) begin: loop
			//convert the intf_in/out to signal to better readability
			assign read_mem_req[i] = intf_in[i].read_mem_req;
			assign write_mem_req[i] = intf_in[i].write_mem_req;
			assign intf_out[i].read_mem_valid = read_mem_valid[i];
			assign intf_out[i].write_mem_ack = write_mem_ack[i];
			assign read_mem_start_addr[i] = intf_in[i].read_mem_start_addr;
			assign read_mem_size_bytes[i] = intf_in[i].read_mem_size_bytes;
			assign write_mem_start_addr[i] = intf_in[i].write_mem_start_addr;
			assign write_mem_size_bytes[i] = intf_in[i].write_mem_size_bytes;
			assign intf_out[i].read_mem_data = read_mem_data[i];
			assign write_mem_data[i] = intf_in[i].write_mem_data;

			assign read_prior[i] = read_mem_req[i] ? 1'b1 : 1'b0; //FIXME add fairness priority - once read, once write

			//bits 18-16 determine the region and bit 5 determine if odd or even bank 
			assign read_sram[i] = {read_mem_start_addr[i][18:16], read_mem_start_addr[i][5]};
			assign write_sram[i] = {write_mem_start_addr[i][18:16], write_mem_start_addr[i][5]};
			//which srams the first req belong to
			assign which_sram[i] = read_prior[i] ? read_sram[i] : write_sram[i];
			
			//if the number bytes that need to be write bigger that the number of bytes until the end of the line:
			//take the number bytes until the end of the line, else take the number of the bytes that need to be written
			assign num_bytes_first_data_out[i] = (write_mem_size_bytes[i][5:0] > 6'd32 - write_mem_start_addr[i][4:0]) ?
				(6'd32 - write_mem_start_addr[i][4:0]) : write_mem_size_bytes[i][5:0];
			//the number of the bytes that need to be written in the second req (if not exist - so don't care from this value)
			//is the remainder form the first req nub bytes
			assign num_bytes_second_data_out[i] =  write_mem_size_bytes[i][5:0] - num_bytes_first_data_out[i];

			//the <<3 is because byte-bit convertion. i.e. multiplication in 8
			assign first_data_out[i] =  write_mem_data[i] << ({3'b0,write_mem_start_addr[i][4:0]}<<3);
			assign second_data_out[i] = write_mem_data[i] >> (num_bytes_first_data_out[i]<<3);

			// the next addr can be in another region (there is 8 regions and 16 banks) if the addr is the last in the region - 2047 in modulo 2048
			// else if the bank is even the next bank is plus 1, and minus 1 if the bank is odd 
			assign which_sram_sec[i] =  write_mem_start_addr[i][15:5] == 11'h7ff ? which_sram[i] + 4'd1 : 
				(which_sram[i][0] ? which_sram[i] - 4'd1 : which_sram[i] + 4'd1 );
			assign two_read_req[i] = read_mem_start_addr[i][4:0] + read_mem_size_bytes[i][5:0] > 19'd32 ? 1'b1 : 1'b0;
			assign two_write_req[i] = write_mem_start_addr[i][4:0] + write_mem_size_bytes[i][5:0] > 19'd32 ? 1'b1 : 1'b0;
			assign data_read_align[i] = read_mem_start_addr[i][4:0]==0 ? 1'b1 : 1'b0;
			assign data_write_align[i] = write_mem_start_addr[i][4:0]==0 ? 1'b1 : 1'b0;
			assign second_addr_write[i] =  write_mem_start_addr[i]+19'd32; //plus 32, because the 4:0 bits don't care even to the addr that came to the sram
			assign second_addr_read[i] =  read_mem_start_addr[i]+19'd32; //plus 32, because the 4:0 bits don't care even to the addr that came to the sram

			//the address of the req should be higher than (or equal to) the address of the temp_buf
			//and the last address of the temp_buf is higher than (or equal to) the address of the req
			assign req_data_stored_temp_buf[i] = ((read_mem_start_addr[i] >= addr_temp_buf[i]) &&
				(addr_temp_buf[i] + num_bytes_temp_buf[i] >= read_mem_start_addr[i] + read_mem_size_bytes[i][5:0])) || two_read_req_need_one;

			//if there is read req that required two req for the memory, 
			//check if the first data req stored in the temp_buf
			assign two_read_req_need_one[i] = ( (read_mem_start_addr[i] >= addr_temp_buf[i]) &&
				(addr_temp_buf[i] + num_bytes_temp_buf[i] >= read_mem_start_addr[i] + 19'd32 - read_mem_start_addr[i][4:0]) && two_read_req[i] ) ? 1'b1 : 1'b0;
				
			//There is new request (pulse) when the state is IDLE or valid/ack with request
			assign new_read_req[i] = (state[i]==IDLE || read_mem_valid[i] ) && read_mem_req[i];
			assign new_write_req[i] = (state[i]==IDLE || write_mem_ack[i] ) && write_mem_req[i];

			//the num of the bytes and the address updated once when there is a new req
			//in conrtast to the temp_buf that updtate several times during one req
	
			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					num_bytes_temp_buf[i]<='0;
					addr_temp_buf[i]<='0;
				end
				else if (new_read_req[i])
					if (!req_data_stored_temp_buf[i] || two_read_req_need_one) begin
						num_bytes_temp_buf[i]<=two_read_req[i] ? (7'd64 - read_mem_start_addr[i][4:0] - read_mem_size_bytes[i][5:0]) :
							(6'd32 - read_mem_start_addr[i][4:0] - read_mem_size_bytes[i][5:0]);
						addr_temp_buf[i]<=read_mem_start_addr[i] + read_mem_size_bytes[i][5:0];
					end
					else begin
						num_bytes_temp_buf[i]<= num_bytes_temp_buf[i] - read_mem_size_bytes[i][5:0];
						addr_temp_buf[i]<=read_mem_start_addr[i] + read_mem_size_bytes[i][5:0];
					end
			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
						addr_temp_buf_prev[i]<='0;
						num_bytes_temp_buf_prev[i]<='0;
					end
					else if (new_read_req[i]) begin
						addr_temp_buf_prev[i]<=addr_temp_buf[i];
						num_bytes_temp_buf_prev[i]<=num_bytes_temp_buf[i];
					end

			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
						start_addr_s[i]<='0;
					end
					else begin
						start_addr_s[i]<=read_mem_start_addr[i];
					end

			always_comb begin
				req_sram[i]='0;
				if (|gnt[i])
					req_sram[i]=1'b1;
				else
					req_sram[i]=1'b0;
			end

			//define the ack back to the clients
			always_comb begin
				case (state[i])
					IDLE: begin
						write_mem_ack[i]=1'b0;
					end
					READ_ONE: begin
						write_mem_ack[i]=1'b0;
					end
					READ_TWO: begin
						write_mem_ack[i]=1'b0;
					end
					WRITE_ONE: begin
						if (write_gnt_cnt[i]==2'd1)
							write_mem_ack[i]=1'b1;
						else
							write_mem_ack[i]=1'b0;
					end
					WRITE_TWO: begin
						if (write_gnt_cnt[i]==2'd3)
							write_mem_ack[i]=1'b1;
						else
							write_mem_ack[i]=1'b0;
					end
					default: begin
						write_mem_ack[i]=1'b0;
					end
				endcase
			end 

			//define the valid back to the clients
			always_comb begin
				case (state[i])
					IDLE: begin
						read_mem_valid[i]=1'b0;
					end
					READ_ONE: begin
						if (read_gnt_cnt[i]==2'd1 || req_data_stored_temp_buf_s[i])
							read_mem_valid[i]=1'b1;
						else
							read_mem_valid[i]=1'b0;
					end
					READ_TWO: begin
						if (read_gnt_cnt[i]==2'd3 || (read_gnt_cnt[i]==2'd2) && req_data_stored_temp_buf_s[i])
							read_mem_valid[i]=1'b1;
						else
							read_mem_valid[i]=1'b0;
					end
					WRITE_ONE: begin
						read_mem_valid[i]=1'b0;
					end
					WRITE_TWO: begin
						read_mem_valid[i]=1'b0;
					end
					default: begin
						read_mem_valid[i]=1'b0;
					end
				endcase
			end
			
			//sample values that required to the valid/ack cycle. because the the request not available whem there is valid/ack.
			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
						req_data_stored_temp_buf_s[i]<='0;
						read_mem_start_addr_s[i]<='0;
						write_mem_start_addr_s[i]<='0;
						read_mem_size_bytes_s[i]<='0;
						write_mem_size_bytes_s[i]<='0;
						data_read_align_s[i]<='0;
						which_sram_s[i]<='0;
						which_sram_sec_s[i]<='0;
						read_gnt_cnt_s[i]<='0;
					end
					else begin
						req_data_stored_temp_buf_s[i]<=req_data_stored_temp_buf[i];
						read_mem_start_addr_s[i]<=read_mem_start_addr[i];
						write_mem_start_addr_s[i]<=write_mem_start_addr[i];
						read_mem_size_bytes_s[i]<=read_mem_size_bytes[i];
						write_mem_size_bytes_s[i]<=write_mem_size_bytes[i];
						data_read_align_s[i]<=data_read_align[i];
						which_sram_s[i]<=which_sram[i];
						which_sram_sec_s[i]<=which_sram_sec[i];
						read_gnt_cnt_s[i]<=read_gnt_cnt[i];
					end

			//define value of the temp_buf
			//TODO - complete adding comments
			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					temp_buf[i]<='0;
				end
				else begin
					case (state[i])
						READ_ONE: begin
							if (!req_data_stored_temp_buf_s[i])
								if (data_read_align_s[i])
									if (read_gnt_cnt[i]==2'd1)
										temp_buf[i][255:0]<=data_in[which_sram_s[i]] >> ({3'b0,read_mem_size_bytes_s[i][5:0]} <<3);
									else
										temp_buf[i][255:0]<=temp_buf[i][255:0];
								else if (read_gnt_cnt[i]==2'd1) 
										temp_buf[i][255:0]<= data_in[which_sram_s[i]] >> ({3'b0,(read_mem_start_addr_s[i][4:0]+read_mem_size_bytes_s[i][5:0])}<<3);
									else
											temp_buf[i][255:0]<=temp_buf[i][255:0];
							else
								temp_buf[i][255:0]<=temp_buf[i][255:0] >> ({3'b0,read_mem_size_bytes_s[i][5:0]} <<3);
						end
						READ_TWO: begin
							if (!req_data_stored_temp_buf_s[i]) begin
								case ({read_gnt_cnt_s[i], read_gnt_cnt[i]}) //to know what was before and what is now.
									4'b0001: begin
										temp_buf[i][255:0]<= data_in[which_sram_s[i]]; 
									end
									4'b0010: begin
										temp_buf[i][511:256]<= data_in[which_sram_sec_s[i]]; 
									end
									4'b0011: begin
										temp_buf[i][255:0]<= {data_in[which_sram_sec_s[i]],data_in[which_sram_s[i]]} >> ((9'd32+start_addr_s[i][4:0])<<3);
									end
									4'b0111: begin
										temp_buf[i][255:0]<= {data_in[which_sram_sec_s[i]],temp_buf[i][255:0]} >> ((9'd32+start_addr_s[i][4:0])<<3);
									end
									4'b1011: begin
										temp_buf[i][255:0]<= {temp_buf[i][511:256],data_in[which_sram_s[i]]} >> ((9'd32+start_addr_s[i][4:0])<<3);
									end
								endcase
							end
							else begin
								case ({read_gnt_cnt_s[i], read_gnt_cnt[i]}) //to know what was before and what is now.
									4'b0011: begin
										temp_buf[i][255:0]<= data_in[which_sram_sec_s[i]] >> (((read_mem_start_addr_s[i][4:0] + read_mem_size_bytes_s[i])- 8'd32 )<<3); 
									end
									4'b0111: begin
										temp_buf[i][255:0]<= data_in[which_sram_sec_s[i]] >> (((read_mem_start_addr_s[i][4:0] + read_mem_size_bytes_s[i]) - 8'd32)<<3); 
									end
								endcase
							end
						end
					endcase
				end

			/*
			case template
			always_comb begin
				case (state[i])
					IDLE: begin
					end
					READ_ONE: begin
					end
					READ_TWO: begin
					end
					WRITE_ONE: begin
					end
					WRITE_TWO: begin
					end
					default: begin
					end
				endcase
			end 
			*/

			always_comb
					begin
						if (gnt[which_sram[i]][i] || read_prior[i] && req_data_stored_temp_buf[i] )
							if (read_prior[i]) begin
								first_read_gnt[i]=1'b1;
								first_write_gnt[i]='0;
							end
							else begin
								first_read_gnt[i]='0;
								first_write_gnt[i]=1'b1;
							end
						else begin
							first_read_gnt[i]='0;
							first_write_gnt[i]='0;
						end
						if (gnt[which_sram_sec[i]][i])
							if (read_prior[i]) begin
								second_read_gnt[i]=1'b1;
								second_write_gnt[i]='0;
							end
							else begin 
								second_write_gnt[i]=1'b1;
								second_read_gnt[i]='0;
							end 
						else begin
							second_read_gnt[i]='0;
							second_write_gnt[i]='0;
						end
					end

			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					first_read_gnt_s[i]<='0;
					first_write_gnt_s[i]<='0;
					second_read_gnt_s[i]<='0;
					second_write_gnt_s[i]<='0;
				end
				else begin
					first_read_gnt_s[i]<=first_read_gnt[i];
					first_write_gnt_s[i]<=first_write_gnt[i];
					second_read_gnt_s[i]<=second_read_gnt[i];
					second_write_gnt_s[i]<=second_write_gnt[i];
				end
			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
							read_gnt_cnt[i]<='0;
					end
					else begin
						//if there is now valid and there is new req
						if (read_gnt_cnt[i] == 2'd3 || (state[i]==READ_ONE) && (read_gnt_cnt[i] == 2'd1) || 
							write_gnt_cnt[i] == 2'd3 || ((state[i]==WRITE_ONE) && (write_gnt_cnt[i] == 2'd1))) begin
							case ({first_read_gnt[i],second_read_gnt[i]})
								2'b00:	read_gnt_cnt[i]<=2'd0;
								2'b01:	read_gnt_cnt[i]<=2'd2;
								2'b10:	read_gnt_cnt[i]<=2'd1;
								2'b11:	read_gnt_cnt[i]<=2'd3;
								default: read_gnt_cnt[i]<=2'd0;
							endcase
						end
						else begin
							case ({first_read_gnt[i],second_read_gnt[i]})
								2'b00:	read_gnt_cnt[i]<=read_gnt_cnt[i];
								2'b01:	read_gnt_cnt[i]<=read_gnt_cnt[i]+2'd2;
								2'b10:	read_gnt_cnt[i]<=read_gnt_cnt[i]+2'd1;
								2'b11:	read_gnt_cnt[i]<=read_gnt_cnt[i]+2'd3;
								default: read_gnt_cnt[i]<=read_gnt_cnt[i];
							endcase
						end
					end

			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
							write_gnt_cnt[i]<='0;
					end
					else begin
						if (read_gnt_cnt[i] == 2'd3 || (state[i]==READ_ONE) && (read_gnt_cnt[i] == 2'd1) ||
							write_gnt_cnt[i] == 2'd3 || ((state[i]==WRITE_ONE) && (write_gnt_cnt[i] == 2'd1))) begin
							case ({first_write_gnt[i],second_write_gnt[i]})
								2'b00:	write_gnt_cnt[i]<=2'd0;
								2'b01:	write_gnt_cnt[i]<=2'd2;
								2'b10:	write_gnt_cnt[i]<=2'd1;
								2'b11:	write_gnt_cnt[i]<=2'd3;
								default: write_gnt_cnt[i]<=2'd0;
							endcase
						end
						else begin
							case ({first_write_gnt[i],second_write_gnt[i]})
								2'b00:	write_gnt_cnt[i]<=write_gnt_cnt[i];
								2'b01:	write_gnt_cnt[i]<=write_gnt_cnt[i]+2'd2;
								2'b10:	write_gnt_cnt[i]<=write_gnt_cnt[i]+2'd1;
								2'b11:	write_gnt_cnt[i]<=write_gnt_cnt[i]+2'd3;
								default: write_gnt_cnt[i]<=write_gnt_cnt[i];
							endcase
						end
					end
			//the transition of the fsm:
			//the fsm move from IDLE to another state and wait for gnt.
			//when gnt is come if there is another req the FSM move to the appropriate state else it move back to IDLE  
			always_comb	
				case (state[i])
					IDLE: 
						if (read_prior[i])
							if (two_read_req[i] )
								next_state[i]=READ_TWO;
							else if (read_mem_req[i])
									next_state[i]=READ_ONE;
								else
									next_state[i]=IDLE;
						else
							if (two_write_req[i])
								next_state[i]=WRITE_TWO;
							else if (write_mem_req[i])
									next_state[i]=WRITE_ONE;
								else
									next_state[i]=IDLE;
					READ_TWO:
						if (read_gnt_cnt[i] ==2'd3)
							if (!read_mem_req[i] && !write_mem_req[i])
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] )
										next_state[i]=READ_TWO;
									else
										next_state[i]=READ_ONE;
								else
									if (two_write_req[i])
										next_state[i]=WRITE_TWO;
									else
										next_state[i]=WRITE_ONE;
						else
							next_state[i]=READ_TWO;
					READ_ONE:
						if (first_read_gnt_s[i])
							if (!read_mem_req[i] && !write_mem_req[i])
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] )
										next_state[i]=READ_TWO;
									else
										next_state[i]=READ_ONE;
								else
									if (two_write_req[i])
										next_state[i]=WRITE_TWO;
									else
										next_state[i]=WRITE_ONE;
						else
							next_state[i]=READ_ONE;
					WRITE_TWO:
						if (write_gnt_cnt[i] == 2'd3)
							if (!read_mem_req[i] && !write_mem_req[i])
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] )
										next_state[i]=READ_TWO;
									else
										next_state[i]=READ_ONE;
								else
									if (two_write_req[i])
										next_state[i]=WRITE_TWO;
									else
										next_state[i]=WRITE_ONE;
						else
							next_state[i]=WRITE_TWO;
					WRITE_ONE:
						if (first_write_gnt_s[i])
							if (!read_mem_req[i] && !write_mem_req[i])
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] )
										next_state[i]=READ_TWO;
									else
										next_state[i]=READ_ONE;
								else
									if (two_write_req[i])
										next_state[i]=WRITE_TWO;
									else
										next_state[i]=WRITE_ONE;
						else
							next_state[i]=WRITE_ONE;
				endcase

			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					state[i]<=IDLE;
				end
				else begin
					state[i]<=next_state[i];
				end

		always_comb begin
			read_mem_data[i]='0;
				case (state[i])
					IDLE: begin
						read_mem_data[i]='0;
					end
					READ_ONE: begin 
						if (!req_data_stored_temp_buf_s[i]) begin
							if (data_read_align_s[i]) begin
									if (read_gnt_cnt[i]==2'd1) 
										read_mem_data[i]=data_in[which_sram_s[i]];
									else
										read_mem_data[i]='0;
							end
							else begin if (read_gnt_cnt[i]==2'd1) 
									read_mem_data[i]= (data_in[which_sram_s[i]]) >> (({3'b0,read_mem_start_addr_s[i][4:0]})<<3);
								else
									read_mem_data[i]='0;
							end
						end
						else
							read_mem_data[i]=temp_buf[i][255:0] >> ( {3'b0,(read_mem_start_addr_s[i][4:0] - addr_temp_buf_prev[i][4:0])}<<3);
					end
					READ_TWO: begin
						if (!req_data_stored_temp_buf_s[i]) begin
							case ({read_gnt_cnt_s[i], read_gnt_cnt[i]})
								4'b0011: begin
									read_mem_data[i]={data_in[which_sram_sec_s[i]],data_in[which_sram_s[i]]} >> ({3'b0,(start_addr_s[i][4:0])}<<3);
								end
								4'b0111: begin
									read_mem_data[i]={data_in[which_sram_sec_s[i]],temp_buf[i][255:0]} >> ({3'b0,(start_addr_s[i][4:0])}<<3);
								end
								4'b1011: begin
									read_mem_data[i]={temp_buf[i][511:256],data_in[which_sram_s[i]]} >> ({3'b0,(start_addr_s[i][4:0])}<<3);
								end
								default: begin
								read_mem_data[i]='0;
								end
							endcase
						end
						else begin
							case ({read_gnt_cnt_s[i], read_gnt_cnt[i]})
								4'b0011: begin
									read_mem_data[i]={data_in[which_sram_sec_s[i]],(temp_buf[i][255:0] << ((8'd32 - num_bytes_temp_buf_prev[i][4:0] )<<3))} >> ({3'b0,(start_addr_s[i][4:0])}<<3);
								end
								4'b0111: begin
									read_mem_data[i]={data_in[which_sram_sec_s[i]],(temp_buf[i][255:0] << ((8'd32 - num_bytes_temp_buf_prev[i][4:0] )<<3))} >> ({3'b0,(start_addr_s[i][4:0])}<<3);
								end
								default: begin
								read_mem_data[i]='0;
								end
							endcase
						end
					end
					WRITE_ONE: begin
						read_mem_data[i]='0;
					end
					WRITE_TWO: begin
						read_mem_data[i]='0;
					end
					default: begin
						read_mem_data[i]='0;
					end
				endcase
			end
		end
	endgenerate

			always_comb	begin
				req='0;
			//	case (state[i])
	for (integer k=0; k < 16; k++) 
				begin
						if ((next_state[k]!=IDLE) && (!req_data_stored_temp_buf[k] && read_mem_req[k] || two_read_req_need_one[k]|| write_mem_req[k]))
							if ((next_state[k]==WRITE_TWO) || (next_state[k]==READ_TWO)) begin
								req[which_sram[k]][k]=1'b1;
								req[which_sram_sec[k]][k]=1'b1;
							end
							else begin
								req[which_sram[k]][k]=1'b1;
							end
						else begin
							req[which_sram_sec[k]][k]=1'b0;
							req[which_sram[k]][k]=1'b0;
						end
					end
				end
	
				
   // 		always_comb	begin
   // 			req='0;
   // 		//	case (state[i])
   // for (integer k=0; k < 16; k++) 
   // 			begin
   // 					if ((next_state[k]!=IDLE) && (!req_data_stored_temp_buf[k] && read_mem_req[k] || two_read_req_need_one[k]|| write_mem_req[k]))
   // 						if ((next_state[k]==WRITE_TWO) || (next_state[k]==READ_TWO)) begin
   // 							if (!req_data_stored_temp_buf) begin
   // 								req[which_sram[k]][k]=1'b1;
   // 								req[which_sram_sec[k]][k]=1'b1;
   // 							end
   // 							else
   // 								req[which_sram_sec[k]][k]=1'b1;
   // 						end
   // 						else begin
   // 							req[which_sram[k]][k]=1'b1;
   // 						end
   // 					else begin
   // 						req[which_sram_sec[k]][k]=1'b0;
   // 						req[which_sram[k]][k]=1'b0;
   // 					end
   // 				end
   // 			end

			always_comb begin
				data_out='0;
				addr_to_sram='0;
				mask_sec='0;
				mask_enable='0;
				read='0;
				write='0;
				for (integer kk=0; kk < 16; kk++)
					for (integer j=0; j < 16; j++) 
						if (gnt[kk][j]) begin
							data_out[kk]= kk[3:0]==which_sram[j] ? first_data_out[j] : second_data_out[j]; 
							addr_to_sram[kk] = read_prior[j] ? 
								((kk[3:0]==which_sram[j] ? {read_mem_start_addr[j][18:16],read_mem_start_addr[j][5],read_mem_start_addr[j][15:6],read_mem_start_addr[j][4:0]} :
								{second_addr_read[j][18:16],second_addr_read[j][5],second_addr_read[j][15:6],second_addr_read[j][4:0]}))
								:
								(kk[3:0]==which_sram[j] ? {write_mem_start_addr[j][18:16],write_mem_start_addr[j][5],write_mem_start_addr[j][15:6],write_mem_start_addr[j][4:0]} :
								{second_addr_write[j][18:16],second_addr_write[j][5],second_addr_write[j][15:6],second_addr_write[j][4:0]});
							//reduce 1 to get all the right(lsb) bits 1, and then negate all
							mask_sec[kk]= ((257'd1<<256)-1) >> (256-(num_bytes_second_data_out[j]<<3));
							//reduce 1 to get all the right(lsb) bits 1, and then negate all
							mask[kk] =kk[3:0]==which_sram[j] ? (~((256'd1 << ({3'b0,write_mem_start_addr[j][4:0]}<<3))-1'b1)) & 
								(((257'd1<<256)-1) >> (256-(({3'd0,write_mem_start_addr[j][4:0]}<<3)+(num_bytes_first_data_out[j]<<3)))) : mask_sec[kk]; 
							mask_enable[kk] = !data_write_align[j]|| (num_bytes_first_data_out[j]<32);
							read[kk]= read_prior[j]==1'b1;
							write[kk]= read_prior[j]==1'b0;

						end
			end


endmodule

// Local Variables:
// verilog-library-directories:("." ".")
// verilog-auto-output-ignore-regexp: "" 
// verilog-library-extensions:(".sv" ".v")
// END:

