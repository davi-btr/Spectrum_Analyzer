module FFT_block(
    clk, rst_n,
    
    // buffer interface
    data_i,
    address_o,
    
    // control signals
    start_i
    //end_o, per ora non serve
);

// Parameters
//localparam SAMPLE_WIDTH = 16;
//localparam SAMPLE_NUM	= 1024;
//localparam FFT_DEPTH    = $clog2(SAMPLE_NUM);
localparam s0 = 3'b000, CALC_FFT = 3'b10;

// Ports definition
input clk;
input rst_n;

input [15:0] data_i;
output [9:0] address_o;

//output end_o;
input start_i;

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

// Private regs
//reg i2s_get = 0;
/*reg [DAC_BITS-1:0] data_R = 0;
reg [2:0]sreg = CALC_FFT;
reg [2:0]snext;
reg [8:0]j = 9'b0; //le coppie sono metà dei campioni, quindi bastano 9 bit
reg [3:0]i = 3'b0;*/


// Private assignments
assign a_real = memsel ? a_real_ram2 : a_real_ram1;
assign a_img = memsel ? a_img_ram2 : a_img_ram1;
assign b_real = memsel ? b_real_ram2 : b_real_ram1;
assign b_img = memsel ? b_img_ram2 : b_img_ram1;
assign mem1_address_a = memsel ? pipe_address_a : address_a;
assign mem1_address_b = memsel ? pipe_address_b : address_b;
assign mem2_address_a = memsel ? address_a : pipe_address_a;
assign mem2_address_b = memsel ? address_b : pipe_address_b;
assign anext_real = loading ? $signed(data_i) : anext_real_bfu;
assign anext_img = loading ? 0 : anext_img_bfu;
assign bnext_real = loading ? $signed(data_i) : bnext_real_bfu;
assign bnext_img = loading ? 0 : bnext_img_bfu;

// Private instances
addr_gen_unit fft_agu(
    .clk(clk),
    .rst_n(rst_n),
    .address_a_o(address_a),
    .address_b_o(address_b),
	 .memsel_o(memsel),
	 .twiddle_addr_o(tw_addr),
	 .start_i(start_i), //da aggiustare
	 .read_address_buffer_o(address_o),
	 .loading_o(loading)
);

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

twiddle_fact twiddle(
    .clk(clk),
    //.rst_n(rst_n),
    .twiddle_addr(tw_addr),
    .twiddle_real_out(tw_real),
    .twiddle_img_out(tw_img)
);

cmplx_ram2port ram1(
	.address_a_in(mem1_address_a),
	.address_b_in(mem1_address_b),
	.clk(clk),
	.dreal_a(anext_real),
	.dimg_a(anext_img),
	.dreal_b(bnext_real),
	.dimg_b(bnext_img),
	.wren(~memsel),
	.qreal_a(a_real_ram1),
	.qimg_a(a_img_ram1),
	.qreal_b(b_real_ram1),
	.qimg_b(b_img_ram1)
);

cmplx_ram2port ram2(
	.address_a_in(mem2_address_a),
	.address_b_in(mem2_address_b),
	.clk(clk),
	.dreal_a(anext_real),
	.dimg_a(anext_img),
	.dreal_b(bnext_real),
	.dimg_b(bnext_img),
	.wren(memsel),
	.qreal_a(a_real_ram2),
	.qimg_a(a_img_ram2),
	.qreal_b(b_real_ram2),
	.qimg_b(b_img_ram2)
);

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
