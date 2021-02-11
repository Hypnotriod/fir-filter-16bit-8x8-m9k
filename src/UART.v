
/*
* Main.sv
*
*  Author: Ilya Pikin
*/

module UART
# (
	parameter CLOCK_FREQUENCY = 50_000_000,
	parameter BAUD_RATE       = 9600
)
(
	input  clkIn,
	
	input  nTxResetIn,
	input  [7:0] txDataIn,
	input  txLoadIn,
	output txIdleOut,
	output txReadyOut,
	output txOut,
	
	input  nRxResetIn,
	input  rxIn, 
	output rxIdleOut,
	output rxReadyOut,
	output [7:0] rxDataOut
);

defparam  uart_tx.CLOCK_FREQUENCY = CLOCK_FREQUENCY;
defparam  uart_tx.BAUD_RATE       = BAUD_RATE;
UART_TX uart_tx
(
	.clkIn(clkIn),
	.nTxResetIn(nTxResetIn),
	.txDataIn(txDataIn),
	.txLoadIn(txLoadIn),
	.txIdleOut(txIdleOut),
	.txReadyOut(txReadyOut),
	.txOut(txOut)
);

defparam  uart_rx.CLOCK_FREQUENCY = CLOCK_FREQUENCY;
defparam  uart_rx.BAUD_RATE       = BAUD_RATE;
UART_RX uart_rx
(
	.clkIn(clkIn),
	.nRxResetIn(nRxResetIn),
	.rxIn(rxIn), 
	.rxIdleOut(rxIdleOut),
	.rxReadyOut(rxReadyOut),
	.rxDataOut(rxDataOut)
);

endmodule