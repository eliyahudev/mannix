//======================================================================================================
//
// Module: dot_product
//
// Design Unit Owner : Dor Shilo & Nitzan Dabush
//                    
// Original Author   : Dor Shilo & Nitzan Dabush
// Original Date     : 22-Nov-2020
//
//======================================================================================================

module dot_product (a, b, res);
 parameter DEPTH=4;
  input [7:0] a;
  input [7:0] b;
  output[16:0] res;

  assign res=a*b;

endmodule