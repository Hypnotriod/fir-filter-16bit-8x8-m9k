
/*
* Main.sv
*
*  Author: Ilya Pikin
*/

module Main
(
	input clkIn,
	input nResetIn,
	input ssIn,
	input mosiIn,
	input sckIn,
	output misoOut
);

localparam PACKET_SIZE = 8;
localparam SAMPLES_NUM = 2;
localparam BYTE_SIZE = 8;
localparam SAMPLE_WIDTH = 16;

wire dataReceived;
wire [BYTE_SIZE * PACKET_SIZE - 1:0] dataRaw;
wire [BYTE_SIZE * PACKET_SIZE - 1:0] dataComputed;

wire [SAMPLE_WIDTH * SAMPLES_NUM - 1:0] dataLoad = {
	dataRaw[SAMPLE_WIDTH * 3 - 1:SAMPLE_WIDTH * 2], 
	dataRaw[SAMPLE_WIDTH * 4 - 1:SAMPLE_WIDTH * 3]};

wire clk;
wire ss;
wire mosi;
wire sck;

RXMajority3Filter ssFilter(.clkIn(clk), .nResetIn(nResetIn), .in(ssIn), .out(ss));
RXMajority3Filter mosiFilter(.clkIn(clk), .nResetIn(nResetIn), .in(mosiIn), .out(mosi));
RXMajority3Filter sckFilter(.clkIn(clk), .nResetIn(nResetIn), .in(sckIn), .out(sck));

Pll100MHz pll100MHz(
	.inclk0(clkIn),
	.c0(clk)
);

SpiSlave #(.PACKET_SIZE(PACKET_SIZE)) spiSlave(
	.clkIn(clk),
	.nResetIn(nResetIn),
	.ssIn(ss),
	.mosiIn(mosi),
	.sckIn(sck),
	.dataIn(dataComputed),
	.dataOut(dataRaw),
	.misoOut(misoOut),
	.dataReceivedOut(dataReceived)
	//.emptyOut(),
	//.busyOut()
);

FirFilter #(.SAMPLES_NUM(SAMPLES_NUM)) firFilter(
	.clkIn(clk),
	.nResetIn(nResetIn),
	.startIn(dataReceived),
	.dataIn(dataLoad),
	//.doneOut(),
	//.busyOut(),
	.dataOut(dataComputed)
);

endmodule
