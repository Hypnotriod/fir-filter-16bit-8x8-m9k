
/*
* Main.sv
*
*  Author: Ilya Pikin
*/

module UART_TX
# (
	parameter CLOCK_FREQUENCY = 50_000_000,
	parameter BAUD_RATE       = 9600
)
(
	input  clkIn,
	input  nTxResetIn,
	input  [7:0] txDataIn,
	input  txLoadIn,
	output wire txIdleOut,
	output wire txReadyOut,
	output wire txOut
);

localparam HALF_BAUD_CLK_REG_VALUE = (CLOCK_FREQUENCY / BAUD_RATE / 2 - 1);

reg [$clog2(HALF_BAUD_CLK_REG_VALUE) - 1:0] txClkCounter;
reg txBaudClk;
reg [9:0] txReg;
reg [3:0] txCounter; 

assign txReadyOut = !txCounter[3:1];
assign txIdleOut  = txReadyOut & !txCounter[0];
assign txOut      = txReg[0];

always @(posedge clkIn) begin : tx_clock_generate
	if(txIdleOut & !txLoadIn) begin
		txClkCounter <= 0;
		txBaudClk    <= 1'b0;
	end
	else if(txClkCounter == 0) begin
		txClkCounter <= HALF_BAUD_CLK_REG_VALUE;
		txBaudClk    <= ~txBaudClk;
	end
	else begin
		txClkCounter <= txClkCounter - 1'b1;
	end
end

always @(posedge txBaudClk or negedge nTxResetIn) begin : tx_transmit
	if(!nTxResetIn) begin
		txCounter <= 4'h0;
		txReg[0]  <= 1'b1;
	end
	else if(!txReadyOut) begin
		txReg     <= {1'b0, txReg[9:1]};
		txCounter <= txCounter - 1'b1;
	end
	else if(txLoadIn) begin
		txReg     <= {1'b1, txDataIn[7:0], 1'b0};
		txCounter <= 4'hA;
	end
	else begin
		txCounter <= 4'h0;
	end
end

endmodule