
/*
* Main.sv
*
*  Author: Ilya Pikin
*/

module SpiTest
(
	input clkIn,
	input nResetIn,
	input ssIn,
	input mosiIn,
	input sckIn,
	output misoOut
);

localparam PACKET_SIZE = 8;
localparam BYTE_SIZE = 8;

wire ss;
wire mosi;
wire sck;

wire dataReceived;

wire [BYTE_SIZE * PACKET_SIZE - 1:0] dataRx;
reg [BYTE_SIZE * PACKET_SIZE - 1:0] dataTx;

RXMajority3Filter ssFilter(.clkIn(clkIn), .nResetIn(nResetIn), .in(ssIn), .out(ss));
RXMajority3Filter mosiFilter(.clkIn(clkIn), .nResetIn(nResetIn), .in(mosiIn), .out(mosi));
RXMajority3Filter sckFilter(.clkIn(clkIn), .nResetIn(nResetIn), .in(sckIn), .out(sck));

SpiSlave #(.PACKET_SIZE(PACKET_SIZE)) spiSlave(
	.clkIn(clkIn),
	.nResetIn(nResetIn),
	.ssIn(ss),
	.mosiIn(mosi),
	.sckIn(sck),
	.dataIn(dataTx),
	.dataOut(dataRx),
	.misoOut(misoOut),
	.dataReceivedOut(dataReceived),
	.emptyOut(),
	.busyOut()
);

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		dataTx = 0;
	end
	else if (dataReceived) begin
		dataTx <= dataRx;
	end
end

endmodule
