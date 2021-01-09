//======================================================================================================
//
// Module: dot_product_parallel
//
// Design Unit Owner : Dor Shilo & Nitzan Dabush
//                    
// Original Author   : Dor Shilo & Nitzan Dabush
// Original Date     : 22-Nov-2020
//
//======================================================================================================
module dot_product_parallel (a, b, res);
 parameter DEPTH=4;
  input signed [7:0] a [0:DEPTH-1];
  input signed [7:0] b [0:DEPTH-1];
  output signed [16:0] res ;

  wire signed [16:0] res_sum [0:DEPTH-1];

   wire signed [16:0] res_tmp [0:DEPTH-1];
  
  genvar       i;
generate
  assign res_sum[0]=res_tmp[0]+res_tmp[1];
  
  for (i=0;i<DEPTH;i++)
    begin
      dot_product dp_ins (.a(a[i]), .b(b[i]), .res(res_tmp[i]));
      assign res_sum[i+1]=res_sum[i]+res_tmp[i+2];
    end
  endgenerate

  assign res=res_sum[DEPTH-2];

endmodule
