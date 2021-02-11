
/*
* Main.v
*
*  Author: Ilya Pikin
*/

module Main
(
	input clkIn,
	input nResetIn,
	input rxIn,
	output txOut,
	output [35:0] resultOut
);

localparam CLOCK_FREQUENCY = 50_000_000;
localparam BAUD_RATE = 9600;
localparam WORD_WIDTH = 128;
localparam WORDS_NUM = 1024;

reg [$clog2(WORDS_NUM) - 1:0] wordIndex;
reg [35:0] accumulator;
reg ramWren;
reg [7:0] txData;
reg txLoad;

wire [33:0] multAddResult1;
wire [33:0] multAddResult2;
wire [36:0] parallelAddResult;
wire [WORD_WIDTH - 1:0] firData;
wire [WORD_WIDTH - 1:0] buffData;
wire [7:0] rxData;
wire txIdle;
wire txReady;
wire rxIdle;
wire rxReady;
wire rxFiltered;

assign resultOut = accumulator;

initial begin
	ramWren <= 0;
	accumulator <= 0;
	wordIndex <= 0;
end

RXMajority3Filter rxMajority3Filter(
	.clkIn(clkIn),
	.nResetIn(nResetIn),
	.rxIn(rxIn),
	.rxOut(rxFiltered)
);

UART #(.CLOCK_FREQUENCY(CLOCK_FREQUENCY), .BAUD_RATE(BAUD_RATE))
	com(
	.clkIn(clkIn),
	.nTxResetIn(nResetIn),
	.nRxResetIn(nResetIn),
	.txDataIn(txData),
	.txLoadIn(txLoad),
	.txIdleOut(txIdle),
	.txReadyOut(txReady),
	.txOut(txOut),
	.rxIn(rxFiltered),
	.rxIdleOut(rxIdle),
	.rxReadyOut(rxReady),
	.rxDataOut(rxData)
);

ROM1 rom(
	.clock(clkIn),
	.address(wordIndex),
	.q(firData)
);

RAM1 ram (
	.clock(clkIn),
	.address(wordIndex),
	.wren(ramWren),
	.data(0),
	.q(buffData)
);

MultAdd multAdd1(
	.clock0(clkIn),
	.dataa_0(firData[15:0]),
	.datab_0(buffData[15:0]),
	.dataa_1(firData[31:16]),
	.datab_1(buffData[31:16]),
	.dataa_2(firData[47:32]),
	.datab_2(buffData[47:32]),
	.dataa_3(firData[63:48]),
	.datab_3(buffData[63:48]),
	.result(multAddResult1)
);

MultAdd multAdd2(
	.clock0(clkIn),
	.dataa_0(firData[79:64]),
	.datab_0(buffData[79:64]),
	.dataa_1(firData[95:80]),
	.datab_1(buffData[95:80]),
	.dataa_2(firData[111:96]),
	.datab_2(buffData[111:96]),
	.dataa_3(firData[127:112]),
	.datab_3(buffData[127:112]),
	.result(multAddResult2)
);

ParallelAdd parallelAdd(
	.data0x(multAddResult1),
	.data1x(multAddResult2),
	.result(parallelAddResult)
);

always @(negedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		accumulator <= 0;
	end
	else begin
		if (wordIndex == 0) begin
			accumulator <= parallelAddResult;
		end
		else begin
			accumulator <= parallelAddResult + accumulator;
		end
	end
end

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		wordIndex <= 0;
		ramWren <= 0;
	end
	else begin
		wordIndex <= wordIndex + 1;
	end
end


endmodule
