module buffer_wrap(
	clk1,	//64x48kHz
	clk2,	//50 MHz
	 
   buff_sel_i,
   buff_rdata_o,
	buff_wdata_i,
	buff_raddr_i,
	buff_waddr_i
);

// Params
localparam DATA_BITS = 16;

// Ports definition
input clk1;
input clk2;

input [9:0]buff_raddr_i;
output [DATA_BITS-1:0]buffer_rdata_o;
input buffer_sel_i;

input [9:0] buffer_waddr_i;
input [DATA_BITS-1:0] buffer_wdata_i;

// Private regs
/*
reg [9:0] w_addr = 0;	//initial
reg req_sampled;
*/
// Private wires
wire [DATA_BITS-1:0]sample;
//wire clk2_inv;
wire read_en;
wire [DATA_BITS-1:0] buffer_rdata1;
wire [DATA_BITS-1:0] buffer_rdata2;

// Private assignments
assign buff_rdata_o = (buff_sel_i)? buffer_rdata1 : buffer_rdata2;

buffer buffer1(
	.data(buff_wdata_i),
	.rdaddress(buffer_raddr_i),
	.rdclock(clk2),
	.rden(!buff_sel_i),
	.wraddress(buffer_waddr_i),
	.wrclock(clk1),
	.wren(buff_sel_i),
	.q(buffer_rdata1)
);
buffer buffer2(
	.data(buff_wdata_i),
	.rdaddress(buffer_raddr_i),
	.rdclock(clk2),
	.rden(buff_sel_i),
	.wraddress(buffer_waddr_i),
	.wrclock(clk1),
	.wren(!buff_sel_i),
	.q(buffer_rdata2)
);

endmodule
