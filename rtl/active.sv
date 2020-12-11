//======================================================================================================
//
// Module: FCC
//
// Design Unit Owner : Dor Shilo 
//                    
// Original Author   : Dor Shilo 
// Original Date     : 7-Dec-2020
//
//======================================================================================================

module active (READ,WRITE,clk,ACTIV_ADDRX,ACTIV_XM,ACTIV_YM,GO,FC_ADDRZ,DONE);
//======================================================================================================
//
// Inputs\Outputs
//
// Owner : Dor Shilo 
//                    
// Inputs:
//		1) ACTIV_ADDRX - 32 bits - Data Vector start address 			  - 0x0034
//		2) ACTIV_XM    - 32 bits - Data vector input length 			  - 0x0038
//		5) FC_XN       - 32 bits - Data matrix input width 		          - 0x003B
//		8) GO		   - 1 bit   - Alerting the previous system finished  - 0x
// 
// Outputs:
//		1) FC_ADDRZ	- 32 bits - Z matrix start address 				  - 0x0048
//		2) DONE     - 1 bit   - Alerting the FC system finished 	  - 0x
//
//======================================================================================================
  input clk;
  
  //input [7:0] MEM_DATA   [7:0] //Simulating the memory data - 8 values of 8 bit
  //input [7:0] MEM_WEIGHT [63:0]//Simulating the memory weights - 8x8 values of 8 bit
  
  input [31:0] ACTIV_ADDRX; 
  input [31:0] ACTIV_XM;
  input [31:0] ACTIV_YM;
  input GO;
  
  output [31:0] FC_ADDRZ;
  output DONE;
//======================================================================================================
// Interface instanciation 
//======================================================================================================
  mem_intf_read.client_read READ;
 mem_intf_write.client_write WRITE; 
//======================================================================================================
//
// Algorithem
//
// The module will recieve :
//    1) 8 bytes of data every rise of the GO 
//                
//
// The module will calculate the output vector Z in serial -
//  
//	*The module will normlaize every data to [0 1] fixed point value   
//======================================================================================================






endmodule
