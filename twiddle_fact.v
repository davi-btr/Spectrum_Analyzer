module twiddle_fact(
	clk,
	twiddle_addr,
	twiddle_real_out,
	twiddle_img_out
);

//Parameters

//Ports definition
input clk;
input [8:0]twiddle_addr;
output [15:0]twiddle_real_out;
output [15:0]twiddle_img_out;

//Private wires


//Private regs

//Private assignments

rom1port_real twiddle_coeff_real(
	.address(twiddle_addr),
	.clock(clk),
	.q(twiddle_real_out)
);

rom1port_img twiddle_coeff_img(
	.address(twiddle_addr),
	.clock(clk),
	.q(twiddle_img_out)
);


endmodule
