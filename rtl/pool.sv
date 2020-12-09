//======================================================================================================
//
// Module: pool
//
// Design Unit Owner : Nitzan Lalazar
//                    
// Original Author   : Netanel Lalazar
// Original Date     : 27-Nov-2020
//
//======================================================================================================
module pool (
            clk,
            rst_n,

            mem_intf_write,
            mem_intf_read_mx,
            
            cnn_sw_busy_ind,
            sw_cnn_pool_rd_addr,
            sw_pool_wr_addr,
            sw_cnn_pool_rd_m,   
            sw_cnn_pool_rd_n,
            sw_pool_m,   
            sw_pool_n   

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

  mem_intf_write           mem_intf_write;
  mem_intf_read            mem_intf_read_mx;

  
  //====================      
  // Software Interface
  //====================		
  input [ADDR_WIDTH-1:0]            sw_cnn_pool_rd_addr;	//POOL Data matrix FIRST address
  input [ADDR_WIDTH-1:0]            sw_pool_wr_addr;	//POOL return address
  input                             sw_cnn_pool_rd_m;  	//POOLdata matrix num of rows
  input                             sw_cnn_pool_rd_n;	//POOL data matrix num of columns
  input                             sw_pool_m;	//POOL size - rows
  input                             sw_pool_n;	//POOL size - columns 
  output                            cnn_sw_busy_ind;	//An output to the software - 1 – POOL unit is busy - 0 -POOL is available (Default)



  
endmodule
