//======================================================================================================
//
// Module: activation
//
// Design Unit Owner : Nitzan Dabush
//                    
// Original Author   : Nitzan Dabush
// Original Date     : 10-Mar-2021
//
//======================================================================================================

module activation (in, out);
  input signed [31:0] in;
  output [7:0] out;

  parameter WB_LOG2_SCALE = 7;  // Weights and Bias scale, typically 7 bits
  parameter UINT_DATA_WIDTH=8;  //TODO: Need to check if default/constant //number of bits for unsigned data, in our case 8 as we hold data in single byte.
  parameter LOG2_RELU_FACTOR=1; //  meta parameter for relu slope factoring for optimal clamping.

  localparam LOG2_SCALE = WB_LOG2_SCALE + LOG2_RELU_FACTOR;
  localparam MAX_SCALED_OUTPUT_DATA_RANGE = (1 << (UINT_DATA_WIDTH + LOG2_SCALE))-1'd1;  // for  UINT_DATA_WIDTH=8 this is same as 256*(2**log2_scale)

  wire [31:0] relu_in;
  wire [31:0] relu_clamp;
  wire [31:0] relu_clamp_descale;
  
  assign relu_in = (in < 0) ? 0  :  in;
  assign relu_clamp = (relu_in > MAX_SCALED_OUTPUT_DATA_RANGE)  ?  MAX_SCALED_OUTPUT_DATA_RANGE : relu_in;
  assign out = relu_clamp >> LOG2_SCALE;                          // Equivelent to relu_accum_clamp/(2**log2_scale). By above sequence data out is guaranteed not to exceed (2**UINT_DATA_WIDTH)-1 (=255) and provide a unsigned byte value between 0 and 255 , which is the unsigned input data for the next layer.
  


endmodule
