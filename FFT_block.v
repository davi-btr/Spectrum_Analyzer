module FFT_block(
    clk, rst_n,
    
    // buffer interface
    data_i,
    address_o,
    
    // control signals
    start_i,
    end_o,
);

// Parameters
localparam SAMPLE_WIDTH = 16;
localparam SAMPLE
localparam FSM_STATE_BITS       = $clog2(FSM_STATES);

// Ports definition
input clk;
input rst_n;

input wire data_i;
output wire address_o;

output wire end_o;
input wire start_i;

// Private wires
wire memsel;
wire [9:0]address_a;
wire [9:0]address_b;
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
wire [31:0]anext_real;
wire [31:0]anext_img;
wire [31:0]bnext_real;
wire [31:0]bnext_img;

// Private regs
reg i2s_get = 0;
reg [DAC_BITS-1:0] data_R = 0;

// Private assignments
assign a_real = memsel ? a_real_ram2 : a_real_ram1;
assign a_img = memsel ? a_img_ram2 : a_img_ram1;
assign b_real = memsel ? b_real_ram2 : b_real_ram1;
assign b_img = memsel ? b_img_ram2 : b_img_ram1;

// Private instances
addr_gen_unit fft_agu(
    .clk(clk),
    .rst_n(rst_n),
    .address_a_o(address_a),
    .address_b_o(address_b),
	 .memsel_o(memsel),
);

butterfly_unit bfu(
    .clk(clk), //serve?
	 //input
	 .twiddle, 
	 .ina_real(a_real), 
	 .ina_img(a_img), 
	 .inb_real(b_real), 
	 .inb_img(b_img), 
	 //output
	 .outa_real(anext_real), 
	 .outa_img(anext_img), 
	 .outb_real(bnext_real), 
	 .outb_img(bnext_img)
);

twiddle_fact twiddle(
    .clk(clk),
    .rst_n(rst_n),
    .i2c_sclk(codec_i2c_sclk_o),
    .i2c_sdat(codec_i2c_sdat_io)
);

cmplx_ram2port ram1(
	.address_a(address_a),
	.address_b(address_b),
	.clock(clk),
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
	.address_a(address_a),
	.address_b(address_b),
	.clock(clk),
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

// Main FSM
always @ (posedge clk) begin
    if(!rst_n) begin
        codec_buff_sel_o <= 0;
        codec_buff_empty_o <= 0;
        codec_buff_addr_o <= 0;
        i2s_get <= 0;
        sample_cnt <= 0;
        fsm_state <= FSM_WAIT_BUFFER_0;
    end else case(fsm_state)
	 //FORSE I 2 BUFFER VANNO SCAMBIATI DI RUOLO
        FSM_WAIT_BUFFER_0: begin
            codec_buff_empty_o <= !codec_buffer_empty_ack_i;
            fsm_state <= (codec_buff_empty_ack_i) ? FSM_WAIT_BUFFER_1 : fsm_state;
        end
        FSM_WAIT_BUFFER_1: begin
            if(i2s_done)
                i2s_get <= 0;
            if(codec_buff_filled_i) begin
                codec_buff_sel_o <= codec_buff_sel_o ^ 1;
                codec_buff_empty_o <= 1'b1;
                codec_buff_addr_o <= 0; 
                sample_cnt <= 0;
                wait_states <= 0;
                fsm_state <= FSM_CONSUMING_BUFFER;
            end
        end
        FSM_CONSUMING_BUFFER: begin
            if(wait_states == RAM_READ_WAIT_STATES) begin
                codec_buff_empty_o <= !codec_buff_empty_ack_i & (swap_buffs | codec_buff_empty_o);
                codec_buff_sel_o   <= codec_buff_sel_o ^ swap_buffs;
              
                codec_buff_addr_o <= codec_buff_addr_o + 1'b1;
                sample_cnt          <= (sample_cnt < sample_cnt_top) ? sample_cnt + 1'b1 : 0;
                wait_states <= 0;
                
                i2s_get <= i2s_get | (sample_cnt == sample_cnt_top);
                
                case(sample_cnt)
                    0: begin data_L[ 7:0] <= codec_buffer_data_i; data_R[ 7:0] <= codec_buffer_data_i; end
                    1: begin data_L[15:8] <= codec_buffer_data_i; data_R[15:8] <= codec_buffer_data_i; end
                    2: data_R[ 7:0] <= codec_buffer_data_i;
                    3: data_R[15:8] <= codec_buffer_data_i;
                endcase
                
                if(sample_cnt == sample_cnt_top) begin                    
                    if(buffer_is_over && !codec_buffer_filled_i)
                        fsm_state <= FSM_WAIT_BUFFER_1;
                    else
                        fsm_state <= (!i2s_done) ? FSM_WAIT_I2S : fsm_state;
                end
            end else begin
                wait_states <= wait_states + 1'b1;
            end
        end
        FSM_WAIT_I2S: begin
            if(codec_buff_empty_ack_i)
                codec_buff_empty_o <= 0;

            fsm_state <= (i2s_done && !codec_pause_i) ? FSM_CONSUMING_BUFFER : fsm_state;
        end
    endcase
end

endmodule
