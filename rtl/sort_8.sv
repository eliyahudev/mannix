//======================================================================================================
//
// Module: sort_8
//
// Description: Output the bigger number of 8 inputs
//
//======================================================================================================
module sort_8 (
	input [7:0]      num1,
	input [7:0]      num2,
	input [7:0]      num3,
	input [7:0]      num4,
	input [7:0]      num5,
	input [7:0]      num6,
	input [7:0]      num7,
	input [7:0]      num8,

	output [7:0]     big  );   // biggest to out  
 
// local:
	wire [7:0] big1;
	wire [7:0] big2;

// instansiations:

	sort_4 sort_4_ins_1( .num1(num1), .num2(num2), .num3(num3), .num4(num4), .big(big1) );
	 
	sort_4 sort_4_ins_2( .num1(num5), .num2(num6), .num3(num7), .num4(num8), .big(big2) );	
	

	sort_xy sort_xy_ins( .num1(big1), .num2(big2), .big(big) );

endmodule // sort_8
