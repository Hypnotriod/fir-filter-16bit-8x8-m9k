
/*
* ClockDivider.sv
*
*  Author: Ilya Pikin
*/

module ClockDivider
# (
	parameter VALUE = 2
)
(
	input clkIn,
	input nResetIn,
	output clkOut
);

Counter # (.TOP(VALUE)) counter (
	.clkIn(clkIn),
	.nResetIn(nResetIn),
	.counterOverflowOUT(clkOut)
);

endmodule
