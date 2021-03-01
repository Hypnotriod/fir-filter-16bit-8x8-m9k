
/*
* FirFilter.sv
*
*  Author: Ilya Pikin
*/

module FirFilter
# (
	parameter SAMPLES_NUM = 4
)
(
	input clkIn,
	input nResetIn,
	input startIn,
	input [SAMPLE_WIDTH * SAMPLES_NUM - 1:0] dataIn,
	output doneOut,
	output busyOut,
	output [32 * SAMPLES_NUM - 1:0] dataOut
);

localparam SAMPLE_WIDTH = 16;
localparam WORD_WIDTH = 128;
localparam WORDS_NUM = 1024;
localparam TOTAL_WIDTH = WORD_WIDTH + SAMPLE_WIDTH * SAMPLES_NUM;

reg [WORD_WIDTH + SAMPLE_WIDTH * SAMPLES_NUM - 1:0] buffShifter;
reg [WORD_WIDTH - 1:0] firReg;
reg [$clog2(WORDS_NUM) - 1:0] wordIndex;
reg [33:0] accumulator[SAMPLES_NUM];
reg buffWren;
reg memoryDelay;
reg busy;
reg done;

wire [TOTAL_WIDTH - 1:0] buffDataLoad;
wire [TOTAL_WIDTH - 1:0] buffDataShift;
wire [33:0] multAddResult1[SAMPLES_NUM];
wire [33:0] multAddResult2[SAMPLES_NUM];
wire [33:0] parallelAddResult[SAMPLES_NUM];
wire [WORD_WIDTH - 1:0] firWord;
wire [WORD_WIDTH - 1:0] buffWord;

genvar i;
integer n;

assign doneOut = done;
assign busyOut = busy;
assign buffDataLoad = {dataIn, buffWord};
assign buffDataShift = {buffShifter[SAMPLE_WIDTH * SAMPLES_NUM - 1:0], buffWord};

ROM1 firStorage(
	.clock(~clkIn),
	.address(wordIndex),
	.q(firWord)
);

RAM1 buffStorage (
	.clock(~clkIn),
	.address(wordIndex),
	.wren(buffWren),
	.data(buffShifter[TOTAL_WIDTH - 1:SAMPLE_WIDTH * SAMPLES_NUM]),
	.q(buffWord)
);

function [31:0] normalize ([33:0] value);
	begin
		case ({value[33], value[32], value[31]})
			3'b100, 3'b101, 3'b110: normalize = 32'h80000000;
			3'b011, 3'b001, 3'b010: normalize = 32'h7FFFFFFF;
			default: normalize = value[31:0];
		endcase
	end
endfunction

generate
    for (i = 0; i < SAMPLES_NUM; i = i + 1) begin : accumulators_generation
    MultAdd multAdd1(
		.clock0(~clkIn & busy),
		.dataa_0(firReg[SAMPLE_WIDTH * 1 - 1:SAMPLE_WIDTH * 0]),
		.datab_0(buffShifter[SAMPLE_WIDTH * (2 + i) - 1:SAMPLE_WIDTH * (1 + i)]),
		.dataa_1(firReg[SAMPLE_WIDTH * 2 - 1:SAMPLE_WIDTH * 1]),
		.datab_1(buffShifter[SAMPLE_WIDTH * (3 + i) - 1:SAMPLE_WIDTH * (2 + i)]),
		.dataa_2(firReg[SAMPLE_WIDTH * 3 - 1:SAMPLE_WIDTH * 2]),
		.datab_2(buffShifter[SAMPLE_WIDTH * (4 + i) - 1:SAMPLE_WIDTH * (3 + i)]),
		.dataa_3(firReg[SAMPLE_WIDTH * 4 - 1:SAMPLE_WIDTH * 3]),
		.datab_3(buffShifter[SAMPLE_WIDTH * (5 + i) - 1:SAMPLE_WIDTH * (4 + i)]),
		.result(multAddResult1[i])
	);

	MultAdd multAdd2(
		.clock0(~clkIn & busy),
		.dataa_0(firReg[SAMPLE_WIDTH * 5 - 1:SAMPLE_WIDTH * 4]),
		.datab_0(buffShifter[SAMPLE_WIDTH * (6 + i) - 1:SAMPLE_WIDTH * (5 + i)]),
		.dataa_1(firReg[SAMPLE_WIDTH * 6 - 1:SAMPLE_WIDTH * 5]),
		.datab_1(buffShifter[SAMPLE_WIDTH * (7 + i) - 1:SAMPLE_WIDTH * (6 + i)]),
		.dataa_2(firReg[SAMPLE_WIDTH * 7 - 1:SAMPLE_WIDTH * 6]),
		.datab_2(buffShifter[SAMPLE_WIDTH * (8 + i) - 1:SAMPLE_WIDTH * (7 + i)]),
		.dataa_3(firReg[SAMPLE_WIDTH * 8 - 1:SAMPLE_WIDTH * 7]),
		.datab_3(buffShifter[SAMPLE_WIDTH * (9 + i) - 1:SAMPLE_WIDTH * (8 + i)]),
		.result(multAddResult2[i])
	);

	ParallelAdd parallelAdd(
		.clock(~clkIn & busy),
		.data0x(multAddResult1[i]),
		.data1x(multAddResult2[i]),
		.result(parallelAddResult[i])
	);
end 
case (SAMPLES_NUM)
	1 : assign dataOut = {normalize(accumulator[0])};
	2 : assign dataOut = {normalize(accumulator[0]), normalize(accumulator[1])};
	3 : assign dataOut = {normalize(accumulator[0]), normalize(accumulator[1]), 
								 normalize(accumulator[2])};
	4 : assign dataOut = {normalize(accumulator[0]), normalize(accumulator[1]), 
								 normalize(accumulator[2]), normalize(accumulator[3])};
	5 : assign dataOut = {normalize(accumulator[0]), normalize(accumulator[1]), 
								 normalize(accumulator[2]), normalize(accumulator[3]),
								 normalize(accumulator[4])};
	6 : assign dataOut = {normalize(accumulator[0]), normalize(accumulator[1]), 
								 normalize(accumulator[2]), normalize(accumulator[3]),
								 normalize(accumulator[4]), normalize(accumulator[5])};
	7 : assign dataOut = {normalize(accumulator[0]), normalize(accumulator[1]), 
								 normalize(accumulator[2]), normalize(accumulator[3]),
								 normalize(accumulator[4]), normalize(accumulator[5]),
								 normalize(accumulator[6])};
	8 : assign dataOut = {normalize(accumulator[0]), normalize(accumulator[1]), 
								 normalize(accumulator[2]), normalize(accumulator[3]),
								 normalize(accumulator[4]), normalize(accumulator[5]),
								 normalize(accumulator[6]), normalize(accumulator[7])};
endcase
endgenerate

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		for (n = 0; n < SAMPLES_NUM; n = n + 1) begin
			accumulator[n] <= 0;
		end
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
		for (n = 0; n < SAMPLES_NUM; n = n + 1) begin
			accumulator[n] <= 0;
		end
		buffShifter <= buffDataLoad;
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
		for (n = 0; n < SAMPLES_NUM; n = n + 1) begin
			accumulator[n] <= parallelAddResult[n] + accumulator[n];
		end
		buffShifter <= buffDataShift;
		firReg <= firWord;
	end
	else if(busy) begin
		for (n = 0; n < SAMPLES_NUM; n = n + 1) begin
			accumulator[n] <= parallelAddResult[n] + accumulator[n];
		end
		busy <= 0;
		done <= 1;
	end
	else if(done == 1) begin
		done <= 0;
	end
end


endmodule
