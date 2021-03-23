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
  input        [7:0] a;
  input signed [7:0] b;
  output signed [31:0] res;

  assign res=$signed({1'b0,a})*b;

endmodule
