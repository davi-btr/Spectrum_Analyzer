module i2s_master #(
    parameter LEADING_BITS  = 1,  // Dummy bits before sample, fixed to 1
    parameter DATA_BITS     = 16, // Width in bits of one sample
    parameter TRAILING_BITS = 15  // Dummy bits after sample, (at least one required)
)(
    rst_n,
    
    // Audio codec physical pins
    //codec_aud_xck_o,
    codec_aud_bclk_i,
    codec_aud_adcdat_i,
    codec_aud_adclrck_i,
    
    // Control signals
    i2s_sample_data_L_o,
    i2s_sample_data_R_o,
    i2s_get_i,	//relativamente inutile
    i2s_done_o
);

// Params
//`include "../globals.v"

//localparam BCLK_TICKS_BITS = $clog2(BCLK_TICKS_PER_SAMPLE); // Number of BCLK cycles to transmit 1 sample (left or right channel)
localparam DATA_BITS_CNTR = $clog2(DATA_BITS); // Number of BCLK cycles to transmit 1 sample (left or right channel)

localparam FSM_IDLE   = 0;
localparam FSM_GET   = 1;
localparam FSM_STATES = 2;
localparam FSM_STATE_BITS = $clog2(FSM_STATES);

// Ports definition
//input bclk;
input rst_n;

//output codec_aud_xck_o;
input codec_aud_bclk_i;
input codec_aud_adcdat_i;
input codec_aud_adclrck_i;

output reg [DATA_BITS-1:0] i2s_sample_data_L_o;
output reg [DATA_BITS-1:0] i2s_sample_data_R_o;
input i2s_get_i;
output reg i2s_done_o;

// Private regs
//reg [XCK_CNT_BITS-1:0]    xck_counter = 0;
//reg [BCLK_CNT_BITS-1:0]   bclk_counter = 0;
//reg [BCLK_TICKS_BITS-1:0] bclk_ticks = 0;
reg [DATA_BITS_CNTR-1:0] data_bit;
//reg [DATA_BITS-1:0] sample_L = 0;
//reg [DATA_BITS-1:0] sample_R = 0; 

reg [FSM_STATE_BITS-1:0] fsm_state = 0;

//reg synch = 0;	//POTREBBE ESSERE CHANNEL RIGHT PER ORA
reg ch_right;
reg sample_L_done;
reg sample_R_done;
//reg dummy_trail_cnt; // =0
reg get_synch;
reg get;

// Private wires
//wire [DATA_BITS-1:0] sample;
//wire end_of_sample;
//wire i2s_idle;

//wire done;


//assign i2s_sample_data_L_o = 0;
//assign i2s_sample_data_R_o = 0;


// Private assignments
//assign i2s_idle = fsm_state == FSM_IDLE;
/*
assign i2s_done_o = (codec_aud_adclrck_o & end_of_sample) | i2s_idle;
//assign sample = (codec_aud_adclrck_o) ? sample_L : sample_R;
//assign codec_aud_adcdat_i = sample[data_bit];
assign end_of_sample = (bclk_ticks == (BCLK_TICKS_PER_SAMPLE-1))
                        && (bclk_counter == BCLK_CNT_TOP)
                        && (xck_counter == XCK_CNT_TOP);
*/	
//assign i2s_done_o = sample_L_done & sample_R_done;

/* XCK and BCK clock generation
always @ (posedge clk) begin
    if(!rst_n) begin
        xck_counter <= 0;
        bclk_counter <= 0;
        bclk_ticks <= 0;
        codec_aud_xck_o <= 0;
        codec_aud_bclk_o <= 0;
    end else begin
        xck_counter <= (xck_counter < XCK_CNT_TOP)  ? xck_counter + 1'b1 : 0;
        codec_aud_xck_o <= (xck_counter < XCK_CNT_TOP) && (xck_counter > (XCK_CNT_HALF-2)); 
 
        if(!i2s_idle && (xck_counter == XCK_CNT_TOP)) begin
            bclk_counter     <= (bclk_counter < BCLK_CNT_TOP)  ? bclk_counter + 1'b1 : 0;
            codec_aud_bclk_o <= (bclk_counter < BCLK_CNT_TOP) && (bclk_counter > (BCLK_CNT_HALF-2));
            
            if(bclk_counter == BCLK_CNT_TOP)
                bclk_ticks <= bclk_ticks + 1'b1;
        end
    end
end 

// Obtaining data_bit from blck_cycles                      
always @ (bclk_ticks) begin
    if(bclk_ticks < LEADING_BITS)
        data_bit <= DATA_BITS - 1'b1;
    else if(bclk_ticks < LEADING_BITS + DATA_BITS)
        data_bit <= LEADING_BITS + DATA_BITS - 1'b1 - bclk_ticks;
    else
        data_bit <= 0;
end
*/    
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
	/*ch_right <= 0;
	if (i2s_done_o) begin	//clear condition: previous sample has been sent to buffer
		sample_L_done <= 1'b0;
		sample_R_done <= 1'b0;
	end*/
	i2s_done_o <= 1'b0;
	if (!rst_n | !get) begin	//rst or inactive condition
		fsm_state <= FSM_IDLE;
		ch_right <= 1'b0;
		//synch <= 1'b0;
	end else begin
		ch_right <= codec_aud_adclrck_i;	//può anche essere scritto più esternamente
		case(fsm_state)
			FSM_IDLE: begin
				/*if (codec_aud_adclrck_i == 1'b1) begin //eliminabile
					synch <= 1'b1;
					fsm_state <= FSM_IDLE;
				end else*/ if ((ch_right == 1'b1) && (codec_aud_adclrck_i == 1'b0)) begin	//dummy bit for left channel
					//ch_right <= 0;
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
					//dummy_trail_cnt <= dummy_trail_cnt + 1;
				end if (ch_right ^ codec_aud_adclrck_i) begin	//other channel start condition (dummy bit detected)
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
					//eventuale gestione caso dummy trail count e introduzione stato di errore
				end
			end
		endcase
	end
end

/*              
// Main FSM
always @ (posedge codec_aud_bclk_i) begin
    if(!rst_n) begin
        fsm_state <= FSM_IDLE;
        codec_aud_adclrck_o <= 0;
    end else case(fsm_state)
        FSM_IDLE: begin
            if(i2s_get_i) begin
                fsm_state <= FSM_GET;
                //sample_L <= i2s_sample_data_L_i;
                //sample_R <= i2s_sample_data_R_i;
                codec_aud_adclrck_o <= 0;
            end
        end
        FSM_GET: begin
            codec_aud_adclrck_o <= codec_aud_adclrck_o ^ end_of_sample;
            
            if(codec_aud_adclrck_o & end_of_sample) begin            
                if(i2s_get_i) begin
                    //sample_L <= i2s_sample_data_L_o;
                    //sample_R <= i2s_sample_data_R_o;
                end
                
                fsm_state <= (i2s_get_i) ? fsm_state : FSM_IDLE;
            end
        end
    endcase
end
*/

endmodule
