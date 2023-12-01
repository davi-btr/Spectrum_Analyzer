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
output [31:0]outa_real;
output [31:0]outa_img;
output [31:0]outb_real;
output [31:0]outb_img;


//Private wires
wire [63:0]mult_out_real;
wire [63:0]mult_out_img;

//Private regs

//Private assignments
assign outa_real = mult_out_real[62:31] + ina_real;
assign outa_img = mult_out_img[62:31] + ina_img;
assign outb_real = ina_real - mult_out_real[62:31];
assign outb_img = ina_img - mult_out_img[62:31];


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
