module vga_controller(
	input clk,	//VGA_CLK = 108 MHz?
	input rst_n,
	input display_start_i, //dati pronti per essere stampati
	input [15:0]vga_buff_rdata_a_i,	//16 bit ogni campione
	input [15:0]vga_buff_rdata_b_i,	//16 bit ogni campione
	output reg vga_buff_reading_o, // vga buffer in uso, si può mettere direttamente come buff read_en senza passare da altri reg
	output [9:0]vga_buff_radd_a_o,
	output [9:0]vga_buff_radd_b_o,
	output vga_sync,	
	output vga_h_sync,
	output vga_v_sync,
	output inDisplayArea,	
	output vga_R,
	output vga_G, 
	output vga_B
);

// Params
localparam LEFT_MARG = 144;	//144
localparam RIGHT_MARG = 144;	//144
localparam X_PXL_PER_SAMPLE = 1;	//1
localparam DISPLAY_WIDTH = 800;	//800
localparam DISPLAY_HEIGHT = 600;
//localparam X_SPACING = 0;


// Private regs
reg [1:0] vga_fsm_state;
reg draw_en;			// VGA attiva
reg val_R;
reg val_G;
reg val_B;
reg [9:0]add_a;		// indirizzi memoria interna
reg [9:0]add_b;
reg wren_a;				// scirttura abilitata in memoria interna
reg wren_b;
reg delay_to_mem;		// usa pipeline per allineare ritardi
reg [9:0]add_a_pipe1;
reg [9:0]add_a_pipe2;
reg [9:0]add_b_pipe1;
reg [9:0]add_b_pipe2;
reg wren_a_pipe1;
reg wren_a_pipe2;
reg wren_b_pipe1;
reg wren_b_pipe2;
reg within_margin;	// dentro i margini dello schermo (area di disegno)

// Private wires
wire [15:0] CounterX;// ascissa pixel
wire [15:0] CounterY;// ordinata pixel
wire [9:0]mem_add_a;
wire [9:0]mem_add_b;
wire mem_wren_a;
wire mem_wren_b;
wire [15:0]mem_q_a;
wire [15:0]mem_q_b;
wire need_wait;		// esaurire pipeline

// Private assignments
assign  vga_sync=1;
assign vga_buff_radd_a_o = add_a;
assign vga_buff_radd_b_o = add_b;
assign mem_add_a = (delay_to_mem) ? add_a_pipe2 : add_a; 
assign mem_add_b = (delay_to_mem) ? add_b_pipe2 : add_b; 
assign mem_wren_a = (delay_to_mem) ? wren_a_pipe2 : wren_a; 
assign mem_wren_b = (delay_to_mem) ? wren_b_pipe2 : wren_b; 
assign need_wait = &add_b;

