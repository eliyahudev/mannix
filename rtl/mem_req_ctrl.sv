// -------------------------------------------------------------------------
// File name		: mem_req_ctrl.sv 
// Title				: 
// Project      	: 
// Developers   	: gerners 
// Created      	: Thu Apr 08, 2021  09:16PM 
// Last modified  : 
// Description  	: 
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
	input req_ctrl_in_s [15:0] intf_in,
	input [15:0] [15:0] gnt,
	input [15:0][255:0] data_in,
	output logic [15:0][255:0] data_out,
	output req_ctrl_out_s [15:0] intf_out,
	output logic [15:0][15:0] req,
	output logic [15:0] mask_enable,
	output logic [15:0][255:0] mask

	);

	// -------------------------------------------------------------------------
	//  declarations
	// -------------------------------------------------------------------------
	/*AUTOLOGIC*/
	logic [15:0] read_prior;
	logic [15:0][3:0] which_sram, read_sram, write_sram;
	logic [15:0] two_read_req, two_write_req;
	logic [15:0] data_read_align, data_write_align;
	logic [15:0][511:0] temp_buf;
	logic [15:0][4:0] num_bits_temp_buf;
	logic [15:0][18:0] addr_temp_buf;
	logic [15:0] req_data_stored_temp_buf;
	logic [15:0] two_read_req_need_one;
	logic [15:0] first_read_gnt, first_write_gnt, second_read_gnt, second_write_gnt;
	//states for the FSM
	typedef enum logic [2:0] {IDLE, READ_ONE, READ_TWO, WRITE_ONE, WRITE_TWO} fsm;
	fsm [15:0] state, next_state;
	
	/*AUTOWIRE*/
	/*AUTOREG*/
	genvar i;
	generate
		for (i=0; i < 16; i++) begin: loop
			assign read_prior[i] = intf_in[i].read_mem_req ? 1'b1 : 1'b0; //FIXME add fairness priority - once read, once write
			assign read_sram[i] = {intf_in[i].read_mem_start_addr[18:16], intf_in[i].read_mem_start_addr[5]};
			assign write_sram[i] = {intf_in[i].write_mem_start_addr[18:16], intf_in[i].write_mem_start_addr[5]};
			assign which_sram[i] = read_prior[i] ? read_sram[i] : write_sram[i];
			assign two_read_req[i] = intf_in[i].read_mem_start_addr[4:0] + intf_in[i].read_mem_size_bytes > 19'd32 ? 1'b1 : 1'b0;
			assign two_write_req[i] = intf_in[i].write_mem_start_addr[4:0] + intf_in[i].write_mem_size_bytes > 19'd32 ? 1'b1 : 1'b0;
			assign data_read_align[i] = intf_in[i].read_mem_start_addr[4:0]==0 ? 1'b1 : 1'b0;
			assign data_write_align[i] = intf_in[i].write_mem_start_addr[4:0]==0 ? 1'b1 : 1'b0;
			//the address of the req should be higher than (or equal to) the address of the temp_buf
			//and the last address of the temp_buf is higher than (or equal to) the address of the req
			assign req_data_stored_temp_buf[i] = (intf_in[i].read_mem_start_addr >= addr_temp_buf) &&
				(addr_temp_buf + num_bits_temp_buf >= intf_in[i].read_mem_start_addr + intf_in[i].read_mem_size_bytes);
			//if there is read req that required two req for the memory, 
			//check if the first data req stored in the temp_buf
			assign two_read_req_need_one[i] = ( (intf_in[i].read_mem_start_addr >= addr_temp_buf) &&
				(addr_temp_buf + num_bits_temp_buf >= intf_in[i].read_mem_start_addr + 19'd32 - intf_in[i].read_mem_start_addr[4:0]) && two_read_req[i] ) ? 1'b1 : 1'b0;
			
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			state[i]<=IDLE;
		end
		else begin
			state[i]<=next_state[i];
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
						else
							next_state[i]=READ_ONE;
					else
						if (two_write_req[i])
							next_state[i]=WRITE_TWO;
						else
							next_state[i]=WRITE_ONE;
				READ_TWO:
					if (first_read_gnt[i] && second_read_gnt[i])
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
					if (first_read_gnt[i])
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
					if (first_write_gnt[i] && second_write_gnt[i])
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
					if (first_write_gnt[i])
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
		end
	endgenerate

	

endmodule

// Local Variables:
// verilog-library-directories:("." ".")
// verilog-auto-output-ignore-regexp: "" 
// verilog-library-extensions:(".sv" ".v")
// END:

