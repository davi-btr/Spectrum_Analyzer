module buffer_wrap(
	clk1,	// bclk
	clk2,	// master clock, 50 MHz
	 
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
output [DATA_BITS-1:0]buff_rdata_o;
input buff_sel_i;

input [9:0] buff_waddr_i;
input [DATA_BITS-1:0] buff_wdata_i;

// Private regs
reg buff_sel;
reg buff_sel_synch;
// Private wires
wire [DATA_BITS-1:0]sample;
wire read_en;
wire [DATA_BITS-1:0] buffer_rdata1;
wire [DATA_BITS-1:0] buffer_rdata2;

wire buff_wdata;

// Private assignments
assign buff_rdata_o = (buff_sel)? buffer_rdata1 : buffer_rdata2;

buffer buffer1(
	.data(buff_wdata_i),
	.rdaddress(buff_raddr_i),
	.rdclock(clk2),
	.rden(buff_sel),
	.wraddress(buff_waddr_i),
	.wrclock(clk1),
	.wren(!buff_sel_i),
	.q(buffer_rdata1)
);
buffer buffer2(
	.data(buff_wdata_i),
	.rdaddress(buff_raddr_i),
	.rdclock(clk2),
	.rden(!buff_sel),
	.wraddress(buff_waddr_i),
	.wrclock(clk1),
	.wren(buff_sel_i),
	.q(buffer_rdata2)
);

// Sync buffer select between bclk and mclk
always @ (posedge clk2) begin
		buff_sel <= buff_sel_synch;
		buff_sel_synch <= buff_sel_i;
end

endmodule