// Private instances
vga_time_generator vga(
	.pixel_clk(clk),
	.draw_i(draw_en),
	//temporizzazioni richieste per SVGA 800x600 (in cicli di clock)
	.h_disp   (12'd800),
	.h_fporch (12'd15),
	.h_sync   (12'd79),
	.h_bporch (12'd159),
	.v_disp   (12'd600),
	.v_fporch (12'd1),
	.v_sync   (12'd3),
	.v_bporch (12'd21),
	.vga_hs   (vga_h_sync),
	.vga_vs   (vga_v_sync),
	.vga_blank(inDisplayArea),
	.CounterY(CounterY),
	.CounterX(CounterX) 
);

storemem2port mem(			//questa memoria è configurata sincrona ma non con registro di uscita su q,
	.address_a(mem_add_a),	//dunque vi è un ciclo in meno di ritardo sulle uscite
	.address_b(mem_add_b),
	.clock(clk),
	.data_a(vga_buff_rdata_a_i),
	.data_b(vga_buff_rdata_b_i),
	.wren_a(mem_wren_a),
	.wren_b(mem_wren_b),
	.q_a(mem_q_a),
	.q_b(mem_q_b)
);

// Delay address and enable to mem when needed (2 cicles)
always @(posedge clk) begin
	if (!rst_n) begin
		add_a_pipe1 <= 10'd0;
		add_a_pipe2 <= 10'd0;
		add_b_pipe1 <= 10'd0;
		add_b_pipe2 <= 10'd0;
		wren_a_pipe1 <= 0;
		wren_a_pipe2 <= 0;
		wren_b_pipe1 <= 0;
		wren_b_pipe2 <= 0;
	end else begin
		add_a_pipe1 <= add_a;
		add_a_pipe2 <= add_a_pipe1;
		add_b_pipe1 <= add_b;
		add_b_pipe2 <= add_b_pipe1;
		wren_a_pipe1 <= wren_a;
		wren_a_pipe2 <= wren_a_pipe1;
		wren_b_pipe1 <= wren_b;
		wren_b_pipe2 <= wren_b_pipe1;
	end
end

// Next state update
always @(posedge clk) begin
        if (~rst_n) begin
                vga_fsm_state <= 0;		//RESET
        end else begin
                case (vga_fsm_state)
                        0: begin
                                if (display_start_i) vga_fsm_state <= 1;	//COPY
                                else vga_fsm_state <= 0;        				//RESET
                        end
                        1: begin
                                if (need_wait) vga_fsm_state <= 2;        	//WAIT
                                else vga_fsm_state <= 1;        				//COPY
                        end
                        2: begin
                                if (add_b > 0) vga_fsm_state <= 2;        	//WAIT
                                else vga_fsm_state <= 3;        				//DRAW
                        end
                        3: begin
                                if (display_start_i) vga_fsm_state <= 1;	//RESET-IDLE
                                else vga_fsm_state <= 3;        				//DRAW
                        end
                endcase
        end
end

// Output update
always@(posedge clk) begin
	  //default output (and reset values)
	  vga_buff_reading_o <= 0;
	  draw_en <= 0;
	  wren_a <= 0;
	  wren_b <= 0;
	  add_a <= 0;
	  add_b <= 0;
	  delay_to_mem <= 0;
	  if (rst_n) begin
		 case(vga_fsm_state)
			1: begin		//COPY
			  draw_en <= 1;
			  vga_buff_reading_o <= 1;
			  delay_to_mem <= 1;
			  add_a <= 0;
			  add_b <= 1;
			  wren_a <= 1;
			  wren_b <= 1;
			  if (vga_buff_reading_o) begin	//scorre la memoria 2 a 2 (double port)
				 add_a <= add_a + 10'd2;
				 add_b <= add_b + 10'd2;
				 if (add_b == 10'd1023) begin
					vga_buff_reading_o <= 0;
					wren_a <= 0;
					wren_b <= 0;
					add_a <= 0;
					add_b <= 2;
				 end
			  end
			end
			2: begin 	//WAIT
			  draw_en <= 1;
			  delay_to_mem <= 1;
			  add_b <= add_b - 10'd1;
			  if (add_b == 0) begin
				 add_b <= 0;        		//può essere utilizzato come contatore da ora in poi,
			  end								//per non impegnare nuovi registri
			end
			3: begin     //DRAW
			  draw_en <= 1;
			  if (inDisplayArea & within_margin) begin
					 if (add_b == (X_PXL_PER_SAMPLE - 1)) add_b <= 0;	//numero di pixel per campione (attualmente 1)
					 else add_b <= add_b + 10'd1;
						add_a <= add_a + 10'd1;
			  end
			end
		 endcase
    end
end

// Rete combinatoria per il calcolo delle uscite (valore dei pixel)
always @(CounterX or CounterY or mem_q_a) begin
  if ((CounterX >= LEFT_MARG - 10) && (CounterX < (DISPLAY_WIDTH - RIGHT_MARG + 10))) begin
	if (((CounterX < LEFT_MARG) || (CounterX > (DISPLAY_WIDTH - RIGHT_MARG))) && (CounterY <= 16'd560 && CounterY >= 16'd40)) begin //
		within_margin = 0;
		val_R = 1;
		val_G = 1;
		val_B = 1;
	end
	else begin
		within_margin = 1;
		if(CounterY <= 16'd560 && CounterY >= 16'd40)  begin
			val_R = 1'b1;
			val_G = (((mem_q_a + CounterY) >= 16'd551) && (CounterY <= 16'd551)) ? 1'b0 : 1'b1;
			val_B = (((mem_q_a + CounterY) >= 16'd551) && (CounterY <= 16'd551)) ? 1'b0 : 1'b1;
		end
		else begin
			val_R = 0;
			val_G = 0;
			val_B = 0;
		end
	end
  end else 
  begin
	 val_R = 0;
	 val_G = 0;
	 val_B = 0;
	 within_margin = 0;
  end

end

// VGA data out
assign	vga_R = val_R & inDisplayArea;
assign	vga_G = val_G & inDisplayArea;
assign	vga_B = val_B & inDisplayArea;

endmodule
