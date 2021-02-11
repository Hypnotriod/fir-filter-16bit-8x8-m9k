
/*
* RXMajority3Filter.sv
*
*  Author: Ilya Pikin
*/

module RXMajority3Filter
(
	input clkIn,
	input nResetIn,
	input rxIn,
	output rxOut
);

wire out;

reg [2:0] rxShift;

initial begin
	rxShift = 3'b111;
end

assign rxOut = out;
assign out = (rxShift[0] & rxShift[1]) | (rxShift[0] & rxShift[2]) | (rxShift[1] & rxShift[2]);

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		rxShift = 3'b111;
	end
	else begin
		rxShift <= {rxIn, rxShift[2:1]};
	end
end

endmodule
