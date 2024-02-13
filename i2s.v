module i2s #(
    parameter LEADING_BITS  = 1,  // Dummy bits in testa
    parameter DATA_BITS     = 16, // Ampiezza campioni
    parameter TRAILING_BITS = 15  // Dummy bits in coda
)(
    rst_n,
    
    // Audio codec physical pins
    codec_aud_bclk_i,
    codec_aud_adcdat_i,
    codec_aud_adclrck_i,
    
    // Control signals
    i2s_sample_data_L_o,
    i2s_sample_data_R_o,
    i2s_get_i,
    i2s_done_o
);




// Params
localparam DATA_BITS_CNTR = $clog2(DATA_BITS); // per il contatore dei bit di un campione
// Stati FSM
localparam FSM_IDLE   = 0;
localparam FSM_GET   = 1;
localparam FSM_STATES = 2;	// numero di stati
localparam FSM_STATE_BITS = $clog2(FSM_STATES);

// Ports definition
input rst_n;

input codec_aud_bclk_i;
input codec_aud_adcdat_i;
input codec_aud_adclrck_i;
input i2s_get_i;

output reg [DATA_BITS-1:0] i2s_sample_data_L_o;
output reg [DATA_BITS-1:0] i2s_sample_data_R_o;
output reg i2s_done_o;

// Private regs
reg [DATA_BITS_CNTR-1:0] data_bit;
reg [FSM_STATE_BITS-1:0] fsm_state = 0;
reg ch_right;
reg sample_L_done;
reg sample_R_done;
reg get_synch;
reg get;

// Synch get input
always @ (posedge codec_aud_bclk_i) begin
	  if (!rst_n) begin
			 get_synch <= 0;
			 get <= 0;
	  end else begin
			 get_synch <= i2s_get_i;
			 get <= get_synch;
	  end
end

 
// Main FSM
always @ (posedge codec_aud_bclk_i) begin
	i2s_done_o <= 1'b0;
	if (!rst_n | !get) begin	//rst (condizione di inattività)
		fsm_state <= FSM_IDLE;
		ch_right <= 1'b0;
	end else begin
		ch_right <= codec_aud_adclrck_i;
		case(fsm_state)
			FSM_IDLE: begin
				if ((ch_right == 1'b1) && (codec_aud_adclrck_i == 1'b0)) begin	//dummy bit in testa al camèione sinistro
					data_bit <= 4'd15;
					fsm_state <= FSM_GET;
				end else begin
					fsm_state <= FSM_IDLE;
				end
			end
			FSM_GET: begin
				fsm_state <= FSM_GET;
				if (!codec_aud_adclrck_i & !ch_right & !sample_L_done) begin
					i2s_sample_data_L_o[data_bit] <= codec_aud_adcdat_i;
					data_bit <= data_bit - 1'b1;
					if (data_bit == 0) sample_L_done <= 1'b1;
				end if (ch_right ^ codec_aud_adclrck_i) begin	//start condition e cambio canale (dummy bit riconosciuto)
					data_bit <= 4'd15;
					if (sample_L_done & sample_R_done) begin
							sample_L_done <= 1'b0;
							sample_R_done <= 1'b0;
							i2s_done_o <= 1'b1;
               end
				end if (codec_aud_adclrck_i & ch_right & !sample_R_done) begin
					i2s_sample_data_R_o[data_bit] <= codec_aud_adcdat_i;
					data_bit <= data_bit - 1'b1;
					if (data_bit == 0) sample_R_done <= 1'b1;
				end
			end
		endcase
	end
end

endmodule
