//======================================================================================================
//
// Module: cnn
//
// Design Unit Owner : Netanel Lalazar
//                    
// Original Author   : Netanel Lalazar
// Original Date     : 27-Nov-2020
//
//======================================================================================================
module cnn (
            clk,
            rst_n,

            // pic_mem_start_addr, 
            // pic_mem_bytes,   
            // pic_mem_rd_req,
            // pic_mem_data,
            // pic_mem_data_vld,

            // wgt_mem_start_addr, 
            // wgt_mem_bytes ,
            // wgt_mem_rd_req,
            // wgt_mem_data, 
            // wgt_mem_data_vld,

            // out_mem_start_addr, 
            // out_mem_bytes,
            // out_mem_wr_req,
            // out_mem_ack,

            mem_intf_write,
            mem_intf_read_pic,
            mem_intf_read_wgt,
            
            cnn_sw_busy_ind,
            sw_cnn_addr_x,
            sw_cnn_addr_y,
            sw_cnn_addr_z,
            sw_cnn_x_m,   
            sw_cnn_x_n,
            sw_cnn_y_m,
            sw_cnn_y_n,

            );
  
  
  parameter ADDR_WIDTH=12; //TODO: check width
  parameter MAX_BYTES_TO_RD=20;
  parameter LOG2_MAX_BYTES_TO_RD=$clog2(MAX_BYTES_TO_RD);  
  parameter MAX_BYTES_TO_WR=5;  
  parameter LOG2_MAX_BYTES_TO_WR=$clog2(MAX_BYTES_TO_WR);
  parameter MEM_DATA_BUS=128;
    
  
  input  clk;	//clock
  input  rst_n;	//reset negative
  
  //====================  
  //  Memory Interfaces
  //==================== 
  // input  [MEM_DATA_BUS-1:0]         pic_mem_data; //Data that was read from memory
  // input                             pic_mem_data_vld;	//Data valid indication 
  // output [ADDR_WIDTH-1:0]           pic_mem_start_addr;   //Output to memory –  request for data from this address on. 
  // output [LOG2_MAX_BYTES_TO_RD-1:0] pic_mem_bytes;   	//Output to memory – num of bytes to request
  // output                            pic_mem_rd_req;	//Output to memory – read request
  
  // input  [MEM_DATA_BUS-1:0]         wgt_mem_data; 	//Data that was read from memory
  // input                             wgt_mem_data_vld;	//Data valid indication  
  // output [ADDR_WIDTH-1:0]           wgt_mem_start_addr; 	//Output to memory – request for data from this address on.
  // output [LOG2_MAX_BYTES_TO_RD-1:0] wgt_mem_bytes; 	//Output to memory – num of bytes to request
  // output                            wgt_mem_rd_req;	//Output to memory – read request

  // input                             out_mem_ack;	//Indication that data was written to memory and can be deleted in the unit.
  // output [ADDR_WIDTH-1:0]           out_mem_start_addr; 	//Output to memory – request to write data to this address and on.
  // output [LOG2_MAX_BYTES_TO_WR-1:0] out_mem_bytes;	//Output to memory – num of bytes that the unit wants to write
  // output                            out_mem_wr_req;	//Output to memory – write request



  mem_intf_write           mem_intf_write;
  mem_intf_read            mem_intf_read_pic;
  mem_intf_read            mem_intf_read_wgt;
  
  //====================      
  // Software Interface
  //====================		
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_x;	//CNN Data window FIRST address
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_y;	//CNN  weights window FIRST address
  input [ADDR_WIDTH-1:0]            sw_cnn_addr_z;	//CNN return address
  input                             sw_cnn_x_m;  	//CNN data matrix num of rows
  input                             sw_cnn_x_n;	//CNN data matrix num of columns
  input                             sw_cnn_y_m;	//CNN weight matrix num of rows
  input                             sw_cnn_y_n;	//CNN weight matrix num of columns 
  output                            cnn_sw_busy_ind;	//An output to the software - 1 – CNN unit is busy CNN is available (Default)














  
endmodule
