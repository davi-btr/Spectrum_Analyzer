module vga_controller(
	input clk,	//VGA_CLK = 108 MHz?
	input rst_n,
	input display_start_i, //dati pronti per essere stampati
	input [15:0]vga_buff_rdata_a_i,	//16 bit ogni campione
	input [15:0]vga_buff_rdata_b_i,	//16 bit ogni campione
	output reg vga_buff_reading_o, // vga buffer in uso, si può mettere direttamente come buff read_en senza passare da altri reg
	output [3:0]vga_buff_radd_a_o, // 16 campioni
	output [3:0]vga_buff_radd_b_o, // 16 campioni
	/*input [7:0]scan_code1,
	input [7:0]scan_code2,
	input [7:0]scan_code3,
	input [7:0]scan_code4,*/
	output vga_sync,	
	output vga_h_sync,
	output vga_v_sync,
	output inDisplayArea,	
	output vga_R,
	output vga_G, 
	output vga_B
);

// Params
localparam LEFT_MARG = 2;
localparam RIGHT_MARG = 2;
localparam X_PXL_PER_SAMPLE = 2;
//localparam X_SPACING = 0;


// Private regs
reg [1:0] vga_fsm_state;
reg draw_en;
reg val_R;
reg val_G;
reg val_B;
reg [3:0]add_a;
reg [3:0]add_b;
//reg [15:0]mem_data_a;
//reg [15:0]mem_data_b;
reg wren_a;
reg wren_b;
//reg [15:0]mem_q_a;
//reg [15:0]mem_q_b;
reg delay_to_mem;
reg [3:0]add_a_pipe1;
reg [3:0]add_a_pipe2;
reg [3:0]add_b_pipe1;
reg [3:0]add_b_pipe2;
reg wren_a_pipe1;
reg wren_a_pipe2;
reg wren_b_pipe1;
reg wren_b_pipe2;
reg within_margin;
reg end_of_screen;

// Private wires
wire [15:0] CounterX;
wire [15:0] CounterY;
//wire val_G;
//wire val_B;
wire [3:0]mem_add_a;
wire [3:0]mem_add_b;
wire mem_wren_a;
wire mem_wren_b;
wire [15:0]mem_q_a;
wire [15:0]mem_q_b;
wire need_wait;

// Private assignments
assign  vga_sync=1;	//forse eliminabile
//assign val_G = 0;
//assign val_B = 0;
assign vga_buff_radd_a_o = add_a;
assign vga_buff_radd_b_o = add_b;
assign mem_add_a = (delay_to_mem) ? add_a_pipe2 : add_a; 
assign mem_add_b = (delay_to_mem) ? add_b_pipe2 : add_b; 
assign mem_wren_a = (delay_to_mem) ? wren_a_pipe2 : wren_a; 
assign mem_wren_b = (delay_to_mem) ? wren_b_pipe2 : wren_b; 
assign need_wait = &add_b;

