module cmplx_ram2port(
    clk,
    
    // inputs
    address_a_in,
    address_b_in,
	 dreal_a,
	 dimg_a,
	 dreal_b,
	 dimg_b,
	 wren,
    // outputs
    qreal_a,
	 qimg_a,
	 qreal_b,
	 qimg_b
);

// Parameters

// Ports definition
input clk;
input [9:0]address_a_in;
input [9:0]address_b_in;
input [31:0]dreal_a;
input [31:0]dimg_a;
input [31:0]dreal_b;
input [31:0]dimg_b;
input wren;
output [31:0]qreal_a;
output [31:0]qimg_a;
output [31:0]qreal_b;
output [31:0]qimg_b;

// Private instances
ram2port ram_real(
	.address_a(address_a_in),
	.address_b(address_b_in),
	.clock(clk),
	.data_a(dreal_a),
	.data_b(dreal_b),
	.wren_a(wren),
	.wren_b(wren),
	.q_a(qreal_a),
	.q_b(qreal_b)
);
ram2port ram_img(
	.address_a(address_a_in),
	.address_b(address_b_in),
	.clock(clk),
	.data_a(dimg_a),
	.data_b(dimg_b),
	.wren_a(wren),
	.wren_b(wren),
	.q_a(qimg_a),
	.q_b(qimg_b)
);

endmodule
