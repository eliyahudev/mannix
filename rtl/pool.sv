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
            
            pool_sw_busy_ind,
            sw_pool_rd_addr,
            sw_pool_wr_addr,
            sw_pool_rd_m,   
            sw_pool_rd_n,
            sw_pool_m,   
            sw_pool_n   

            );
  
  
  parameter ADDR_WIDTH=12; //TODO: check width
  parameter MAX_BYTES_TO_RD=20;
  parameter LOG2_MAX_BYTES_TO_RD=$clog2(MAX_BYTES_TO_RD);  
  parameter MAX_BYTES_TO_WR=5;  
  parameter LOG2_MAX_BYTES_TO_WR=$clog2(MAX_BYTES_TO_WR);
  parameter MEM_DATA_BUS=128;
  
  parameter DATA_ROWS_NUM=4;  
  parameter DATA_COLS_NUM=4;  
  parameter DATA_LOG2_ROWS_NUM = $clog2(DATA_ROWS_NUM);
  parameter DATA_LOG2_COLS_NUM = $clog2(DATA_COLS_NUM);

  parameter RES_ROWS_NUM=2;
  parameter RES_COLS_NUM=2;
  parameter OUT_LOG2_ROWS_NUM=$clog2(RES_ROWS_NUM);
  parameter OUT_LOG2_COLS_NUM=$clog2(RES_COLS_NUM);

  input  clk;	//clock
  input  rst_n;	//reset negative
  
  //====================  
  //  Memory Interfaces
  //==================== 

  mem_intf_write.client_write           mem_intf_write;
  mem_intf_read.client_read            mem_intf_read_mx;

  
  //====================      
  // Software Interface
  //====================		
  input [ADDR_WIDTH-1:0]            sw_pool_rd_addr;	//POOL Data matrix FIRST address
  input [ADDR_WIDTH-1:0]            sw_pool_wr_addr;	//POOL return address
  input [DATA_LOG2_ROWS_NUM-1:0]    sw_pool_rd_m;  	//POOL data matrix num of rows
  input [DATA_LOG2_COLS_NUM-1:0]    sw_pool_rd_n;	//POOL data matrix num of columns
  input [OUT_LOG2_ROWS_NUM-1:0]     sw_pool_m;	//POOL size - rows
  input [OUT_LOG2_COLS_NUM-1:0]     sw_pool_n;	//POOL size - columns 
  output                            pool_sw_busy_ind;	//An output to the software - 1 – POOL unit is busy - 0 -POOL is available (Default)



  
endmodule
