
/*
* Main.sv
*
*  Author: Ilya Pikin
*/

module UART_RX
# (
	parameter CLOCK_FREQUENCY = 50_000_000,
	parameter BAUD_RATE       = 9600
)
(
	input  clkIn,
	input  nRxResetIn,
	input  rxIn, 
	output wire rxIdleOut,
	output wire rxReadyOut,
	output wire [7:0] rxDataOut
);

localparam HALF_BAUD_CLK_REG_VALUE = (CLOCK_FREQUENCY / BAUD_RATE / 2 - 1);

reg [$clog2(HALF_BAUD_CLK_REG_VALUE) - 1:0] rxClkCounter;
reg rxBaudClk;
reg [9:0] rxReg;
reg [1:0] readyStatus;

assign rxIdleOut      = ~rxReg[0];
assign rxReadyOut     = readyStatus[0];
assign rxDataOut[7:0] = rxReg[8:1];

always @(posedge clkIn) begin : rx_clock_generate
	if(rxIn & rxIdleOut) begin
		rxClkCounter <= HALF_BAUD_CLK_REG_VALUE;
		rxBaudClk    <= 0;
	end
	else if(rxClkCounter == 0) begin
		rxClkCounter <= HALF_BAUD_CLK_REG_VALUE;
		rxBaudClk    <= ~rxBaudClk;
	end
	else begin
		rxClkCounter <= rxClkCounter - 1'b1;
	end
	
	case ({readyStatus[1], readyStatus[0], rxReg[9], rxIdleOut})
		4'b0011 : readyStatus <= 2'b11;
		4'b1111, 4'b1011 : readyStatus <= 2'b10;
		default : readyStatus <= 2'b00;
	endcase
end

always @(posedge rxBaudClk or negedge nRxResetIn) begin : rx_receive
	if(!nRxResetIn) begin
		rxReg <= 10'h000;
	end
	else if(!rxIdleOut) begin
		rxReg <= {rxIn, rxReg[9:1]};
	end
	else if(!rxIn) begin
		rxReg <= 10'h1FF;
	end
end

endmodule