module butterfly_unit(
    //.clk(clk), //serve?
	 //input
	 twiddle_real, 
	 twiddle_img, 
	 ina_real, 
	 ina_img, 
	 inb_real, 
	 inb_img, 
	 //output
	 outa_real, 
	 outa_img, 
	 outb_real, 
	 outb_img
);

//Parameters

//Ports definition
input [31:0]twiddle_real;
input [31:0]twiddle_img;
input [31:0]ina_real;
input [31:0]ina_img;
input [31:0]inb_real;
input [31:0]inb_img;
output [31:0]outa_real; // = 32'b0;
output [31:0]outa_img; //= 32'b0;
output [31:0]outb_real; // = 32'b0;
output [31:0]outb_img; //= 32'b0;


//Private wires
wire [63:0]mult_out_real; //= 64'b0;
wire [63:0]mult_out_img; // = 64'b0;

//Private regs

//Private assignments
assign outa_real = ina_real - mult_out_real[63:32];
assign outa_img = ina_img - mult_out_img[63:32];
assign outb_real = ina_real + mult_out_real[63:32];
assign outb_img = ina_img + mult_out_img[63:32];


// Private instances
cmplx_mult mult(
	.dataa_imag(twiddle_img),
	.dataa_real(twiddle_real),
	.datab_imag(inb_img),
	.datab_real(inb_real),
	.result_imag(mult_out_img),
	.result_real(mult_out_real)
);


endmodule
