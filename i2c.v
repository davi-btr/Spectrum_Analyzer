// ============================================================================
//
// Permission:
//
// ============================================================================
//
// Major Functions:I2C Finite State Machine
//
// ============================================================================
//
// Revision History :
// 
// ============================================================================

// ============================================================================

// ad ora ogni messaggio è mandato con 3 serie di invii (la prima è l'indrizzo del codec su bus).
// Si potrebbe far sì che comandi consecutivi chiedano solo 2 invii (forse il datasheet non lo consente)
// la macchina potrebbe essere riscritta con parte sequenziale e combinatoria per bene

module i2c (
	CLK,
	I2C_SCLK,//I2C CLOCK
 	I2C_SDAT,//I2C DATA
	I2C_DATA,//DATA:[REGISTER,DATA]
	GO,      //start transfer
	READY,    //completed transfer and ready for next command
	ACK,     //received command
	RST_L,
	//ONLY TO USE IN TESTBENCH
	SD_COUNTER,
	SDO
);

localparam CODEC_ADDRESS = 8'h35;    //CODEC address write to program registers (forse 8'h34)

	input  CLK;
	input  [15:0]I2C_DATA;	//l'indirizzo del CODEC sul bus I2C è preso costante 0x35
	input  GO;
	input  RST_L;	
 	inout  I2C_SDAT;	
	output I2C_SCLK;
	output READY;	
	output ACK;
	//si può aggiungere NACK/ERR
//ONLY TO USE IN TESTBENCH
	output [5:0] SD_COUNTER;
	output SDO;


reg SDO;
reg SCLK;
reg READY;
reg ACK;
reg [15:0]SD;
reg [5:0]SD_COUNTER;    //indagare perché 6 bit e scegliere che tipo di contatore fare

wire I2C_SCLK = SCLK | ( ((SD_COUNTER >= 4) & (SD_COUNTER <=30))? ~CLK : 1'b0 );
wire I2C_SDAT = SDO ? 1'bz : 1'b0;

//reg ACK1, ACK2, ACK3;
//wire ACK = ACK1 | ACK2 | ACK3;

//--I2C STATEFLOW
always @(posedge CLK) begin   //reset scelto sincrono
	if (!RST_L) SD_COUNTER <= 6'b111111;
	else begin
		if (SD_COUNTER >= 0 && SD_COUNTER < 32) //go through normal functioning states
			SD_COUNTER <= SD_COUNTER + 6'd1;
		else if (GO == 1) SD_COUNTER = 0;	    //start transfer
		else SD_COUNTER <= 6'b100000;           //waiting idle state
	end
end

//--I2C OUTPUT 
always @(posedge CLK) begin    //reset scelto sincrono
if (!RST_L) begin SCLK = 1; SDO = 1; READY = 0; ACK = 0; end
else
case (SD_COUNTER)
	6'd0  : begin READY = 0; SDO = 1; SCLK = 1; ACK = 1; end
	//start
	6'd1  : begin SD = I2C_DATA; SDO = 0; ACK <= 0; end
	6'd2  : SCLK = 0;
	//SLAVE ADDR
	6'd3  : SDO = CODEC_ADDRESS[7];
	6'd4  : SDO = CODEC_ADDRESS[6];
	6'd5  : SDO = CODEC_ADDRESS[5];
	6'd6  : SDO = CODEC_ADDRESS[4];
	6'd7  : SDO = CODEC_ADDRESS[3];
	6'd8  : SDO = CODEC_ADDRESS[2];
	6'd9  : SDO = CODEC_ADDRESS[1];
	6'd10 : SDO = CODEC_ADDRESS[0];	
	6'd11 : SDO = 1'b1;//ACK

	//SUB ADDR
	6'd12  : SDO = SD[15]; //ACK1 = I2C_SDAT; end
	6'd13  : SDO = SD[14];
	6'd14  : SDO = SD[13];
	6'd15  : SDO = SD[12];
	6'd16  : SDO = SD[11];
	6'd17  : SDO = SD[10];
	6'd18  : SDO = SD[9];
	6'd19  : SDO = SD[8];	
	6'd20  : SDO = 1'b1;//ACK

	//DATA
	6'd21  : SDO = SD[7]; //ACK2 = I2C_SDAT; end
	6'd22  : SDO = SD[6];
	6'd23  : SDO = SD[5];
	6'd24  : SDO = SD[4];
	6'd25  : SDO = SD[3];
	6'd26  : SDO = SD[2];
	6'd27  : SDO = SD[1];
	6'd28  : SDO = SD[0];	
	6'd29  : SDO = 1'b1;//ACK

	
	//stop
    6'd30 : begin SDO = 1'b0; SCLK = 1'b0; end//ACK3 = I2C_SDAT; end	questo stato potrebbe essere quello in cui controllare trasferimento successivo
    6'd31 : SCLK = 1'b1; 
    6'd32 : begin SDO = 1'b1; READY = 1; end
    default : begin SDO = 1'b1; SCLK = 1'b1; READY = 1; ACK = 0; end

endcase
end



endmodule
