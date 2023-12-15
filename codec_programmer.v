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

// si occupa di trasformare i "comandi" dalla fsm principale in registro del codec e parola da scrivere
// fa da frequency divider per il clock (i2c più lento del resto)

module codec_programmer(
    RST_L,
    CLK,
    CMD,
    GO,
    SDAT,//i2c data line
    SCLK,//i2c clock out.
    READY,//Goes high when the module is done doing its thing
    ACK,
//ONLY TO USE IN TESTBENCH
    DIV_CLK
//output [3:0]audioInitError,

//input manualSend,//Pulse high to send i2c data manually.
//input [6:0]manualRegister,
//input [8:0]manualData,
//output reg manualDone
);

    input RST_L;
    input CLK;
    input CMD;
    input GO;
    inout SDAT;
    output SCLK;
    output READY;
    output ACK;
    output DIV_CLK;

//possible commands from main FSM (to initialize codec, ...)
localparam Dummy_DATA	=	0;
localparam SET_LIN_L	=	1;
localparam SET_LIN_R	=	2;
localparam SET_HEAD_L	=	3;
localparam SET_HEAD_R	=	4;
localparam A_PATH_CTRL	=	5;
localparam D_PATH_CTRL	=	6;
localparam POWER_ON	    =	7;
localparam SET_FORMAT	=	8;
localparam SAMPLE_CTRL	=	9;

// frequency division factor
localparam F_DIV = 8;


//reg [6:0]REGISTERS[0:5];
//reg [8:0]DATA[0:5];

//reg [3:0]currentInit;
//reg [2:0]initState;


//i2c interface
//reg i2cEnable;
//initial i2cEnable = 1'b0;

//reg [6:0]i2cRegister;
//reg [8:0]i2cData;
//wire [3:0]i2cError;
//wire i2cDone;

reg SLOW_CLK;
reg DATAWORD;
reg COUNT;

initial COUNT = 0;

// frequency division for I2C clock
always @(posedge CLK) begin
    COUNT <= COUNT + 1;
    if (COUNT >= F_DIV) begin
        COUNT <= 0;
        SLOW_CLK <= ~SLOW_CLK;
    end
end

always begin
    case(CMD)
        0	:	DATAWORD	<=	16'h0000;	//<=?
        1	:	DATAWORD	<=	{7'd0,9'b000010111};
        2	:	DATAWORD	<=	{7'd1,9'b000010111};
        3	:	DATAWORD	<=	{7'd2,9'b000000000}; //valutare di mettere l'audio in uscita
        4	:	DATAWORD	<=	{7'd3,9'b000000000};
        5	:	DATAWORD	<=	{7'd4,9'b000000010};
        6	:	DATAWORD	<=	{7'd5,9'b000001000};
        7	:	DATAWORD	<=	{7'd6,9'b001101010};
        8	:	DATAWORD	<=	{7'd7,9'b000000010};
        9	:	DATAWORD	<=	{7'd8,9'b000000000};	//sampling at 48kHz from 16.288MHz clock
        10	:	DATAWORD	<=	{7'd9,9'b000000001};
        default		:	DATAWORD	<=	16'h0000;  
    endcase
end
i2c i2c_fsm(
	.RST_L(i2cEnable),
	.CLK(SLOW_CLK),
	.ACK(ACK),
	.GO(GO),
	.I2C_DATA(DATAWORD),
	//.rw(1'b0),//We're always writing. Can't read from this device.
	//.error(i2cError),//This will output an error if something goes wrong.
	.I2C_SDAT(SDAT),//This is the i2c data line.
	.I2C_SCLK(SCLK),
	.READY(READY),//Will go high when i2c is done.
	.SDO(),
	.SD_COUNTER()
);

assign DIV_CLK = SLOW_CLK;

endmodule