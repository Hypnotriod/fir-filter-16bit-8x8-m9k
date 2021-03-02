
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
localparam IN_SAMPLE_WIDTH = 16;

reg [BYTE_SIZE * PACKET_SIZE * 2 - 1:0] dataBuff;

wire dataReceived;
wire [BYTE_SIZE * PACKET_SIZE - 1:0] dataRaw;
wire [BYTE_SIZE * PACKET_SIZE - 1:0] dataComputed;

wire [IN_SAMPLE_WIDTH * SAMPLES_NUM - 1:0] dataLoad = {
	dataRaw[IN_SAMPLE_WIDTH * 3 - 1:IN_SAMPLE_WIDTH * 2], 
	dataRaw[IN_SAMPLE_WIDTH * 4 - 1:IN_SAMPLE_WIDTH * 3]};

wire clk;
wire ss;
wire mosi;
wire sck;

wire computationComplete;

RXMajority3Filter ssFilter(.clkIn(clk), .nResetIn(nResetIn), .in(ssIn), .out(ss));
RXMajority3Filter mosiFilter(.clkIn(clk), .nResetIn(nResetIn), .in(mosiIn), .out(mosi));
RXMajority3Filter sckFilter(.clkIn(clk), .nResetIn(nResetIn), .in(sckIn), .out(sck));

Pll100MHz pll100MHz(
	.inclk0(clkIn),
	.c0(clk)
);

SpiSlave #(.PACKET_SIZE(PACKET_SIZE)) spiSlave(
	.clkIn(~clk),
	.nResetIn(nResetIn),
	.ssIn(ss),
	.mosiIn(mosi),
	.sckIn(sck),
	.dataIn(dataBuff[BYTE_SIZE * PACKET_SIZE * 2 - 1:BYTE_SIZE * PACKET_SIZE]),
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
	.doneOut(computationComplete),
	//.busyOut(),
	.dataOut(dataComputed)
);

always @(posedge clk or negedge nResetIn) begin
	if (!nResetIn) begin
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
