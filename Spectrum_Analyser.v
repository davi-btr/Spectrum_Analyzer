module Spectrum_Analyser(
    // Audio Codec physical pins
    AUD_XCK,
    AUD_BCLK,
    AUD_ADCDAT,
    AUD_ADCLRCK,
	 
    // shared I2C bus
    I2C_SCLK,
    I2C_SDAT,
	 
	 // VGA interface
	 VGA_CLK,
	 VGA_BLANK,
	 VGA_SYNC,
	 VGA_HS,
	 VGA_VS,
	 VGA_R,
	 VGA_G,
	 VGA_B,
	 
	 //Global signals
	 SW,
    CLOCK_50
);


// Ports definition
input CLOCK_50;
input [1:0] SW;

output wire AUD_XCK;
input wire AUD_BCLK;
input wire AUD_ADCDAT;
input wire AUD_ADCLRCK;

output wire I2C_SCLK;
inout  wire I2C_SDAT;

output wire VGA_CLK;
output wire VGA_BLANK;
output wire VGA_SYNC;
output wire VGA_HS;
output wire VGA_VS;
output wire [9:0]VGA_R;
output wire [9:0]VGA_G;
output wire [9:0]VGA_B;


// Internal wires
wire right_channel;
wire fft_start;
wire fft_done;
wire [15:0] buff_rd_data;
wire [9:0] buff_rd_addr;
wire clk;
wire fft_done_w;
wire [9:0] write_vga_buffer_address1_w;
wire [9:0] write_vga_buffer_address2_w;
wire [31:0] fft_sample1_real_w;
wire [31:0] fft_sample1_img_w;
wire [31:0] fft_sample2_real_w;
wire [31:0] fft_sample2_img_w;
wire vga_start_w;
wire init_done_w;
wire i2s_done_w;


// Internal registers
reg rst_n;
reg rstn_synch;

// Private assignments
assign right_channel = SW[0];
assign clk = CLOCK_50;


// Synch rstn input
always @ (posedge CLOCK_50) begin
	rstn_synch <= SW[1];
	rst_n <= rstn_synch;
end


Codec_interface codec(
    .clk(clk),
    .rst_n(rst_n),
    // Audio codec physical pins
    .codec_aud_xck_o(AUD_XCK),
    .codec_aud_bclk_i(AUD_BCLK),
    .codec_aud_adcdat_i(AUD_ADCDAT),
    .codec_aud_adclrck_i(AUD_ADCLRCK),
    // Shared I2C bus
    .codec_i2c_sclk_o(I2C_SCLK),
    .codec_i2c_sdat_io(I2C_SDAT),
    // Buffer interface
    .codec_buff_raddr_i(buff_rd_addr),
    .codec_buff_start_o(fft_start),
    .codec_buff_rdata_o(buff_rd_data),
	 .codec_channel_select_i(right_channel)
);


fft_block FFT_calc (
    // Input
	 .clk(clk),
	 .rst_n(rst_n),
    .data_i(buff_rd_data),
	 .start_i(fft_start),
	 // Output
    .read_input_buffer_address_o(buff_rd_addr),
	 .fft_done_o(fft_done_w),
	 .write_vga_buffer_address1_o(write_vga_buffer_address1_w),
	 .write_vga_buffer_address2_o(write_vga_buffer_address2_w),
	 .fft_sample1_real_o(fft_sample1_real_w),
	 .fft_sample1_img_o(fft_sample1_img_w),
	 .fft_sample2_real_o(fft_sample2_real_w),
	 .fft_sample2_img_o(fft_sample2_img_w),
	 .vga_start_o(vga_start_w)
);


vga_block vga_output (
	// VGA physical pins
	.vga_clk(VGA_CLK),
	.vga_blank(VGA_BLANK),
	.vga_sync(VGA_SYNC),
	.vga_h_sync(VGA_HS),
	.vga_v_sync(VGA_VS),
	.vga_R(VGA_R),
	.vga_G(VGA_G),
	.vga_B(VGA_B),
	// Global signals
	.clk(clk),
	.rst_n(rst_n),
	// Control signals
	.fft_done_i(fft_done_w),
	.write_vga_buffer_address1_i(write_vga_buffer_address1_w),
	.write_vga_buffer_address2_i(write_vga_buffer_address2_w),
	.fft_sample1_real_i(fft_sample1_real_w),
	.fft_sample1_img_i(fft_sample1_img_w),
	.fft_sample2_real_i(fft_sample2_real_w),
	.fft_sample2_img_i(fft_sample2_img_w),
	.vga_start_i(vga_start_w)
);

endmodule
