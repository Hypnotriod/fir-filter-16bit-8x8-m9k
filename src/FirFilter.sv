
/*
* FirFilter.sv
*
*  Author: Ilya Pikin
*/

module FirFilter
# (
	parameter SAMPLES_NUM = 4,
	parameter WORDS_NUM = 4
)
(
	input clkIn,
	input nResetIn,
	input startIn,
	input [IN_SAMPLE_WIDTH * SAMPLES_NUM - 1:0] dataIn,
	output doneOut,
	output busyOut,
	output [OUT_SAMPLE_WIDTH * SAMPLES_NUM - 1:0] dataOut
);

localparam IN_SAMPLE_WIDTH = 16;
localparam OUT_SAMPLE_WIDTH = 32;
localparam WORD_WIDTH = 128;
localparam RESULT_DELAY = 3;
localparam BUFF_WIDTH = WORD_WIDTH + IN_SAMPLE_WIDTH * SAMPLES_NUM;

reg [BUFF_WIDTH - 1:0] buffShifter;
reg [WORD_WIDTH - 1:0] firReg;
reg [$clog2(WORDS_NUM) - 1:0] rdWordIndex;
reg [$clog2(WORDS_NUM) - 1:0] wrWordIndex;
reg signed [33:0] accumulator[SAMPLES_NUM];
reg [$clog2(RESULT_DELAY) - 1:0] resultDelay;
reg buffWren;
reg busy;
reg done;
reg clear;

wire [BUFF_WIDTH - 1:0] buffDataLoad;
wire [BUFF_WIDTH - 1:0] buffDataShift;
wire [WORD_WIDTH - 1:0] buffDataStore;
wire signed [33:0] multAddResult1[SAMPLES_NUM];
wire signed [33:0] multAddResult2[SAMPLES_NUM];
wire signed [33:0] parallelAddResult[SAMPLES_NUM];
wire [WORD_WIDTH - 1:0] firWord;
wire [WORD_WIDTH - 1:0] buffWord;

genvar i;
integer n;

assign doneOut = done;
assign busyOut = busy;
assign buffDataLoad = {dataIn, buffWord};
assign buffDataShift = {buffShifter[IN_SAMPLE_WIDTH * SAMPLES_NUM - 1:0], buffWord};
assign buffDataStore = buffShifter[BUFF_WIDTH - 1:IN_SAMPLE_WIDTH * SAMPLES_NUM];

FirRam firStorage(
	.clock(~clkIn),
	.address(rdWordIndex),
	.wren(0), // TODO: Add possibility to update fir data
	.data(0),
	.q(firWord)
);

BufferRam buffStorage (
	.clock(~clkIn),
	.rdaddress(rdWordIndex),
	.wraddress(wrWordIndex),
	.wren(buffWren),
	.data(buffDataStore),
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
		.clock0(~clkIn),
		.aclr3(clear),
		.ena0(busy),
		.dataa_0(firReg[IN_SAMPLE_WIDTH * 1 - 1:IN_SAMPLE_WIDTH * 0]),
		.datab_0(buffShifter[IN_SAMPLE_WIDTH * (2 + i) - 1:IN_SAMPLE_WIDTH * (1 + i)]),
		.dataa_1(firReg[IN_SAMPLE_WIDTH * 2 - 1:IN_SAMPLE_WIDTH * 1]),
		.datab_1(buffShifter[IN_SAMPLE_WIDTH * (3 + i) - 1:IN_SAMPLE_WIDTH * (2 + i)]),
		.dataa_2(firReg[IN_SAMPLE_WIDTH * 3 - 1:IN_SAMPLE_WIDTH * 2]),
		.datab_2(buffShifter[IN_SAMPLE_WIDTH * (4 + i) - 1:IN_SAMPLE_WIDTH * (3 + i)]),
		.dataa_3(firReg[IN_SAMPLE_WIDTH * 4 - 1:IN_SAMPLE_WIDTH * 3]),
		.datab_3(buffShifter[IN_SAMPLE_WIDTH * (5 + i) - 1:IN_SAMPLE_WIDTH * (4 + i)]),
		.result(multAddResult1[i])
	);

	MultAdd multAdd2(
		.clock0(~clkIn),
		.aclr3(clear),
		.ena0(busy),
		.dataa_0(firReg[IN_SAMPLE_WIDTH * 5 - 1:IN_SAMPLE_WIDTH * 4]),
		.datab_0(buffShifter[IN_SAMPLE_WIDTH * (6 + i) - 1:IN_SAMPLE_WIDTH * (5 + i)]),
		.dataa_1(firReg[IN_SAMPLE_WIDTH * 6 - 1:IN_SAMPLE_WIDTH * 5]),
		.datab_1(buffShifter[IN_SAMPLE_WIDTH * (7 + i) - 1:IN_SAMPLE_WIDTH * (6 + i)]),
		.dataa_2(firReg[IN_SAMPLE_WIDTH * 7 - 1:IN_SAMPLE_WIDTH * 6]),
		.datab_2(buffShifter[IN_SAMPLE_WIDTH * (8 + i) - 1:IN_SAMPLE_WIDTH * (7 + i)]),
		.dataa_3(firReg[IN_SAMPLE_WIDTH * 8 - 1:IN_SAMPLE_WIDTH * 7]),
		.datab_3(buffShifter[IN_SAMPLE_WIDTH * (9 + i) - 1:IN_SAMPLE_WIDTH * (8 + i)]),
		.result(multAddResult2[i])
	);

	ParallelAdd parallelAdd(
		.aclr(clear),
		.clken(busy),
		.clock(~clkIn),
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
		rdWordIndex <= 0;
		wrWordIndex <= 0;
		busy <= 0;
		done <= 0;
		clear <= 0;
		buffWren <= 0;
		resultDelay <= 0;
	end
	else if (startIn && !busy) begin
		resultDelay <= RESULT_DELAY;
		busy <= 1;
		done <= 0;
		clear <= 1;
		buffWren <= 0;
		for (n = 0; n < SAMPLES_NUM; n = n + 1) begin
			accumulator[n] <= 0;
		end
		rdWordIndex <= 1;
		wrWordIndex <= WORDS_NUM - 1;
	end
	else if (busy) begin
		clear <= 0;
		
		if (rdWordIndex != 0 || wrWordIndex != WORDS_NUM - 1) begin
			buffWren <= 1;
			if (rdWordIndex != 0) rdWordIndex <= rdWordIndex + 1;
			wrWordIndex <= wrWordIndex + 1;
			firReg <= firWord;
			buffShifter <= !buffWren ? buffDataLoad : buffDataShift;
		end
		else begin
			buffWren <= 0;
			resultDelay <= resultDelay - 1;
		end
		
		for (n = 0; n < SAMPLES_NUM; n = n + 1) begin
			accumulator[n] <= parallelAddResult[n] + accumulator[n];
		end
		
		if (resultDelay == 0) begin
			busy <= 0;
			done <= 1;
		end
	end
	else if (done == 1) begin
		done <= 0;
	end
end


endmodule
