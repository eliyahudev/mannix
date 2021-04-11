//======================================================================================================
//
// Module: sort_xy
//
// Description: Output the bigger number
//
//======================================================================================================
module sort_xy (
		num1,
		num2,
		big   );

  input [7:0] num1; 
  input [7:0] num2;
  output [7:0] big;  

  assign big = (num1>num2)? num1 : num2;
  
endmodule // sort_xy
