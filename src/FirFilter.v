
/*
* FirFilter.v
*
*  Author: Ilya Pikin
*/

module FirFilter
(
	input clkIn,
	input nResetIn,
	input startIn,
	input [SAMPLE_WIDTH - 1:0] dataIn,
	output doneOut,
	output busyOut,
	output [35:0] dataOut,
	output [$clog2(WORDS_NUM) - 1:0] wordIndexOut
);

localparam MEMORY_DELAY = 1;
localparam SAMPLE_WIDTH = 16;
localparam WORD_WIDTH = 128;
localparam WORDS_NUM = 1024;

reg [WORD_WIDTH + SAMPLE_WIDTH - 1:0] buffShifter;
reg [WORD_WIDTH - 1:0] firReg;
reg [$clog2(WORDS_NUM) - 1:0] wordIndex;
reg [35:0] accumulator;
reg buffWren;
reg memoryDelay;
reg busy;
reg done;

wire [33:0] multAddResult1;
wire [33:0] multAddResult2;
wire [35:0] parallelAddResult;
wire [WORD_WIDTH - 1:0] firWord;
wire [WORD_WIDTH - 1:0] buffWord;

assign dataOut = accumulator;//buffWord[127:96];//firWord[127:96];//buffShifter[143:112];//accumulator;//parallelAddResult
assign doneOut = done;
assign busyOut = busy;
assign wordIndexOut = wordIndex;

ROM1 firStorage(
	.clock(~clkIn),
	.address(wordIndex),
	.q(firWord)
);

RAM1 buffStorage (
	.clock(~clkIn),
	.address(wordIndex),
	.wren(buffWren),
	.data(buffShifter[143:16]),
	.q(buffWord)
);

MultAdd multAdd1(
	.clock0(~clkIn & busy),
	.dataa_0(firReg[15:0]),
	.datab_0(buffShifter[31:16]),
	.dataa_1(firReg[31:16]),
	.datab_1(buffShifter[47:32]),
	.dataa_2(firReg[47:32]),
	.datab_2(buffShifter[63:48]),
	.dataa_3(firReg[63:48]),
	.datab_3(buffShifter[79:64]),
	.result(multAddResult1)
);

MultAdd multAdd2(
	.clock0(~clkIn & busy),
	.dataa_0(firReg[79:64]),
	.datab_0(buffShifter[95:80]),
	.dataa_1(firReg[95:80]),
	.datab_1(buffShifter[111:96]),
	.dataa_2(firReg[111:96]),
	.datab_2(buffShifter[127:112]),
	.dataa_3(firReg[127:112]),
	.datab_3(buffShifter[143:128]),
	.result(multAddResult2)
);

ParallelAdd parallelAdd(
	.clock(~clkIn & busy),
	.data0x(multAddResult1),
	.data1x(multAddResult2),
	.result(parallelAddResult)
);

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		accumulator <= 0;
		wordIndex <= 0;
		busy <= 0;
		done <= 0;
		buffWren <= 0;
		memoryDelay <= 0;
	end
	else if(startIn && !busy) begin
		busy <= 1;
		buffWren <= 1;
		memoryDelay <= 1;
		accumulator <= 0;
		buffShifter <= {dataIn, buffWord};
		firReg <= firWord;
	end
	else if (buffWren) begin
		buffWren <= 0;
		wordIndex <= wordIndex + 1;
	end
	else if (memoryDelay) begin
		memoryDelay <= 0;
	end
	else if(wordIndex != 0) begin
		buffWren <= 1;
		memoryDelay <= 1;
		accumulator <= parallelAddResult + accumulator;
		buffShifter <= {buffShifter[SAMPLE_WIDTH - 1:0], buffWord};
		firReg <= firWord;
	end
	else if(busy) begin
		accumulator <= parallelAddResult + accumulator;
		busy <= 0;
		done <= 1;
	end
	else if(done == 1) begin
		done <= 0;
	end
end


endmodule
