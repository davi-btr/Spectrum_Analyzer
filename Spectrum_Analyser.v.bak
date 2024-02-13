module Spectrum_Analyser(
	//input
    CLOCK_50,
	 rst_n,
	 data_i,
	 start_i,
	 //output
	 read_input_buffer_address_o, //metto qui per non avere errori
	 adapt_buff_q1_o,
	 adapt_buff_q2_o,
	 max_value_address_o,
	 adaptation_done_o
);

// Ports definition
input CLOCK_50;
input rst_n;
input [15:0] data_i;
input start_i;
output [9:0] read_input_buffer_address_o;
output [9:0] max_value_address_o;
output [15:0] adapt_buff_q1_o;
output [15:0] adapt_buff_q2_o;
output adaptation_done_o;


// Internal wires
wire clk;
wire fft_done_w;
wire [9:0] write_vga_buffer_address1_w;
wire [9:0] write_vga_buffer_address2_w;
wire [31:0] fft_sample1_real_w;
wire [31:0] fft_sample1_img_w;
wire [31:0] fft_sample2_real_w;
wire [31:0] fft_sample2_img_w;
wire vga_start_w;


assign clk = CLOCK_50;

//ADATTATA FFT1024
fft_block FFT_calc (
    // input
	 .clk(clk),
	 .rst_n(rst_n),
    .data_i(data_i),
	 .start_i(start_i),
	 // output
    .read_input_buffer_address_o(read_input_buffer_address_o),
	 .fft_done_o(fft_done_w),
	 .write_vga_buffer_address1_o(write_vga_buffer_address1_w),
	 .write_vga_buffer_address2_o(write_vga_buffer_address2_w),
	 .fft_sample1_real_o(fft_sample1_real_w),
	 .fft_sample1_img_o(fft_sample1_img_w),
	 .fft_sample2_real_o(fft_sample2_real_w),
	 .fft_sample2_img_o(fft_sample2_img_w),
	 .vga_start_o(vga_start_w)
);

//ADATTATA FFT1024
vga_block vga_output (
	//input
	.clk(clk),
	.rst_n(rst_n),
	.fft_done_i(fft_done_w),
	.write_vga_buffer_address1_i(write_vga_buffer_address1_w),
	.write_vga_buffer_address2_i(write_vga_buffer_address2_w),
	.fft_sample1_real_i(fft_sample1_real_w),
	.fft_sample1_img_i(fft_sample1_img_w),
	.fft_sample2_real_i(fft_sample2_real_w),
	.fft_sample2_img_i(fft_sample2_img_w),
	.vga_start_i(vga_start_w),
	//output
	.adapt_buff_q1_o(adapt_buff_q1_o),
	.adapt_buff_q2_o(adapt_buff_q2_o),
	.max_value_address_o(max_value_address_o),
	.adaptation_done_o(adaptation_done_o)
);








endmodule
