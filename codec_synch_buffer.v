module codec_synch_buffer(
	bclk,
	mclk,
	rst_n,
	 
	// Buffer synch interface
   buffer_raddr_i,
   buffer_rdata_o,
   buffer_start_o,


	// I2S control signals
	chann_sel_i,
	sample_data_L_i,
	sample_data_R_i,
	data_ready_i		//alto 1 ciclo di bclk
);

// Params
localparam DATA_BITS = 16;

// Ports definition
input bclk;
input mclk;
input rst_n;
input [9:0]buffer_raddr_i;
input [DATA_BITS-1:0] sample_data_L_i;
input [DATA_BITS-1:0] sample_data_R_i;
input chann_sel_i;
input data_ready_i;
output [DATA_BITS-1:0]buffer_rdata_o;
output reg buffer_start_o;

// Private regs
reg [9:0] w_addr;
reg buffer_select;
reg start_asynch;
reg start_synch;
reg ch_sel;
reg ch_sel_synch;


// Private wires
wire [DATA_BITS-1:0]sample;
wire sel_flip;

// Private assignments
assign sample = (ch_sel)? sample_data_R_i : sample_data_L_i;
assign sel_flip = &w_addr;

buffer_wrap buffer_manager(
	.clk1(bclk),
	.clk2(mclk),
	
   .buff_sel_i(buffer_select),	// selezione buffer in double buffering
   .buff_rdata_o(buffer_rdata_o),
	.buff_wdata_i(sample),
	.buff_raddr_i(buffer_raddr_i),
	.buff_waddr_i(w_addr)
);

// Constantly fill buffer if I2S is working, synch interface bclk                   
always @ (posedge bclk) begin
    if (!rst_n) begin
		w_addr <= 9'b0;
		buffer_select <= 1'b0;
		start_asynch <= 1'b0;
	 end else if (data_ready_i) begin
      w_addr <= w_addr + 9'b1;
		if (sel_flip) begin
			buffer_select <= !buffer_select;
			start_asynch <= 1'b1;
		end
    end else begin
		w_addr <= w_addr;
		buffer_select <= buffer_select;
		start_asynch <= 1'b0;
	 end
end

// Synch channel selection input
always @ (posedge bclk) begin
	ch_sel_synch <= chann_sel_i;
	ch_sel <= ch_sel_synch;
end

// Synch interface mclk
always @ (posedge mclk) begin
	if (!rst_n) begin

		buffer_start_o <= 0;
		start_synch <= 0;
	end else begin
		buffer_start_o <= start_synch;
		start_synch <= start_asynch;
	end
end

endmodule
