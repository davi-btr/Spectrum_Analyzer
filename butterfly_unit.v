module butterfly_unit(
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
	 outb_img,
	 clk
);


//Parameters


//Ports definition
input clk;
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
reg [31:0]a_real_reg;
reg [31:0]a_img_reg;

//Private assignments
assign outa_real = a_real_reg - mult_out_real[63:32]; // somme e sottrazioni sono invertite rispetto ad una normale DFT a 2 punti perché
assign outa_img = a_img_reg - mult_out_img[63:32];    // nella ROM sono stati registrati -tw 
assign outb_real = a_real_reg + mult_out_real[63:32];
assign outb_img = a_img_reg + mult_out_img[63:32];


always @ (posedge clk) 
begin
	a_real_reg <= ina_real; // pipe del dato_a per allinearlo al risultato della moltiplicazione
	a_img_reg <= ina_img;
end

// Private instances
cmplx_mult_clk mult(
	.clock(clk), // il moltiplicatore complesso introduce un ciclo di clock di latenza
	.dataa_imag(twiddle_img),
	.dataa_real(twiddle_real),
	.datab_imag(inb_img),
	.datab_real(inb_real),
	.result_imag(mult_out_img),
	.result_real(mult_out_real)
);


endmodule
