module addr_gen_unit(
    clk,
    rst_n,
	 start_i,
    address_a_o,
    address_b_o,
	 memsel_o,
	 twiddle_addr_o,
	 read_address_buffer_o,
	 loading_o
);

//Parameters
localparam s0 = 2'b00, LOAD = 2'b01, ADDRESS_GENERATION = 2'b10, WAIT = 2'b11;

integer k;

//Ports definition
input clk;
input rst_n;
input start_i;
output reg memsel_o;
output reg loading_o;
output reg [8:0]twiddle_addr_o = 9'b0;
output reg [9:0]address_a_o;
output reg [9:0]address_b_o;
output reg [9:0]read_address_buffer_o;

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
end



// RC stato futuro e uscite
always @ (sreg or j or i or start_i or twiddle_addr_o or read_address_buffer_o or loading_o)
begin
	
	case(sreg)
	
	s0 : 
	begin
		address_a_reg = 0;
		address_b_reg = 0;
		memsel_reg = 0;
		twiddle_addr_reg = 0;
		jnext = 0;
		inext = 0;
		k = 0;
		loading_reg = 1'b0;
		read_address_buffer_reg = 0;
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
		for(k = 0; k < 10; k = k+1) address_a_reg[k] = read_address_buffer_o[9-k]; //bit reversal operation
																										   //address_a_o dovrà essere rotardato di 2 cicli di ck per la latenza del buffer
		address_b_reg = address_a_reg;
		twiddle_addr_reg = 0;
		jnext = 0;
		inext = 0;
	end
	
	ADDRESS_GENERATION : 
	begin
		read_address_buffer_reg = 0;
		loading_reg = 1'b0;
		jnext = j + 1'b1;
		inext = i;
		k = 0;
		memsel_reg = i[0];
		if(j == 9'd511) 
		begin
			address_a_reg = 0;
			address_b_reg = 0;
			memsel_reg = 0;
			twiddle_addr_reg = 0;  
			//if(i == 4'd9) snext = s0;
			snext = WAIT;
		end
		else
		begin
			snext = ADDRESS_GENERATION;
			twiddle_addr_reg = twiddle_addr_o + (9'b1 << 9-i); 
			case (i)
			0	: begin
				address_a_reg[9:0] = {j[8:0],1'b0};
				address_b_reg[9:0] = {j[8:0],1'b1};
				end
			1	: begin
				address_a_reg[9:0] = {j[7:0],1'b0,j[8]};
				address_b_reg[9:0] = {j[7:0],1'b1,j[8]};
				end
			2	: begin
				address_a_reg[9:0] = {j[6:0],1'b0,j[8:7]};
				address_b_reg[9:0] = {j[6:0],1'b1,j[8:7]};
				end
			3	: begin
				address_a_reg[9:0] = {j[5:0],1'b0,j[8:6]};
				address_b_reg[9:0] = {j[5:0],1'b1,j[8:6]};
				end
			4	: begin
				address_a_reg[9:0] = {j[4:0],1'b0,j[8:5]};
				address_b_reg[9:0] = {j[4:0],1'b1,j[8:5]};
				end
			5	: begin
				address_a_reg[9:0] = {j[3:0],1'b0,j[8:4]};
				address_b_reg[9:0] = {j[3:0],1'b1,j[8:4]};
				end
			6	: begin
				address_a_reg[9:0] = {j[2:0],1'b0,j[8:3]};
				address_b_reg[9:0] = {j[2:0],1'b1,j[8:3]};
				end
			7	: begin
				address_a_reg[9:0] = {j[1:0],1'b0,j[8:2]};
				address_b_reg[9:0] = {j[1:0],1'b1,j[8:2]};
				end
			8	: begin
				address_a_reg[9:0] = {j[0],1'b0,j[8:1]};
				address_b_reg[9:0] = {j[0],1'b1,j[8:1]};
				end
			9	: begin
				address_a_reg[9:0] = {1'b0,j};
				address_b_reg[9:0] = {1'b1,j};
				end
			default	: begin
				address_a_reg = 9'd0;
				address_b_reg = 9'd0;
				end
			endcase
		end
	end
	
	WAIT : 
	begin
		k = 0;
		read_address_buffer_reg = 0;
		if(loading_o) memsel_reg = 1'b1;
		else memsel_reg = i[0];
		address_a_reg = 0;
		address_b_reg = 0;
		twiddle_addr_reg = 0; 
		if(j == 9'd3)
		begin
			jnext = 9'd0;
			loading_reg = 1'b0;
			if(i == 4'd9) 
			begin
				snext = s0;
				inext = i + 1'b1;
			end
			else
			begin
				snext = ADDRESS_GENERATION;
				if(loading_o) inext = 1'b0;
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
	
	default:
	begin
		k = 0;
		read_address_buffer_reg = 0;
		snext = s0;
		address_a_reg = 0;
		address_b_reg = 0;
		memsel_reg = 0;
		twiddle_addr_reg = 0;
		jnext = 0;
		inext = 0;		
		loading_reg = 0;
	end
	endcase 
end


endmodule
