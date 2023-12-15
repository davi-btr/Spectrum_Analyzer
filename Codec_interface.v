module Codec_interface(
    clk, rst_n,
    
    // Audio codec physical pins
    codec_aud_adcdat_i,
    codec_aud_xck_o, //from PLL
    codec_aud_bclk_i,
    codec_aud_adclrck_i,
    
    // Shared I2C bus
    codec_i2c_sclk_o,
    codec_i2c_sdat_io,
    
    // Buffer interface
    codec_buff_raddr_i,
    codec_buff_start_o,
    codec_buff_rdata_o,
	 
	 // IO pins
	 codec_channel_select_i
);

// Parameters
/*
localparam DAC_BITS = 16;

localparam FSM_WAIT_BUFFER_0    = 0;
localparam FSM_WAIT_BUFFER_1    = 1;
localparam FSM_CONSUMING_BUFFER = 2;
localparam FSM_WAIT_I2S         = 3;
localparam FSM_STATES           = 4;
localparam FSM_STATE_BITS       = $clog2(FSM_STATES);
*/
// Ports definition
input clk;
input rst_n;

input wire codec_aud_adcdat_i;
output wire codec_aud_xck_o;
input wire codec_aud_bclk_i;
input wire codec_aud_adclrck_i;

output wire codec_i2c_sclk_o;
inout wire codec_i2c_sdat_io;

input [9:0] codec_buff_raddr_i;
output codec_buff_start_o;
output [15:0] codec_buff_rdata_o;	//signed
input codec_channel_select_i;
//output reg [BUFFER_ADDR_BITS-1:0] codec_buffer_addr_o;
//output reg codec_buffer_sel_o;
//output reg codec_buffer_empty_o;

// Private wires
//wire i2s_ready;
//wire [2:0] sample_cnt_top;
//wire buff_is_over;
//wire swap_buffs;

wire xclk;
wire bclk;
wire i2s_get;
wire [15:0] data_R;
wire [15:0] data_L;
wire i2s_done;

// Private regs
//reg i2s_get = 0;
//reg [DAC_BITS-1:0] data_R = 0;
//reg [DAC_BITS-1:0] data_L = 0;
//reg [2:0] sample_cnt = 0;
//reg [FSM_STATE_BITS-1:0] fsm_state = 0;
//reg [RAM_READ_WAIT_STATES_BITS-1:0] wait_states = 0;

// Private assignments
//assign sample_cnt_top = (2 * wav_info_audio_channels_i) - 1;
//assign buff_is_over = codec_buff_addr_o == (BUFFER_SIZE_BYTES-1);
//assign swap_buffers   = buff_is_over && codec_buff_filled_i;
assign i2s_get = 1'b1;	//decidere come usarlo
assign bclk = codec_aud_bclk_i;
assign codec_aud_xck_o = xclk;

// Private instances
codec_init config_FSM(
    .clk(clk),
    .rst_n(rst_n),
    .i2c_sclk_o(codec_i2c_sclk_o),
    .i2c_sdat_io(codec_i2c_sdat_io)
);

CODEC_PLL xclk_pll(	//DA SETTARE
    .inclk0(clk),
    .c0(xclk) /* Set clk to 200 MHz */
);

i2s_master #(
    .LEADING_BITS(1),
    .DATA_BITS(16),
    .TRAILING_BITS(15)
) i2s (
    .rst_n(rst_n),
    
    // Audio codec physical pins
    //.codec_aud_xck_o(codec_aud_xck_o),
    .codec_aud_bclk_i(codec_aud_bclk_i),
    .codec_aud_adcdat_i(codec_aud_adcdat_i),
    .codec_aud_adclrck_i(codec_aud_adclrck_i),
    
    // Control signals
    .i2s_sample_data_L_o(data_L),
    .i2s_sample_data_R_o(data_R),
    .i2s_get_i(i2s_get),
    .i2s_done_o(i2s_done)

);
codec_channel_sel buffer(
	.bclk(bclk),
	.mclk(clk),
	.rst_n(rst_n),
	 
	// Buffer synch interface
   .buffer_raddr_i(codec_buff_raddr_i),
   .buffer_rdata_o(codec_buff_rdata_o),
   .buffer_start_o(codec_buff_start_o),
	 
	// I2S control signals
	.chann_sel_i(codec_channel_select_i),
	.sample_data_L_i(data_L),
	.sample_data_R_i(data_R),
	.data_ready_i(i2s_done)
);

endmodule
