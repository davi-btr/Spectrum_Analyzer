module Codec_interface(
    clk, 
	 rst_n,
    
    // Audio codec physical pins
    codec_aud_adcdat_i,
    codec_aud_xck_o,
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

// Ports definition
input clk;
input rst_n;

input wire codec_aud_adcdat_i;
output wire codec_aud_xck_o;
input wire codec_aud_bclk_i;
input wire codec_aud_adclrck_i;

output wire codec_i2c_sclk_o;
inout wire codec_i2c_sdat_io;


input [9:0] codec_buff_raddr_i;		// indirizzo da cui FFT legge
output codec_buff_start_o;				// avvia buffer
output [15:0] codec_buff_rdata_o;	// dati letti, signed
input codec_channel_select_i;			// canale destro o sinistro (1 = DESTRO)

wire xclk;
wire bclk;
wire i2s_get;
wire [15:0] data_R;
wire [15:0] data_L;
wire i2s_done;

// Private regs
reg [1:0] xclk_div_cnt;

// Private assignments
assign bclk = codec_aud_bclk_i;
assign codec_aud_xck_o = xclk_div_cnt[1];	//xclk

// Codec clock generation (no PLL)
always @(posedge clk) begin
	xclk_div_cnt <= xclk_div_cnt + 2'd1;
end

// Private instances
codec_init config_FSM(
    .clk(clk),
    .rst_n(rst_n),
    .i2c_sclk_o(codec_i2c_sclk_o),
    .i2c_sdat_io(codec_i2c_sdat_io),
	 .init_done_o(i2s_get)
);

i2s #(
    .LEADING_BITS(1),
    .DATA_BITS(16),
    .TRAILING_BITS(15)
) i2s (
    .rst_n(rst_n),
    
    // Audio codec physical pins
    .codec_aud_bclk_i(codec_aud_bclk_i),
    .codec_aud_adcdat_i(codec_aud_adcdat_i),
    .codec_aud_adclrck_i(codec_aud_adclrck_i),
    
    // Control signals
    .i2s_sample_data_L_o(data_L),
    .i2s_sample_data_R_o(data_R),
    .i2s_get_i(i2s_get),
    .i2s_done_o(i2s_done)
);
codec_synch_buffer buffer(
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
