
/*
* SpiSlave.sv
*
*  Author: Ilya Pikin
*/

module SpiSlave
# (
	parameter PACKET_SIZE = 2
)
(
	input clkIn,
	input nResetIn,
	input ssIn,
	input mosiIn,
	input sckIn,
	input [BYTE_SIZE * PACKET_SIZE - 1:0] dataIn,
	output [BYTE_SIZE * PACKET_SIZE - 1:0] dataOut,
	output misoOut,
	output dataReceivedOut,
	output emptyOut,
	output busyOut
);

localparam BYTE_SIZE = 8;

reg [$clog2(BYTE_SIZE * PACKET_SIZE - 1) - 1:0] bitsCounter;
reg [BYTE_SIZE * PACKET_SIZE - 1:0] dataShift;
reg [BYTE_SIZE * PACKET_SIZE - 1:0] dataPacket;
reg dataReceived;
reg empty;
reg sckState;
reg ssState;
reg mosi;

assign dataReceivedOut = dataReceived;
assign emptyOut = empty;
assign busyOut = ~ssIn;
assign dataOut = dataPacket;
assign misoOut = dataShift[BYTE_SIZE * PACKET_SIZE - 1];

always @(posedge clkIn) ssState <= ssIn;

always @(posedge clkIn or negedge nResetIn) begin
	if (!nResetIn) begin
		sckState <= 0;
		dataShift <= 0;
		dataReceived <= 0;
		empty <= 0;
		dataPacket <= 0;
		bitsCounter <= BYTE_SIZE * PACKET_SIZE - 1;
	end
	else if (ssState && !ssIn) begin
		dataReceived <= 0;
		empty <= 0;
		bitsCounter <= BYTE_SIZE * PACKET_SIZE - 1;
		dataShift <= dataIn;
	end
	else if (!sckState && sckIn) begin
		sckState <= 1;
		mosi <= mosiIn;
		dataReceived <= (bitsCounter == 0);
		empty <= 0;
		if (bitsCounter == 0) begin
			dataPacket <= {dataShift[BYTE_SIZE * PACKET_SIZE - 2:0], mosiIn};
		end
	end
	else if (sckState && !sckIn) begin
		sckState <= 0;
		dataReceived <= 0;
		empty <= (bitsCounter == 1);
		if (bitsCounter == 0) begin
			bitsCounter <= BYTE_SIZE * PACKET_SIZE - 1;
			dataShift <= dataIn;
		end
		else begin
			bitsCounter <= bitsCounter - 1;
			dataShift <= {dataShift[BYTE_SIZE * PACKET_SIZE - 2:0], mosi};
		end
	end
	else begin
		empty <= 0;
		dataReceived <= 0;
	end
end

endmodule
