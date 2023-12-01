// ============================================================================
//
// Permission:
//
// ============================================================================
//
// Major Functions: Codec initialization Finite State Machine
//
// ============================================================================
//
// Revision History :
// 
// ============================================================================

// ============================================================================

// si occupa di inizializzare il codec programmandone tutti i registri interni.
// Dopo potrebbe essere usata per cambiare volume se servisse

module codec_init_FSM (
    clk,
    rst_n,
	 ack,
	 ready,
    //change_volume, ??
    cmd,
	 send
);

/* Possible commands */
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
localparam INIT_CMDS_N	= 11;
//localparam VOL = 7'd120;

/* Ports definition */
input  clk;
input  rst_n;
input ack;
input ready;
output cmd;
output send;
//input  change_volume;

/* Internal regs */
//reg	[15:0]	mI2C_CLK_DIV;
//reg	[23:0]	mI2C_DATA;
//reg			mI2C_CTRL_CLK;
//reg			mI2C_GO;
//reg	[15:0]	LUT_DATA;
//reg	[3:0]	LUT_INDEX;
reg	[1:0]	state_cnt;
reg	cmd_idx;

assign cmd = cmd_idx;

always@(posedge clk) begin	//reset sincrono
    if(!rst_n) begin
        cmd	<=	0;
        state_cnt	<=	0;
		  cmd_idx	<= 0;
        send		<=	0;
    end else begin
        if(cmd_idx < INIT_CMDS_N)
            case(state_cnt)
                0:	begin
                    //cmd_idx	<=	cmd_idx + 4'd1;	//dopo il reset parto da 0 (dummy) dunque il primo giusto è il numero 1
                    send		<=	1;
                    state_cnt	<=	1;
                end
                1:	begin
                    if(ack) begin
                        state_cnt	<=	2;
                        send		<=	0;
                    end
                end
                2:	begin
							if (ready) begin
							  cmd_idx	<=	cmd_idx + 4'd1;
							  state_cnt	<=	0;
							end
						end
            endcase
    end
end

endmodule
