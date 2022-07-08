
/*
* Main.sv
*
*  Author: Ilya Pikin
*
*  Description:
*  This module does fir filter calculation of 16 bit samples.
*
*  Usage:
*  Data should be sent in packets via SPI (cpol=0, cpha=0) as {SAMPLES_NUM} of
*  16 bit samples data (msb first), followed by {SAMPLES_NUM * 2} of don't care bytes.
*  Each packet transaction user will grab {SAMPLES_NUM} of 32 bit computed samples
*  (msb first) back, delayed by two packet transactions.
*  {ssIn} signal can be not necessary toggled each packet transaction. 
*  But setting this signal high in the middle of transaction will abort it.
*  {SAMPLES_NUM} can range from 1 to 8
* 
*/

module Main
# (
	parameter SAMPLES_NUM = 8,
	parameter WORDS_NUM = 8192
)
(
	input clkIn,
	input nResetIn,
	input ssIn,
	input mosiIn,
	input sckIn,
	output misoOut,
	input firLoadIn,
	input firDataIn,
	input firSckIn
);

localparam BYTE_SIZE = 8;
localparam IN_SAMPLE_WIDTH = 16;
localparam OUT_SAMPLE_WIDTH = 32;
localparam PACKET_SIZE = SAMPLES_NUM * OUT_SAMPLE_WIDTH / BYTE_SIZE;
localparam FIR_PACKET_SIZE = SAMPLES_NUM * IN_SAMPLE_WIDTH / BYTE_SIZE;

reg [BYTE_SIZE * PACKET_SIZE * 2 - 1:0] dataBuff;

wire dataReceived;
wire [BYTE_SIZE * PACKET_SIZE - 1:0] dataRaw;
wire firDataReceived;
wire [IN_SAMPLE_WIDTH * SAMPLES_NUM - 1:0] firData;
wire [BYTE_SIZE * PACKET_SIZE - 1:0] dataComputed;
wire [IN_SAMPLE_WIDTH * SAMPLES_NUM - 1:0] dataLoad;

wire nReset;

wire clk;
wire ss;
wire mosi;
wire sck;

wire firLoad;
wire firDi;
wire firSck;

wire computationComplete;

generate
case (SAMPLES_NUM)
	1 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 2 - 1:IN_SAMPLE_WIDTH * 1]};
	2 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 3 - 1:IN_SAMPLE_WIDTH * 2],
		dataRaw[IN_SAMPLE_WIDTH * 4 - 1:IN_SAMPLE_WIDTH * 3]};
	3 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 4 - 1:IN_SAMPLE_WIDTH * 3],
		dataRaw[IN_SAMPLE_WIDTH * 5 - 1:IN_SAMPLE_WIDTH * 4],
		dataRaw[IN_SAMPLE_WIDTH * 6 - 1:IN_SAMPLE_WIDTH * 5]};
	4 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 5 - 1:IN_SAMPLE_WIDTH * 4],
		dataRaw[IN_SAMPLE_WIDTH * 6 - 1:IN_SAMPLE_WIDTH * 5],
		dataRaw[IN_SAMPLE_WIDTH * 7 - 1:IN_SAMPLE_WIDTH * 6],
		dataRaw[IN_SAMPLE_WIDTH * 8 - 1:IN_SAMPLE_WIDTH * 7]};
	5 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 6 - 1:IN_SAMPLE_WIDTH * 5],
		dataRaw[IN_SAMPLE_WIDTH * 7 - 1:IN_SAMPLE_WIDTH * 6],
		dataRaw[IN_SAMPLE_WIDTH * 8 - 1:IN_SAMPLE_WIDTH * 7],
		dataRaw[IN_SAMPLE_WIDTH * 9 - 1:IN_SAMPLE_WIDTH * 8],
		dataRaw[IN_SAMPLE_WIDTH * 10 - 1:IN_SAMPLE_WIDTH * 9]};
	6 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 7 - 1:IN_SAMPLE_WIDTH * 6],
		dataRaw[IN_SAMPLE_WIDTH * 8 - 1:IN_SAMPLE_WIDTH * 7],
		dataRaw[IN_SAMPLE_WIDTH * 9 - 1:IN_SAMPLE_WIDTH * 8],
		dataRaw[IN_SAMPLE_WIDTH * 10 - 1:IN_SAMPLE_WIDTH * 9],
		dataRaw[IN_SAMPLE_WIDTH * 11 - 1:IN_SAMPLE_WIDTH * 10],
		dataRaw[IN_SAMPLE_WIDTH * 12 - 1:IN_SAMPLE_WIDTH * 11]};
	7 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 8 - 1:IN_SAMPLE_WIDTH * 7],
		dataRaw[IN_SAMPLE_WIDTH * 9 - 1:IN_SAMPLE_WIDTH * 8],
		dataRaw[IN_SAMPLE_WIDTH * 10 - 1:IN_SAMPLE_WIDTH * 9],
		dataRaw[IN_SAMPLE_WIDTH * 11 - 1:IN_SAMPLE_WIDTH * 10],
		dataRaw[IN_SAMPLE_WIDTH * 12 - 1:IN_SAMPLE_WIDTH * 11],
		dataRaw[IN_SAMPLE_WIDTH * 13 - 1:IN_SAMPLE_WIDTH * 12],
		dataRaw[IN_SAMPLE_WIDTH * 14 - 1:IN_SAMPLE_WIDTH * 13]};
	8 : assign dataLoad = {
		dataRaw[IN_SAMPLE_WIDTH * 9 - 1:IN_SAMPLE_WIDTH * 8],
		dataRaw[IN_SAMPLE_WIDTH * 10 - 1:IN_SAMPLE_WIDTH * 9],
		dataRaw[IN_SAMPLE_WIDTH * 11 - 1:IN_SAMPLE_WIDTH * 10],
		dataRaw[IN_SAMPLE_WIDTH * 12 - 1:IN_SAMPLE_WIDTH * 11],
		dataRaw[IN_SAMPLE_WIDTH * 13 - 1:IN_SAMPLE_WIDTH * 12],
		dataRaw[IN_SAMPLE_WIDTH * 14 - 1:IN_SAMPLE_WIDTH * 13],
		dataRaw[IN_SAMPLE_WIDTH * 15 - 1:IN_SAMPLE_WIDTH * 14],
		dataRaw[IN_SAMPLE_WIDTH * 16 - 1:IN_SAMPLE_WIDTH * 15]};
