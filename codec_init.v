module codec_init (
    clk,
    rst_n,
    i2c_sclk_o,
    i2c_sdat_io,
	 init_done_o
);

// Params
localparam CLK_Freq = 50 * 1000 * 1000;
localparam I2C_Freq = 250 * 1000;

// LUT index (command number)
localparam Dummy_DATA		=	0;
localparam SET_LIN_L			=	1;
localparam SET_LIN_R			=	2;
localparam SET_HEAD_L		=	3;
localparam SET_HEAD_R		=	4;
localparam AUD_PATH_CTRL	=	5;
localparam DAT_PATH_CTRL	=	6;
localparam POWER_ON	   	=	7;
localparam SET_FORMAT		=	8;
localparam SAMPLE_CTRL		=	9;
localparam SET_ACTIVE		=	10;
localparam CMD_NUM	   	=	11;

// Ports definition
input  clk;
input  rst_n;
output i2c_sclk_o;
inout  i2c_sdat_io;
output reg init_done_o;

// Internal regs
reg	[15:0]	fr_div_cnt;
reg	[23:0]	i2c_data;
reg			i2c_go;
reg	[15:0]	DATAWORD;
reg	[3:0]	CMD;
reg	[1:0]	codec_init_fsm_state;
reg	i2c_slowclk;

// Internal wires
wire i2c_end;
wire i2c_ack;

i2c i2c ( 	
    .CLOCK(i2c_slowclk),
    .RESET(rst_n),
        
    .GO(i2c_go),
    .END(i2c_end),
    .ACK(i2c_ack),	
    .I2C_DATA(i2c_data),
    
    .I2C_SCLK(i2c_sclk_o),
    .I2C_SDAT(i2c_sdat_io)
);

// I2C clock generation (frequency division)
always @(posedge clk) begin
	fr_div_cnt <= fr_div_cnt+16'd1;
	if (fr_div_cnt == (CLK_Freq/(I2C_Freq) - 1))	fr_div_cnt <= 0;
	if (fr_div_cnt == (CLK_Freq/(2*I2C_Freq) - 1))	i2c_slowclk <= 0;
	else i2c_slowclk <= 1;
end


always@(posedge i2c_slowclk) begin
    if(!rst_n) begin
        CMD	<=	0;
        codec_init_fsm_state	<=	0;
        i2c_go		<=	0;
		  init_done_o <= 0;
    end else begin
        if(CMD<CMD_NUM) begin
				init_done_o <= 0;
            case(codec_init_fsm_state)
                0:	begin	// prepara comando
                    i2c_data	<=	{8'h34,DATAWORD};
                    i2c_go		<=	1;
                    codec_init_fsm_state	<=	1;
                end
                1:	begin	// aspetta termine invio
                    if(i2c_end) begin
                        if(!i2c_ack)
                            codec_init_fsm_state	<=	2;
                        else
                            codec_init_fsm_state	<=	0;							
                        i2c_go		<=	0;
                    end
                end
                2:	begin	// comando successivo
                    CMD	<=	CMD+4'd1;
                    codec_init_fsm_state	<=	0;
                end
            endcase
			end else begin
				init_done_o <= 1;	// I2S start
			end
    end
end

always begin
	case(CMD)
        SET_LIN_L			:	DATAWORD	<=	{7'd0,9'b000010111};		// linea sinistra attiva e volume in ingresso
        SET_LIN_R			:	DATAWORD	<=	{7'd1,9'b000010111};		// linea destra attiva e volume in ingresso
        SET_HEAD_L		:	DATAWORD	<=	{7'd2,9'b001111001};		// output sinistro attivo (per feedback)
        SET_HEAD_R		:	DATAWORD	<=	{7'd3,9'b001111001};		// output destro attivo (per feedback)
        AUD_PATH_CTRL	:	DATAWORD	<=	{7'd4,9'b000001010};		// no mic, bypass attivo (per feedback)
        DAT_PATH_CTRL	:	DATAWORD	<=	{7'd5,9'b000001000};		// DAC mute (non usato)
        POWER_ON			:	DATAWORD	<=	{7'd6,9'b000000000};		// Attivazione alimentazione blocchi
        SET_FORMAT		:	DATAWORD	<=	{7'd7,9'b001000010};		// I2S, 16 bit
        SAMPLE_CTRL		:	DATAWORD	<=	{7'd8,9'b000000000};		// 48kHz, normal mode
        SET_ACTIVE		:	DATAWORD	<=	{7'd9,9'b000000001};		// Avvio
        default			:	DATAWORD	<=	16'h0017;	//dummy
	endcase
end

endmodule
