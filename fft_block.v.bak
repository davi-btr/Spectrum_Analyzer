module fft_block(
    // input
	 clk,
	 rst_n,
    data_i,
	 start_i,
	 // output
    read_input_buffer_address_o,
	 fft_done_o,
	 write_vga_buffer_address1_o,
	 write_vga_buffer_address2_o,
	 fft_sample1_real_o,
	 fft_sample1_img_o,
	 fft_sample2_real_o,
	 fft_sample2_img_o,
	 vga_start_o
);

// Ports definition
input clk;
input rst_n;

input [15:0] data_i;
output [9:0] read_input_buffer_address_o;
input start_i;
output reg fft_done_o = 1'b0;
output [9:0] write_vga_buffer_address1_o;
output [9:0] write_vga_buffer_address2_o;
output [31:0] fft_sample1_real_o;
output [31:0] fft_sample1_img_o;
output [31:0] fft_sample2_real_o;
output [31:0] fft_sample2_img_o;
output reg vga_start_o;

//private reg

reg fft_done_pipe_reg = 1'b0;
reg vga_start_pipe_reg = 1'b0;

// Private wires
wire memsel;
wire [9:0]address_a;
wire [9:0]address_b;
wire [9:0]pipe_address_a;
wire [9:0]pipe_address_b;
wire [9:0]mem1_address_a;
wire [9:0]mem1_address_b;
wire [9:0]mem2_address_a;
wire [9:0]mem2_address_b;
wire [31:0]a_real_ram1;
wire [31:0]a_img_ram1;
wire [31:0]b_real_ram1;
wire [31:0]b_img_ram1;
wire [31:0]a_real_ram2;
wire [31:0]a_img_ram2;
wire [31:0]b_real_ram2;
wire [31:0]b_img_ram2;
wire [31:0]a_real;
wire [31:0]a_img;
wire [31:0]b_real;
wire [31:0]b_img;
wire [31:0]anext_real_bfu;
wire [31:0]anext_img_bfu;
wire [31:0]bnext_real_bfu;
wire [31:0]bnext_img_bfu;
wire [31:0]anext_real;
wire [31:0]anext_img;
wire [31:0]bnext_real;
wire [31:0]bnext_img;
wire [31:0]tw_real;
wire [31:0]tw_img;
wire [8:0]tw_addr;
wire loading;
wire fft_done_w;
wire vga_start_w;

// Private regs
//reg i2s_get = 0;
/*reg [DAC_BITS-1:0] data_R = 0;
reg [2:0]sreg = CALC_FFT;
reg [2:0]snext;
reg [8:0]j = 9'b0; //le coppie sono metà dei campioni, quindi bastano 9 bit
reg [9:0]i = 3'b0;*/


// Private assignments
assign a_real = memsel ? a_real_ram2 : a_real_ram1;
assign a_img = memsel ? a_img_ram2 : a_img_ram1;
assign b_real = memsel ? b_real_ram2 : b_real_ram1;
assign b_img = memsel ? b_img_ram2 : b_img_ram1;
assign mem1_address_a = memsel ? pipe_address_a : address_a;
assign mem1_address_b = memsel ? pipe_address_b : address_b;
assign mem2_address_a = memsel ? address_a : pipe_address_a;//(pipe_address_a + 1'b1) : (pipe_address_a + 1'b1);//pipe_address_a : pipe_address_a;//address_a : pipe_address_a;
assign mem2_address_b = memsel ? address_b : pipe_address_b;//pipe_address_b : pipe_address_b;//address_b : pipe_address_b;
assign anext_real = loading ? ($signed(data_i) << 6) : anext_real_bfu; //per una fft a 1024 punti si può shiftare di 6 (*2^6)
assign anext_img = loading ? 0 : anext_img_bfu;
assign bnext_real = loading ? ($signed(data_i) << 6) : bnext_real_bfu;
assign bnext_img = loading ? 0 : bnext_img_bfu;
assign fft_sample1_real_o = fft_done_o ? a_real_ram1 : 0;
assign fft_sample1_img_o = fft_done_o ? a_img_ram1 : 0;
assign fft_sample2_real_o = fft_done_o ? b_real_ram1 : 0;
assign fft_sample2_img_o = fft_done_o ? b_img_ram1 : 0;
assign write_vga_buffer_address1_o = fft_done_o ? pipe_address_a : 10'b0;
assign write_vga_buffer_address2_o = fft_done_o ? pipe_address_b : 10'b0;



//blocchi always
always @ (posedge clk)
begin
	fft_done_pipe_reg <= fft_done_w;
	fft_done_o <= fft_done_pipe_reg;
	vga_start_pipe_reg <= vga_start_w;
	vga_start_o <= vga_start_pipe_reg;
end


//ADATTATA FFT1024
addr_gen_unit fft_agu(
    .clk(clk),
    .rst_n(rst_n),
    .address_a_o(address_a),
    .address_b_o(address_b),
	 .memsel_o(memsel),
	 .twiddle_addr_o(tw_addr),
	 .start_i(start_i), //da aggiustare
	 .read_address_buffer_o(read_input_buffer_address_o),
	 .loading_o(loading),
	 .fft_done_o(fft_done_w),
	 .vga_start_o(vga_start_w)
);


// NON DEVE ESSERE ADATTATA PER FFT1024
butterfly_unit bfu(
    //.clk(clk), //serve?
	 //input
	 .twiddle_real(tw_real), 
	 .twiddle_img(tw_img), 
	 .ina_real(a_real), 
	 .ina_img(a_img), 
	 .inb_real(b_real), 
	 .inb_img(b_img), 
	 //output
	 .outa_real(anext_real_bfu), 
	 .outa_img(anext_img_bfu), 
	 .outb_real(bnext_real_bfu), 
	 .outb_img(bnext_img_bfu)
);

// ADATTATA FFT1024
twiddle_fact twiddle(
    .clk(clk),
    //.rst_n(rst_n),
    .twiddle_addr(tw_addr),
    .twiddle_real_out(tw_real),
    .twiddle_img_out(tw_img)
);

// ADATTATA FFT1024
cmplx_ram2port ram1(
	.address_a_in(mem1_address_a),
	.address_b_in(mem1_address_b),
	.clk(clk),
	.dreal_a(anext_real),
	.dimg_a(anext_img),
	.dreal_b(bnext_real),
	.dimg_b(bnext_img),
	.wren(memsel),
	.qreal_a(a_real_ram1),
	.qimg_a(a_img_ram1),
	.qreal_b(b_real_ram1),
	.qimg_b(b_img_ram1),
	.loading_i(loading)
);

cmplx_ram2port ram2(
	.address_a_in(mem2_address_a),
	.address_b_in(mem2_address_b),
	.clk(clk),
	.dreal_a(anext_real),
	.dimg_a(anext_img),
	.dreal_b(bnext_real),
	.dimg_b(bnext_img),
	.wren(~memsel),
	.qreal_a(a_real_ram2),
	.qimg_a(a_img_ram2),
	.qreal_b(b_real_ram2),
	.qimg_b(b_img_ram2),
	.loading_i(loading)
);

//ADATTATA FFT1024
pipe2 add_a_pipeline(
	.in(address_a), 
	.out(pipe_address_a), 
	.ck(clk)
);

pipe2 add_b_pipeline(
	.in(address_b), 
	.out(pipe_address_b), 
	.ck(clk)
);


endmodule