// Private instances
vga_timing_gen vga(
	.pixel_clk(clk),
	.draw_i(draw_en),
	.h_disp   (12'd1280),	//1280
	.h_fporch (12'd44),	//44	 //old 16
	.h_sync   (12'd108),	//108 	//old 96
	.h_bporch (12'd248),	//248	//old 48
	.v_disp   (12'd1024),	//1024
	.v_fporch (12'd1),	//1
	.v_sync   (12'd3),	//3
	.v_bporch (12'd38),	//38
	.vga_hs   (vga_h_sync),
	.vga_vs   (vga_v_sync),
	.vga_blank(inDisplayArea),
	.CounterY(CounterY),
	.CounterX(CounterX) 
);

storemem2port mem(	//registrati indirizzi in ingresso ma non q in uscita
	.address_a(mem_add_a),
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
		add_a_pipe1 <= 4'd0;
		add_a_pipe2 <= 4'd0;
		add_b_pipe1 <= 4'd0;
		add_b_pipe2 <= 4'd0;
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
                vga_fsm_state <= 0;        //RESET-IDLE
        end else begin
                case (vga_fsm_state)
                        0: begin
                                if (display_start_i) vga_fsm_state <= 1;        //COPY
                                else vga_fsm_state <= 0;        //RESET-IDLE
                        end
                        1: begin
                                if (need_wait) vga_fsm_state <= 2;        //WAIT
                                else vga_fsm_state <= 1;        //COPY
                        end
                        2: begin
                                if (add_b > 0) vga_fsm_state <= 2;        //WAIT, add_b recycled as a counter
                                else vga_fsm_state <= 3;        //DRAW
                        end
                        3: begin
                                if (end_of_screen) vga_fsm_state <= 0;        //RESET-IDLE
                                else vga_fsm_state <= 3;        //DRAW
                        end
                endcase
        end
end

// Output update
always@(posedge clk) begin
        //default output and reset
        //val_R        <=        0;
        val_G        <= 0;
        val_B        <= 0;
        vga_buff_reading_o <= 0;
        //vga_fsm_state        <=        0;
        draw_en                <=        0;
        wren_a <= 0;
        wren_b <= 0;
        add_a <= 4'd0;
        add_b <= 4'd0;        //4'd1;
        delay_to_mem <= 0;
        if (rst_n) begin
                //VALORI DA TENERE??
                case(vga_fsm_state)
                        1:        begin        //COPY
                                //first access (start reading) and default values for this state
                                vga_buff_reading_o <= 1;
                                delay_to_mem <= 1;
                                add_a <= 4'd0;
                                add_b <= 4'd1;
                                wren_a <= 1;
                                wren_b <= 1;
                                if (vga_buff_reading_o) begin
                                        //standard flow for copy
                                        add_a <= add_a + 4'd2;
                                        add_b <= add_b + 4'd2;
                                        if (add_b == 4'd15) begin
                                                vga_buff_reading_o <= 0;
                                                wren_a <= 0;
                                                wren_b <= 0;
                                                add_a <= 4'd0;
                                                add_b <= 4'd2;        //not used as address anymore, useful in WAIT
                                        end
                                end
                        end
                        2: begin //WAIT
                                delay_to_mem <= 1;
                                add_b <= add_b - 4'd1;
                                if (add_b == 0) begin
                                        //delay_to_mem <= 0;
                                        draw_en <= 1;
                                        add_b <= 0;        //used as a counter in DRAW
                                end
                        end
                        3:        begin        //DRAW
                                draw_en <= 1;
                                if (inDisplayArea & within_margin) begin
                                        if (add_b == (X_PXL_PER_SAMPLE - 1)) add_b <= 0;        // no pixel spacing within different samples
                                        else add_b <= add_b + 4'd1;
                                        if (add_b == (X_PXL_PER_SAMPLE - 2)) add_a <= add_a + 4'd1;        // compensate for registered input delay in memory
                                        else add_a <= add_a;
                                end
                        end
                endcase
    end
end

// Calc R_val
always @(CounterX or CounterY or mem_q_a) begin
        if ((CounterX >= LEFT_MARG) && (CounterX < (36 - RIGHT_MARG))) begin
                within_margin = 1;
                val_R = ((mem_q_a + CounterY) >= 15'd1023) ? 1'b1 : 1'b0;
        end else begin
                val_R = 0;
                within_margin = 0;
        end
        if ((CounterX == 36) && (CounterY == 1024)) end_of_screen = 1;        //verificare come si comporta vera VGA alla fine
        else end_of_screen = 0;
end

/* Main FSM
always@(posedge clk) begin
	if(!rst_n || !display_start_i) begin	// display_start_i basso ha la funzione di reset...si può usare in altro modo volendo
		val_R	<=	0;
		val_G	<= 0;
		val_B	<= 0;
		vga_buff_reading_o <= 0;
		vga_fsm_state	<=	2'b00;
		draw_en		<=	0;
		wren_a <= 0;
		wren_b <= 0;
		add_a <= 4'd0;
		add_b <= 4'd1;
		delay_to_mem <= 0;
		last_delay <= 0;
	end else begin
		// default output
		val_R <= 0;
		val_G	<= 0;
		val_B	<= 0;
		vga_buff_reading_o <= 0;
		delay_to_mem <= 0;
		wren_a <= 0;
		wren_b <= 0;
		draw_en <= 0;
		last_delay <= 0;
		case(vga_fsm_state)
			0:	begin	//copy
				// ad esempio si può controllare qui se display è alto ed interdire la copia andando in uno stato di reset
				vga_buff_reading_o <= 1;
				delay_to_mem <= 1;
				wren_a <= 1;
				wren_b <= 1;
				if (add_b < 4'd15) begin
					add_a <= add_a + 4'd2;
					add_b <= add_b + 4'd2;
					vga_fsm_state <= 0;
				end else begin
					add_a <= 0;
					add_b <= 0;	// da questo momento è un segnale libero
					vga_fsm_state <= 1;
					wren_a <= 0;
					wren_b <= 0;
					delay_to_mem <= 1;	// in questa esecuzione si recupera uno dei due ritardi di pipeline
					last_delay <= 1;		// si può usare add_b
					vga_buff_reading_o <= 0;
				end
			end
			1:	begin	//draw
				vga_fsm_state <= 1;
				if (delay_to_mem && last_delay) begin // recupero ultimo ciclo di pipeline se serve
					delay_to_mem <= 1;
					last_delay <= 0;
					//vga_fsm_state <= 1;
				end else if (delay_to_mem) begin
					delay_to_mem <= 0;
				end else begin
					draw_en <= 1;
					if ((CounterX >= LEFT_MARG) && (CounterX < (36 - RIGHT_MARG))) begin
						if (add_b == 4'd0) begin	// add_b usato come semplice contatore visto che inutilizzato
							val_R <= ((mem_q_a + CounterY) >= 15'd1023) ? 1 : 0;
							add_a <= add_a + 4'd1;
							//if (add_a == 4'd15) last_sample <= 1;
							add_b <= add_b + 4'd1;
						end else if (add_b < X_PXL_PER_SAMPLE - 1) begin
							val_R <= val_R;
							add_b <= add_b + 4'd1;
						end else begin
							val_R <= val_R;
							add_b <= 4'd0;
						end
					end else begin
						add_a <= 4'd0;
						//val_R <= 0;
						if ((CounterX == 36-1) && (CounterY == 1024-1)) begin
							//vga_fsm_state <= 1; potrebbe tornare in copia
							draw_en <= 0;	//commentabile...ora per prova
						end
					end
				end
			 end*/
			 /*2:	begin
				  CMD	<=	CMD+4'd1;
				  codec_init_fsm_state	<=	0;
			 end*/
		/*endcase
    end
end*/

// VGA data out
assign	vga_R = val_R & inDisplayArea;
assign	vga_G = val_G & inDisplayArea;
assign	vga_B = val_B & inDisplayArea;

endmodule