endcase
endgenerate

Majority3Filter nResetFilter(.clkIn(clk), .in(nResetIn), .out(nReset));

Majority3Filter ssFilter(.clkIn(clk), .nResetIn(nReset), .in(ssIn), .out(ss));
Majority3Filter mosiFilter(.clkIn(clk), .nResetIn(nReset), .in(mosiIn), .out(mosi));
Majority3Filter sckFilter(.clkIn(clk), .nResetIn(nReset), .in(sckIn), .out(sck));

Majority3Filter firLoadFilter(.clkIn(clk), .nResetIn(nReset), .in(firLoadIn), .out(firLoad));
Majority3Filter firDataFilter(.clkIn(clk), .nResetIn(nReset), .in(firDataIn), .out(firDi));
Majority3Filter firSckFilter(.clkIn(clk), .nResetIn(nReset), .in(firSckIn), .out(firSck));

Pll100MHz pll100MHz(
	.inclk0(clkIn),
	.c0(clk)
);

SpiSlave #(.PACKET_SIZE(PACKET_SIZE)) dataSpi(
	.clkIn(clk),
	.nResetIn(nReset),
	.ssIn(ss),
	.mosiIn(mosi),
	.sckIn(sck),
	.dataIn(dataBuff[BYTE_SIZE * PACKET_SIZE * 2 - 1:BYTE_SIZE * PACKET_SIZE]),
	.dataOut(dataRaw),
	.misoOut(misoOut),
	.dataReceivedOut(dataReceived),
	.emptyOut(),
	.busyOut()
);

SpiSlave #(.PACKET_SIZE(FIR_PACKET_SIZE)) firSpi(
	.clkIn(clk),
	.nResetIn(nReset),
	.ssIn(~firLoad),
	.mosiIn(firDi),
	.sckIn(firSck),
	.dataIn(0),
	.dataOut(firData),
	.dataReceivedOut(firDataReceived),
	.misoOut(),
	.emptyOut(),
	.busyOut()
);

FirFilter #(.SAMPLES_NUM(SAMPLES_NUM), .WORDS_NUM(WORDS_NUM)) firFilter(
	.clkIn(clk),
	.nResetIn(nReset),
	.startIn(dataReceived),
	.dataIn(dataLoad),
	.firLoadIn(firLoad),
	.firWriteIn(firDataReceived),
	.firIn(firData),
	.dataOut(dataComputed),
	.doneOut(computationComplete),
	.busyOut()
);

always @(posedge clk or negedge nReset) begin
	if (!nReset) begin
		dataBuff <= 0;
	end
	else begin
		if (computationComplete) begin
			dataBuff[BYTE_SIZE * PACKET_SIZE - 1:0] <= dataComputed;
		end
		if (dataReceived) begin
			dataBuff[BYTE_SIZE * PACKET_SIZE * 2 - 1:BYTE_SIZE * PACKET_SIZE] <= dataBuff[BYTE_SIZE * PACKET_SIZE - 1:0];
		end
	end
end

endmodule
