//======================================================================================================
//
// Module: sort_4
//
// Description: Output the bigger number of 4 inputs
//
//======================================================================================================
module sort_4 (
	input [7:0]      num1,
	input [7:0]      num2,
	input [7:0]      num3,
	input [7:0]      num4,

	output [7:0]     big );  // biggest to out  

// local:
	wire [7:0] big1;
	wire [7:0] big2;

// instansiations:

	sort_xy sort_xy_ins_1( .num1(num1), .num2(num2), .big(big1) );
	 
	sort_xy sort_xy_ins_2( .num1(num3), .num2(num4), .big(big2) );	
	

	sort_xy sort_xy_ins_3( .num1(big1), .num2(big2), .big(big) );


endmodule // sort_4
