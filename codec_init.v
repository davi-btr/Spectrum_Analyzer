module codec_init (
    clk,
    rst_n,
    i2c_sclk_o,
    i2c_sdat_io
);

// Params
localparam CLK_Freq = 50 * 1000 * 1000;	//ex. 50MHz
localparam I2C_Freq = 300 * 1000;			//ex. 300kHz

// Commands list
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
localparam SET_ACTIVE	=	10;
localparam CMD_NUM	    =	11;
localparam VOL = 7'd120;

// Ports definition
input  clk;
input  rst_n;
output i2c_sclk_o;
inout  i2c_sdat_io;

// Internal regs
reg	[15:0]	fr_div_cnt;
reg	[15:0]	i2c_data;
reg			i2c_slowclk;
reg			i2c_go;
reg	[15:0]	DATAWORD;
reg	[3:0]	CMD;
reg	[1:0]	codec_init_fsm_state;

// Internal wires
wire mI2C_END;
wire mI2C_ACK;

i2c mI2C ( 	
    .CLK(i2c_slowclk),
    .RST_L(rst_n),
        
    .GO(i2c_go),
    .READY(mI2C_END),
    .ACK(mI2C_ACK),	
    .I2C_DATA(i2c_data),
    
    .I2C_SCLK(i2c_sclk_o),
    .I2C_SDAT(i2c_sdat_io)
);

// I2C Control Clock
always@(posedge clk)
begin
    if(!rst_n)
    begin
        i2c_slowclk	<=	0;
        fr_div_cnt	<=	0;
    end
    else
    begin
        if( fr_div_cnt < 8 )	//(CLK_Freq/I2C_Freq)
            fr_div_cnt <= fr_div_cnt+16'd1;
        else begin
            fr_div_cnt  <= 0;
            i2c_slowclk <= ~i2c_slowclk;
        end
    end
end

// Main FSM to send ordered commands
always@(posedge i2c_slowclk or negedge rst_n) begin
    if(!rst_n) begin
        CMD	<=	0;
        codec_init_fsm_state	<=	0;
        i2c_go		<=	0;
    end else begin
        if(CMD<CMD_NUM)
            case(codec_init_fsm_state)
                0:	begin
                    i2c_data	<=	DATAWORD;
                    i2c_go		<=	1;
                    codec_init_fsm_state	<=	1;
                end
                1:	begin
                    if(mI2C_END) begin
                        if(!mI2C_ACK)
                            codec_init_fsm_state	<=	2;
                        else
                            codec_init_fsm_state	<=	0;							
                        i2c_go		<=	0;
                    end
                end
                2:	begin
                    CMD	<=	CMD+4'd1;
                    codec_init_fsm_state	<=	0;
                end
            endcase
    end
end

// LUT to 
always begin
	case(CMD)
        Dummy_DATA	:	DATAWORD	<=	16'h0000;	//scegliere eventualmente altro, <= serve?
        SET_LIN_L	:	DATAWORD	<=	{7'd0,9'b000010111};
        SET_LIN_R	:	DATAWORD	<=	{7'd1,9'b000010111};
        SET_HEAD_L	:	DATAWORD	<=	{7'd2,9'b000000000};
        SET_HEAD_R	:	DATAWORD	<=	{7'd3,9'b000000000};
        A_PATH_CTRL	:	DATAWORD	<=	{7'd4,9'b000000010};
        D_PATH_CTRL	:	DATAWORD	<=	{7'd5,9'b000001000};
        POWER_ON	:	DATAWORD	<=	{7'd6,9'b001101010};
        SET_FORMAT	:	DATAWORD	<=	{7'd7,9'b000000010};
        SAMPLE_CTRL	:	DATAWORD	<=	{7'd8,9'b000000000};
        SET_ACTIVE	:	DATAWORD	<=	{7'd9,9'b000000001};
        default		:	DATAWORD	<=	16'h0000;
	endcase
end

endmodule
