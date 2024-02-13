module addr_gen_unit(
    clk,
    rst_n,
	 start_i,
    address_a_o,
    address_b_o,
	 memsel_o,
	 twiddle_addr_o,
	 read_address_buffer_o,
	 loading_o,
	 fft_done_o,
	 vga_start_o
);

//Parameters
localparam s0 = 3'b000, LOAD = 3'b001, ADDRESS_GENERATION = 3'b010, WAIT = 3'b011, FFT_OUT = 3'b100;

//integer k;

//Ports definition
input clk;
input rst_n;
input start_i;
output reg memsel_o = 1'b0;
output reg loading_o = 1'b0;
output reg [8:0]twiddle_addr_o = 9'b0;
output reg [9:0]address_a_o = 10'b0;
output reg [9:0]address_b_o = 10'b1;
output reg [9:0]read_address_buffer_o = 10'b0;
output reg fft_done_o = 1'b0;
output reg vga_start_o = 1'b0;
//Private wires



//Private regs

reg [9:0]read_address_buffer_reg;
reg [9:0]address_a_reg;
reg [9:0]address_b_reg;
reg [8:0]twiddle_addr_reg = 9'b0;
reg loading_reg;
reg memsel_reg;
reg [2:0] sreg = s0;
reg [2:0] snext;
reg [8:0] jnext;
reg [3:0] inext;
reg [8:0] j = 9'b0;
reg [3:0] i = 4'b0;
reg fft_done_reg = 1'b0;
reg vga_start_reg = 1'b0;


//Private assignments

//assign j_double[9:0] = {0, j[8:0]};

//Aggiornamento stato FSM e contatori
always @(posedge clk) 
begin
	if(!rst_n)
	begin
			sreg <= s0;
			i <= 4'b0;
			j <= 9'b0;
	end
   else
	begin
			sreg <= snext;
			j <= jnext;
			i <= inext;
	end			
end


//Aggiornamento delle uscite
always @(posedge clk) 
begin
	address_a_o <= address_a_reg;
	address_b_o <= address_b_reg;
	read_address_buffer_o <= read_address_buffer_reg;
	twiddle_addr_o <= twiddle_addr_reg;
	memsel_o <= memsel_reg;
	loading_o <= loading_reg;
	fft_done_o <= fft_done_reg;
	vga_start_o <= vga_start_reg;
end



