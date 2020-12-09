//======================================================================================================
//
// Module: FCC
//
// Design Unit Owner : Dor Shilo 
//                    
// Original Author   : Dor Shilo 
// Original Date     : 3-Dec-2020
//
//======================================================================================================

module fcc (clk,FC_ADDRX,FC_ADDRY,FC_ADDRB,FC_ADDRZ,FC_XM,FC_YM,FC_YN,CNN_BN,GO,DONE,READ, WRITE);
//======================================================================================================
//
// Inputs\Outputs
//
// Owner : Dor Shilo 
//                    
// Inputs:
//		1) FC_ADDRX - 32 bits - Data Vector start address 			  - 0x0040
//		2) FC_ADDRY - 32 bits - Weights matrix start address    	  - 0x0044
//		3) FC_ADDRB - 32 bits - Bias vector start address 		   	  - 0x
//		4) FC_XM    - 32 bits - Data vector input length 			  - 0x004B
//		5) FC_YM    - 32 bits - Weights matrix input length 		  - 0x0050
//		6) FC_YN    - 32 bits - Weights matrix input width		   	  - 0x0054
//		7) CNN_BN   - 32 bits - Bias vector input length			  - 0x0058
//		8) GO		- 1 bit   - Alerting the previous system finished - 0x
// 
// Outputs:
//		1) FC_ADDRZ	- 32 bits - Z matrix start address 				  - 0x0048
//		2) DONE     - 1 bit   - Alerting the FC system finished 	  - 0x
//
//======================================================================================================
  input clk;
  
  //input [7:0] MEM_DATA   [7:0] //Simulating the memory data - 8 values of 8 bit
  //input [7:0] MEM_WEIGHT [63:0]//Simulating the memory weights - 8x8 values of 8 bit
  
  input [31:0] FC_ADDRX; 
  input [31:0] FC_ADDRY;
  input [31:0] FC_ADDRB;
  input [31:0] FC_XM;
  input [31:0] FC_YM;
  input [31:0] FC_YN;
  input [31:0] CNN_BN;
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
//    2) 8 bytes of weigths matrix                 
//
// The module will calculate the output vector Z in serial -
// 
//	* every time the module is able to preform a calculation (recived enough bytes)
//	  - the module will calculte the index of Z he is able to.
//  * TBV - For now ill assume every 8 bytes is a complete line of matrix
//  * TBC - For now ill assume i get 32 bits (4bytes) each request
//  
//======================================================================================================






endmodule
