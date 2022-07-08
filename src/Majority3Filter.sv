
/*
* Majority3Filter.sv
*
*  Author: Ilya Pikin
*/

module Majority3Filter
(
	input clkIn,
	input nResetIn,
	input in,
	output out
);

reg [2:0] rxShift;

initial begin
	rxShift = 3'b111;
end

assign out = (rxShift[0] & rxShift[1]) | (rxShift[0] & rxShift[2]) | (rxShift[1] & rxShift[2]);

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		rxShift = 3'b111;
	end
	else begin
		rxShift <= {in, rxShift[2:1]};
	end
end

endmodule