// RC stato futuro e uscite
always @ (sreg or j or i or start_i or twiddle_addr_o or read_address_buffer_o or loading_o or fft_done_o)
begin
	address_a_reg = 10'b0;//altrimenti mette latch
	fft_done_reg = 1'b0;
	vga_start_reg = 1'b0;
	
	case(sreg)
	
	s0 : 
	begin
		if(fft_done_o) vga_start_reg = 1'b1;
		address_a_reg = 10'b0;
		address_b_reg = 10'b0;
		memsel_reg = 1'b0;
		twiddle_addr_reg = 9'b0;
		jnext = 9'b0;
		inext = 4'b0;
		//k = 0;
		loading_reg = 1'b0;
		read_address_buffer_reg = 10'b0;
		if(start_i) snext = LOAD;
		else snext = s0;
	end
	
	LOAD :
	begin
		if(read_address_buffer_o == 10'd1023) snext = WAIT;
		else snext = LOAD;
		loading_reg = 1'b1;
		read_address_buffer_reg = read_address_buffer_o + 1'b1;
		memsel_reg = 1'b1;
		//if(read_address_buffer_reg == 4'd15) snext = WAIT;
		//else snext = LOAD;
		//for(k = 0; k < 3; k = k+1) address_a_reg[k] = read_address_buffer_reg[3-k]; 
		//bit reversal operation //address_a_o dovrà essere ritardato di 2 cicli di ck per la latenza del buffer
		address_a_reg[9:0] = {read_address_buffer_reg[0], read_address_buffer_reg[1], read_address_buffer_reg[2], read_address_buffer_reg[3], read_address_buffer_reg[4], read_address_buffer_reg[5], read_address_buffer_reg[6], read_address_buffer_reg[7], read_address_buffer_reg[8], read_address_buffer_reg[9]};
		address_b_reg = read_address_buffer_reg; //per avere add_b != da add_a! tanto la scrittura è disabilitata. NB: non è vero che sono sempre diversi: 1001 => 1001, ma comunque non cambia niente
		twiddle_addr_reg = 9'b0;
		jnext = 9'b0;
		inext = 4'b0;
	end
	
	ADDRESS_GENERATION : 
	begin
		read_address_buffer_reg = 10'b0;
		loading_reg = 1'b0;
		jnext = j + 1'b1;
		inext = i;
		//k = 0;
		memsel_reg = i[0];
		//if(j == 3'b0) twiddle_addr_reg = 0;
		//else twiddle_addr_reg = twiddle_addr_o + (3'b1 << 3-i); 
		case (i)
			0	: begin //N-1-i = 9
				address_a_reg[9:0] = {j[8:0],1'b0};
				address_b_reg[9:0] = {j[8:0],1'b1};
				twiddle_addr_reg = 9'b0;
				end
			1	: begin												
				address_a_reg[9:0] = {j[7:0],1'b0,j[8]}; 
				address_b_reg[9:0] = {j[7:0],1'b1,j[8]};
				twiddle_addr_reg = {j[8],8'b0};
				end
			2	: begin
				address_a_reg[9:0] = {j[6:0],1'b0,j[8:7]}; 
				address_b_reg[9:0] = {j[6:0],1'b1,j[8:7]};
				twiddle_addr_reg = {j[8:7],7'b0};
				end
			3	: begin
				address_a_reg[9:0] = {j[5:0],1'b0,j[8:6]};
				address_b_reg[9:0] = {j[5:0],1'b1,j[8:6]};
				twiddle_addr_reg = {j[8:6],6'b0};
				end
			4	: begin
				address_a_reg[9:0] = {j[4:0],1'b0,j[8:5]};
				address_b_reg[9:0] = {j[4:0],1'b1,j[8:5]};
				twiddle_addr_reg = {j[8:5],5'b0};
				end
			5	: begin
				address_a_reg[9:0] = {j[3:0],1'b0,j[8:4]};
				address_b_reg[9:0] = {j[3:0],1'b1,j[8:4]};
				twiddle_addr_reg = {j[8:4],4'b0};
				end
			6	: begin
				address_a_reg[9:0] = {j[2:0],1'b0,j[8:3]};
				address_b_reg[9:0] = {j[2:0],1'b1,j[8:3]};
				twiddle_addr_reg = {j[8:3],3'b0};
				end
			7	: begin
				address_a_reg[9:0] = {j[1:0],1'b0,j[8:2]};
				address_b_reg[9:0] = {j[1:0],1'b1,j[8:2]};
				twiddle_addr_reg = {j[8:2],2'b0};
				end
			8	: begin
				address_a_reg[9:0] = {j[0],1'b0,j[8:1]};
				address_b_reg[9:0] = {j[0],1'b1,j[8:1]};
				twiddle_addr_reg = {j[8:1],1'b0};
				end
			9	: begin
				address_a_reg[9:0] = {1'b0,j};
				address_b_reg[9:0] = {1'b1,j};
				twiddle_addr_reg = j;
				end
			default	: begin
				address_a_reg = 10'd0;
				address_b_reg = 10'd0;
				twiddle_addr_reg = 9'd0;
				end
		endcase
		if(j == 9'd511) snext = WAIT;
		else snext = ADDRESS_GENERATION;
	end
	
	
	// RIPREDENDI DA QUI
	
	WAIT : 
	begin
		//k = 0;
		read_address_buffer_reg = 10'b0;
		if(loading_o) memsel_reg = 1'b1;
		else memsel_reg = i[0];
		address_a_reg = {j,1'b1}; //prova per vedere se anche così diventa undef per read_during_write
		address_b_reg = {j,1'b0}; //in questo modo add_a != add_b
		twiddle_addr_reg = 9'b0; 
		//jnext = j + 1'b1;
		if(j == 9'd1) 
		begin
			jnext = 9'd0;
			loading_reg = 1'b0;
			memsel_reg = i[0];
			if(i == 4'd9) 
			begin
				snext = FFT_OUT;
				inext = 4'b0;
			end
			else
			begin
				snext = ADDRESS_GENERATION;
				if(loading_o) inext = 4'b0;
				else inext = i + 1'b1;
			end
		end
		else 
		begin
			snext = WAIT;
			jnext = j + 1'b1;
			inext = i;
			loading_reg = loading_o;
		end
	end
	
	FFT_OUT : 
	begin
		fft_done_reg = 1'b1;
		address_a_reg = {j, 1'b0};
		address_b_reg = {j, 1'b1};
		jnext = j + 1'b1;
		read_address_buffer_reg = 10'b0;
		memsel_reg = 1'b0;
		inext = 1'b0;
		loading_reg = 1'b0;
		twiddle_addr_reg = 9'b0;
		if(j == 9'd511) snext = s0;
		else snext = FFT_OUT;
	end
	
	default:
	begin
		//k = 0;
		read_address_buffer_reg = 10'b0;
		snext = s0;
		address_a_reg = 10'b0;
		address_b_reg = 10'b0;
		memsel_reg = 1'b0;
		twiddle_addr_reg = 9'b0;
		jnext = 9'b0;
		inext = 4'b0;		
		loading_reg = 1'b0;
	end
	endcase 
end


endmodule
