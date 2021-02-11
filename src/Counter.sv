
/*
* Counter.sv
*
*  Author: Ilya Pikin
*/

module Counter
# (
	parameter TOP = 2
)
(
	input clkIn,
	input nResetIn,
	output [$clog2(TOP) - 1:0] counterOut,
	output counterOverflowOut
);

reg [$clog2(TOP - 1):0] counter;
reg counterOverflow;

initial begin
	counter = 0;
end

assign counterOut = counter;
assign counterOverflowOut = counterOverflow;

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		counter <= 0;
		counterOverflow <= 0;
	end
	else if (counter == TOP - 1) begin
		counter <= 0;
		counterOverflow <= 1;
	end
	else begin
		counter <= counter + 1;
		counterOverflow <= 0;
	end
end
	 
endmodule
