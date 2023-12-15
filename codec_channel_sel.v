module codec_channel_sel(	//synch_buffer
	bclk,
	mclk,
	rst_n,
	 
	// Buffer synch interface (TBC!!!!)
   buffer_raddr_i,
   //codec_buffer_write_o,
   buffer_rdata_o,
   buffer_start_o,
   //codec_buffer_empty_o,
   //codec_buffer_empty_ack_i,

	// I2S control signals
	chann_sel_i,
	sample_data_L_i,
	sample_data_R_i,
	//i2s_get_i,	//relativamente inutile
	data_ready_i	//alto 1 ciclo di bclk
);

// Params
//`include "../globals.v"
/*
localparam CODEC_MCLK_DIV = 100;
localparam CODEC_MCLK_FREQ_HZ = 50000000;
localparam CODEC_FSAMPL_HZ = 48000;

localparam XCK_CNT_BITS = $clog2(CODEC_MCLK_DIV);  // CODEC_MCLK_DIV is the division factor used to obtain MCLK from main clock
localparam XCK_CNT_TOP  = CODEC_MCLK_DIV - 1;
localparam XCK_CNT_HALF = CODEC_MCLK_DIV / 2;
*/
//localparam LAST_BIT = DATA_BITS-1;
//localparam BCLK_TICKS_PER_SAMPLE = LEADING_BITS + DATA_BITS + TRAILING_BITS;
/*
localparam BCLK_CNT_DIV  = CODEC_MCLK_FREQ_HZ/CODEC_FSAMPL_HZ/(BCLK_TICKS_PER_SAMPLE*2);
localparam BCLK_CNT_BITS = $clog2(BCLK_CNT_DIV);
localparam BCLK_CNT_TOP  = BCLK_CNT_DIV - 1;
localparam BCLK_CNT_HALF = BCLK_CNT_DIV/2;
*/
//localparam BCLK_TICKS_BITS = $clog2(BCLK_TICKS_PER_SAMPLE); // Number of BCLK cycles to transmit 1 sample (left or right channel)
//localparam DATA_BITS_CNTR = $clog2(DATA_BITS); // Number of BCLK cycles to transmit 1 sample (left or right channel)
localparam DATA_BITS = 16;
/*
localparam FSM_IDLE   = 0;
localparam FSM_GET   = 1;
localparam FSM_STATES = 2;
localparam FSM_STATE_BITS = $clog2(FSM_STATES);
*/

// Ports definition
input bclk;
input mclk;
input rst_n;

//output codec_aud_xck_o;
input [9:0]buffer_raddr_i;
output [DATA_BITS-1:0]buffer_rdata_o;
output reg buffer_start_o;

input [DATA_BITS-1:0] sample_data_L_i;
input [DATA_BITS-1:0] sample_data_R_i;
input chann_sel_i;
input data_ready_i;

// Private regs
reg [9:0] w_addr = 0;	//initial
reg buffer_select;
//reg req_sampled;
//reg [9:0]data_sampled;
//reg [9:0] buff_top_in;
reg start_synch;
//reg [9:0]buff_top;
reg ch_sel;
reg ch_sel_synch;

// Private wires
wire [DATA_BITS-1:0]sample;
//wire mclk_inv;
//wire read_en;
wire sel_flip;

// Private assignments
assign sample = (ch_sel)? sample_data_R_i : sample_data_L_i;
assign sel_flip = &w_addr;
//assign req_rstn = !req_sampled;
//assign read_en = ((buff_top > 9'b0) && (buffer_raddr_i <= buff_top))? 1'b1 : 1'b0;
//assign buffer_start_o = read_en;

buffer_wrap buffer_manager(
	.clk1(bclk),
	.clk2(mclk),
	
   .buff_sel_i(buffer_select),
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
		start_synch <= 1'b0;
	 end else if (data_ready_i) begin
      w_addr <= w_addr + 9'b1;
		if (sel_flip) begin
			buffer_select <= !buffer_select;
			start_synch <= 1'b1;
		end
		  //top, bottom, altre info eventuali da aggiungere ai dati
    end else begin
		w_addr <= w_addr;
		buffer_select <= buffer_select;
		start_synch <= 1'b0;
	 end
end

// Synch channel selection input
always @ (posedge bclk) begin
	ch_sel_synch <= chann_sel_i;
	ch_sel <= ch_sel_synch;
end
/* data
always @ (posedge bclk) begin
    if (!rst_n) begin
		data_sampled <= 9'b0;
	 end else if (data_ready_i) begin
		  data_sampled <= w_addr;
    end else begin
		data_sampled <= data_sampled;
	 end
end */
/* req
always @ (posedge bclk or negedge req_rstn) begin
    if (!req_rstn) begin
		//w_addr <= 0;
		//data_sampled <= 9'b0;
		req_through <= 0;
	 end else if(!rst_n) begin
		req_through <= 0;
	 end else if (data_ready_i) begin
        //w_addr <= w_addr + 9'b1;
		  //data_sampled <= w_addr;
		  req_through <= data_ready_i;
		  //top, bottom, altre info eventuali da aggiungere ai dati
    end else begin
		//w_addr <= w_addr;
		//data_sampled <= data_sampled;
		//req_through <= req_through;
	 end
end
*/
// Synch interface mclk
always @ (posedge mclk) begin
	if (!rst_n) begin
		//buff_top_in <= 9'b0;
		//buff_top <= 9'b0;
		buffer_start_o <= 0;
	end else begin /*
		if (req_through) begin
			buff_top_in <= data_sampled;
		end
		if (top_valid) begin
			buff_top <= buff_top_in;
		end
		top_valid <= req_through;*/
		buffer_start_o <= start_synch;
	end
end
/* Double clocking on mclk
always @ (negedge mclk) begin
	req_sampled <= req_through;
end
*/
endmodule
