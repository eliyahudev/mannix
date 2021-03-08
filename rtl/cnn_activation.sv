//====================================================================================================
// Module: cnn_activation
//
// Design Unit Owner : Nitzan Dabush
//                    
// Original Author   : Nitzan Dabush
// Original Date     : 11-Jan-2021
//
//=====================================================================================================

module cnn_activation (in, out);
  input signed [31:0] in;
  output [7:0] out;

  assign out=(in > 31'sd127)? 8'd127: (in < -31'sd0)? 8'd0 : in[7:0];

endmodule
