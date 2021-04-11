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
// Version			: 0.1
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
	output logic [15:0] req_sram, //activate the appropriate sram (cs) of course, that just after gnt.
	output req_ctrl_out_s [15:0] intf_out, //struct with the output of the read and/or write interface
	output logic [15:0][15:0] req, //the reqs that sent to the srams, every req_ctrl (there is 16) can send req to each of the srams
	output logic [15:0] mask_enable, // is the srams should use in mask for writing
	output logic [15:0][255:0] mask //the mask in resulotion of bits

	);

	// -------------------------------------------------------------------------
	//  declarations
	// -------------------------------------------------------------------------
	/*AUTOLOGIC*/
	logic [15:0] read_prior; //is read or write in priority
	logic [15:0][3:0] which_sram, read_sram, write_sram, which_sram_sec; //wich number of the sram the addres belong to, sec - second req 
	logic [15:0] two_read_req, two_write_req;//is to req neccessery
	logic [15:0] data_read_align, data_write_align; //is the addr aligned
	logic [15:0][511:0] temp_buf; //temporary buf, conatain the data that came from the sram and not written to the clients
	logic [15:0][5:0] num_bytes_temp_buf; //the number of the bytes that stored ib the temp_buf
	logic [15:0][18:0] addr_temp_buf;//the address that stored in the temp_buf
	logic [15:0] req_data_stored_temp_buf;//is the data for the first req exsist in the temp_buf
	logic [15:0] two_read_req_need_one; //there are two req for the memory but the data for the first req exsit in the temp_buf
	logic [15:0] first_read_gnt, first_write_gnt, second_read_gnt, second_write_gnt;// pulse when the gnt came
	logic [15:0] first_read_gnt_s, first_write_gnt_s, second_read_gnt_s, second_write_gnt_s;//sampling the gnt for use in the next cycle
	logic [15:0][1:0] read_gnt_cnt, read_gnt_cnt_s, write_gnt_cnt; //counter of the gnt : plus 1 for the first_req, plus 2 for the second req  
	logic [15:0][255:0] first_data_out, second_data_out, first_data_out_mask;//the data and the mask for the first req to the sram, the second req - without mask.
	logic [15:0][5:0] num_bytes_first_data_out, num_bytes_second_data_out;// again, currently the second signal doesn't connect because there isn't mask for the second req
	logic [15:0] new_read_req, new_write_req; //pulse when new req is apear
	logic [15:0][5:0] read_bytes_s; //sampling the number of the bytes to read for the memory that come from the clients
	//states for the FSM
	typedef enum logic [2:0] {IDLE, READ_ONE, READ_TWO, WRITE_ONE, WRITE_TWO} fsm;
	fsm [15:0] state, next_state;
	
	/*AUTOWIRE*/
	/*AUTOREG*/
	genvar i;
	generate
		for (i=0; i < 16; i++) begin: loop
			assign read_prior[i] = intf_in[i].read_mem_req ? 1'b1 : 1'b0; //FIXME add fairness priority - once read, once write

			//bits 18-16 determine the region and bit 5 determine if odd or even bank 
			assign read_sram[i] = {intf_in[i].read_mem_start_addr[18:16], intf_in[i].read_mem_start_addr[5]};
			assign write_sram[i] = {intf_in[i].write_mem_start_addr[18:16], intf_in[i].write_mem_start_addr[5]};
			//which srams the first req belong to
			assign which_sram[i] = read_prior[i] ? read_sram[i] : write_sram[i];
			
			//if the number bytes that need to be write bigger that the number of bytes until the end of the line:
			//take the number bytes until the end of the line, else take the number of the bytes that need to be written
			assign num_bytes_first_data_out[i] = (intf_in[i].write_mem_size_bytes[5:0] > 6'd32 - intf_in[i].write_mem_start_addr[4:0]) ?
				(6'd32 - intf_in[i].write_mem_start_addr[4:0]) : intf_in[i].write_mem_size_bytes[5:0];
			//the number of the bytes that need to be written in the second req (if not exist - so don't care from this value)
			//is the remainder form the first req nub bytes
			assign num_bytes_second_data_out[i] =  intf_in[i].write_mem_size_bytes[5:0] - num_bytes_first_data_out[i];

			//the 3 is because byte-bit convertion
			assign first_data_out[i] =  intf_in[i].write_mem_data << (intf_in[i].write_mem_start_addr[4:0]<<3);
			assign second_data_out[i] = intf_in[i].write_mem_data >> (num_bytes_first_data_out[i]<<3);

			//reduce 1 to get all the right bits 1 and then negate all
			//req to writing to address not until the end of the line will overwritten the rest to end of the line. 
			assign mask[i] = ~((256'd1 << (intf_in[i].write_mem_start_addr[4:0]<<3))-1'b1); 
			assign mask_enable[i] = two_write_req[i];

			// the next addr can be in another region (there is 8 regions and 16 banks) if the addr is the last in the region - 2047 in modulo 2048
			// else if the bank is even the next bank is plus 1, and minus 1 if the bank is odd 
			// TODO - complete adding comments
			assign which_sram_sec[i] =  intf_in[i].write_mem_start_addr[15:5] == 11'h7ff ? which_sram[i] + 4'd1 : 
				(which_sram[i][0] ? which_sram[i] - 4'd1 : which_sram[i] + 4'd1 );
			assign two_read_req[i] = intf_in[i].read_mem_start_addr[4:0] + intf_in[i].read_mem_size_bytes[5:0] > 19'd32 ? 1'b1 : 1'b0;
			assign two_write_req[i] = intf_in[i].write_mem_start_addr[4:0] + intf_in[i].write_mem_size_bytes[5:0] > 19'd32 ? 1'b1 : 1'b0;
			assign data_read_align[i] = intf_in[i].read_mem_start_addr[4:0]==0 ? 1'b1 : 1'b0;
			assign data_write_align[i] = intf_in[i].write_mem_start_addr[4:0]==0 ? 1'b1 : 1'b0;

			//the address of the req should be higher than (or equal to) the address of the temp_buf
			//and the last address of the temp_buf is higher than (or equal to) the address of the req
			assign req_data_stored_temp_buf[i] = (intf_in[i].read_mem_start_addr >= addr_temp_buf[i]) &&
				(addr_temp_buf[i] + num_bytes_temp_buf[i] >= intf_in[i].read_mem_start_addr + intf_in[i].read_mem_size_bytes[5:0]);

			//if there is read req that required two req for the memory, 
			//check if the first data req stored in the temp_buf
			assign two_read_req_need_one[i] = ( (intf_in[i].read_mem_start_addr >= addr_temp_buf[i]) &&
				(addr_temp_buf[i] + num_bytes_temp_buf[i] >= intf_in[i].read_mem_start_addr + 19'd32 - intf_in[i].read_mem_start_addr[4:0]) && two_read_req[i] ) ? 1'b1 : 1'b0;
			assign new_read_req[i] = (read_gnt_cnt[i] == 2'd3 || state[i]==READ_ONE && read_gnt_cnt[i] == 2'd1 || 
				read_gnt_cnt[i]==2'd2 && req_data_stored_temp_buf[i] || read_gnt_cnt[i]==2'd0 && state[i]==READ_ONE && req_data_stored_temp_buf[i] || read_gnt_cnt[i]==0) && intf_in[i].read_mem_req;

			//the num of the bytes and the address updated once when there is a new req
			//in conrtast to the temp_buf that updtate several times during one req 
			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					num_bytes_temp_buf[i]<='0;
					addr_temp_buf[i]<='0;
				end
				else if (new_read_req[i]) begin
						num_bytes_temp_buf[i]<=(6'd32 - intf_in[i].read_mem_start_addr[4:0] - intf_in[i].read_mem_size_bytes[5:0]) >='0 ? 
						(6'd32 - intf_in[i].read_mem_start_addr[4:0] - intf_in[i].read_mem_size_bytes[5:0]) : (7'd64 - intf_in[i].read_mem_start_addr[4:0] - intf_in[i].read_mem_size_bytes[5:0]);
						addr_temp_buf[i]<=intf_in[i].read_mem_start_addr + intf_in[i].read_mem_size_bytes[5:0];
				end

			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
						read_bytes_s[i]<='0;
					end
					else begin
						read_bytes_s[i]<=intf_in[i].read_mem_size_bytes[5:0];
					end
			//the srams of first and the second req
			always_comb	begin
				req[i]='0;
				case (state[i])
					IDLE: begin
						if (next_state[i]!=IDLE && !req_data_stored_temp_buf[i])
							req[which_sram[i]][i]=1'b1;
						else
							req[which_sram[i]][i]=1'b0;
						if (next_state[i]==WRITE_TWO || next_state[i]==READ_TWO)
							req[which_sram_sec[i]][i]=1'b1;
						else
							req[which_sram_sec[i]][i]=1'b0;
					end
					READ_ONE: begin
						if (next_state[i]!=IDLE && !req_data_stored_temp_buf[i])
							req[which_sram[i]][i]=1'b1;
						else
							req[which_sram[i]][i]=1'b0;
					end
					READ_TWO: begin
						if ( (read_gnt_cnt[i]=='0 || read_gnt_cnt[i]==2'd2)&& !req_data_stored_temp_buf[i] )
							req[which_sram[i]][i]=1'b0;
						else
							req[which_sram[i]][i]=1'b1;
						if (read_gnt_cnt[i]=='0 || read_gnt_cnt[i]==2'd1)
							req[which_sram_sec[i]][i]=1'b1;
						else
							req[which_sram_sec[i]][i]=1'b0;
					end
					WRITE_ONE: begin
						if (next_state[i]!=IDLE)
							req[which_sram[i]][i]=1'b1;
						else
							req[which_sram[i]][i]=1'b0;
					end
					WRITE_TWO: begin
						if (write_gnt_cnt[i]=='0 || write_gnt_cnt[i]==2'd2)
							req[which_sram[i]][i]=1'b0;
						else
							req[which_sram[i]][i]=1'b1;
						if (write_gnt_cnt[i]=='0 || write_gnt_cnt[i]==2'd1)
							req[which_sram_sec[i]][i]=1'b1;
						else
							req[which_sram_sec[i]][i]=1'b0;
					end
					default: begin
						req[which_sram[i]][i]=1'b0;
						req[which_sram_sec[i]][i]=1'b0;
					end
				endcase
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
						intf_out[i].write_mem_ack=1'b0;
					end
					READ_ONE: begin
						intf_out[i].write_mem_ack=1'b0;
					end
					READ_TWO: begin
						intf_out[i].write_mem_ack=1'b0;
					end
					WRITE_ONE: begin
						if (write_gnt_cnt[i]==2'd1)
							intf_out[i].write_mem_ack=1'b1;
						else
							intf_out[i].write_mem_ack=1'b0;
					end
					WRITE_TWO: begin
						if (write_gnt_cnt[i]==2'd3)
							intf_out[i].write_mem_ack=1'b1;
						else
							intf_out[i].write_mem_ack=1'b0;
					end
					default: begin
						intf_out[i].write_mem_ack=1'b0;
					end
				endcase
			end 

			//define the valid back to the clients
			always_comb begin
				case (state[i])
					IDLE: begin
						intf_out[i].read_mem_valid=1'b0;
					end
					READ_ONE: begin
						if (read_gnt_cnt[i]==2'd1 || req_data_stored_temp_buf[i])
							intf_out[i].read_mem_valid=1'b1;
						else
							intf_out[i].read_mem_valid=1'b0;
					end
					READ_TWO: begin
						if (read_gnt_cnt[i]==2'd3 || read_gnt_cnt[i]==2'd2 && req_data_stored_temp_buf[i])
							intf_out[i].read_mem_valid=1'b1;
						else
							intf_out[i].read_mem_valid=1'b0;
					end
					WRITE_ONE: begin
						intf_out[i].read_mem_valid=1'b0;
					end
					WRITE_TWO: begin
						intf_out[i].read_mem_valid=1'b0;
					end
					default: begin
						intf_out[i].read_mem_valid=1'b0;
					end
				endcase
			end

			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
						read_gnt_cnt_s[i]<='0;
					end
					else begin
						read_gnt_cnt_s[i]<=read_gnt_cnt[i];
					end
			//define the signals of the temp_buf
			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					temp_buf[i]<='0;
				end
				else begin
					case (state[i])
						READ_ONE: begin
							if (!req_data_stored_temp_buf[i])
								if (data_read_align[i])
									if (read_gnt_cnt[i]==2'd1) begin
										temp_buf[i][255:0]<=data_in[which_sram[i]] >> (intf_in[i].read_mem_size_bytes[5:0] <<3);
								end
								else if (read_gnt_cnt[i]==2'd1) begin
										temp_buf[i][255:0]<= data_in[which_sram[i]] >> ((intf_in[i].read_mem_start_addr[4:0]+intf_in[i].read_mem_size_bytes[5:0])<<3);
								end
						end
						READ_TWO: begin
							if (req_data_stored_temp_buf[i]) begin
								case ({read_gnt_cnt_s[i], read_gnt_cnt[i]})
									4'b0001: begin
										temp_buf[i][255:0]<= data_in[which_sram[i]]; 
									end
									4'b0010: begin
										temp_buf[i][511:256]<= data_in[which_sram_sec[i]]; 
									end
									4'b0011: begin
										temp_buf[i][255:0]<= {data_in[which_sram_sec[i]],data_in[which_sram[i]]} >> ((6'd32+read_bytes_s[i])<<3);
									end
									4'b0111: begin
										temp_buf[i][255:0]<= {data_in[which_sram_sec[i]],temp_buf[i][255:0]} >> ((6'd32+read_bytes_s[i])<<3);
									end
									4'b1011: begin
										temp_buf[i][255:0]<= {temp_buf[i][511:256],data_in[which_sram[i]]} >> ((6'd32+read_bytes_s[i])<<3);
									end
								endcase
							end
						end
					endcase
				end

			always_comb begin
				case (state[i])
					IDLE: begin
						intf_out[i].read_mem_data='0;
					end
					READ_ONE: 
						if (!req_data_stored_temp_buf[i])
								if (data_read_align[i])
									if (read_gnt_cnt[i]==2'd1) 
										intf_out[i].read_mem_data=data_in[which_sram[i]];
									else
										intf_out[i].read_mem_data='0;
								else if (read_gnt_cnt[i]==2'd1) 
										intf_out[i].read_mem_data<= data_in[which_sram[i]] >> (intf_in[i].read_mem_start_addr[4:0]<<3);
									else
										intf_out[i].read_mem_data='0;
						else
							intf_out[i].read_mem_data=temp_buf[i][255:0];
					READ_TWO: begin
						case ({read_gnt_cnt_s[i], read_gnt_cnt[i]})
							4'b0011: begin
								intf_out[i].read_mem_data={data_in[which_sram_sec[i]],data_in[which_sram[i]]} >> ((read_bytes_s[i])<<3);
							end
							4'b0111: begin
								intf_out[i].read_mem_data={data_in[which_sram_sec[i]],temp_buf[i][255:0]} >> ((6'd32+read_bytes_s[i])<<3);
							end
							4'b1011: begin
								intf_out[i].read_mem_data={temp_buf[i][511:256],data_in[which_sram[i]]} >> ((6'd32+read_bytes_s[i])<<3);
							end
							default: begin
							intf_out[i].read_mem_data='0;
							end
						endcase
					end
					WRITE_ONE: begin
						intf_out[i].read_mem_data='0;
					end
					WRITE_TWO: begin
						intf_out[i].read_mem_data='0;
					end
					default: begin
						intf_out[i].read_mem_data='0;
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
						if (gnt[which_sram[i]][i])
							if (read_prior[i])
								first_read_gnt[i]=1'b1;
							else
								first_write_gnt[i]=1'b1;
						else begin
							first_read_gnt[i]='0;
							first_write_gnt[i]='0;
						end
						if (gnt[which_sram_sec[i]][i])
							if (read_prior[i])
								second_read_gnt[i]=1'b1;
							else
								second_write_gnt[i]=1'b1;
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
						if (read_gnt_cnt[i] == 2'd3 || state[i]==READ_ONE && read_gnt_cnt[i] == 2'd1 || read_gnt_cnt[i]==2'd2 && req_data_stored_temp_buf[i])
							case ({first_read_gnt[i],second_read_gnt[i]})
								2'b00:	read_gnt_cnt[i]<=2'd0;
								2'b01:	read_gnt_cnt[i]<=2'd2;
								2'b10:	read_gnt_cnt[i]<=2'd1;
								2'b11:	read_gnt_cnt[i]<=2'd3;
								default: read_gnt_cnt[i]<=2'd0;
							endcase
						else
							case ({first_read_gnt[i],second_read_gnt[i]})
								2'b00:	read_gnt_cnt[i]<=read_gnt_cnt[i];
								2'b01:	read_gnt_cnt[i]<=read_gnt_cnt[i]+2'd2;
								2'b10:	read_gnt_cnt[i]<=read_gnt_cnt[i]+2'd1;
								2'b11:	read_gnt_cnt[i]<=read_gnt_cnt[i]+2'd3;
								default: read_gnt_cnt[i]<=read_gnt_cnt[i];
							endcase
					end

			always @(posedge clk or negedge rst_n)
					if (!rst_n) begin
							write_gnt_cnt[i]<='0;
					end
					else begin
						if (write_gnt_cnt[i] == 2'd3 || state[i]==WRITE_ONE && write_gnt_cnt[i] == 2'd1)
							case ({first_write_gnt[i],second_write_gnt[i]})
								2'b00:	write_gnt_cnt[i]<=2'd0;
								2'b01:	write_gnt_cnt[i]<=2'd2;
								2'b10:	write_gnt_cnt[i]<=2'd1;
								2'b11:	write_gnt_cnt[i]<=2'd3;
								default: write_gnt_cnt[i]<=2'd0;
							endcase
						else
							case ({first_write_gnt[i],second_write_gnt[i]})
								2'b00:	write_gnt_cnt[i]<=write_gnt_cnt[i];
								2'b01:	write_gnt_cnt[i]<=write_gnt_cnt[i]+2'd2;
								2'b10:	write_gnt_cnt[i]<=write_gnt_cnt[i]+2'd1;
								2'b11:	write_gnt_cnt[i]<=write_gnt_cnt[i]+2'd3;
								default: write_gnt_cnt[i]<=write_gnt_cnt[i];
							endcase
					end
			always_comb begin
				for (integer j=0; j < 16; j++) 
					if (gnt[i][j])
						data_out[j]= j[3:0]==which_sram[i] ? first_data_out[i] : second_data_out[i]; 
					
			end
			//the transition of the fsm:
			//the fsm move from IDLE to another state and wait for gnt.
			//when gnt is come if there is another req the FSM move to the appropriate state else it move back to IDLE  
			always_comb	
				case (state[i])
					IDLE: 
						if (read_prior[i])
							if (two_read_req[i] && !two_read_req_need_one[i])
								next_state[i]=READ_TWO;
							else if (intf_in[i].read_mem_req)
									next_state[i]=READ_ONE;
								else
									next_state[i]=IDLE;
						else
							if (two_write_req[i])
								next_state[i]=WRITE_TWO;
							else if (intf_in[i].write_mem_req)
									next_state[i]=WRITE_ONE;
								else
									next_state[i]=IDLE;
					READ_TWO:
						if (read_gnt_cnt[i] ==2'd3)
							if (!intf_in[i].read_mem_req && !intf_in[i].write_mem_req)
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] && !two_read_req_need_one[i])
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
							if (!intf_in[i].read_mem_req && !intf_in[i].write_mem_req)
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] && !two_read_req_need_one[i])
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
							if (!intf_in[i].read_mem_req && !intf_in[i].write_mem_req)
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] && !two_read_req_need_one[i])
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
							if (!intf_in[i].read_mem_req && !intf_in[i].write_mem_req)
								next_state[i]=IDLE;
							else
								if (read_prior[i])
									if (two_read_req[i] && !two_read_req_need_one[i])
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
		end
	endgenerate

	

endmodule

// Local Variables:
// verilog-library-directories:("." ".")
// verilog-auto-output-ignore-regexp: "" 
// verilog-library-extensions:(".sv" ".v")
// END:

