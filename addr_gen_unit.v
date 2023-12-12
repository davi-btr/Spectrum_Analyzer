module addr_gen_unit(
    clk,
    rst_n,
    address_a_o,
    address_b_o,
	 memsel_o,
	 twiddle_addr_o,
	 start_i
);

//Parameters
localparam s0 = 2'b00, ADDRESS_GENERATION = 2'b01, WAIT = 2b'10;

//Ports definition
input clk;
input rst_n;
input start_i;
output reg memsel_o;
output reg [8:0]twiddle_addr_o = 9'b0;
output reg [9:0]address_a_o;
output reg [9:0]address_b_o;

//Private wires



//Private regs

reg [9:0]address_a_reg;
reg [9:0]address_b_reg;
reg [8:0]twiddle_addr_reg = 9'b0;
reg memsel_reg;
reg sreg = s0;
reg snext;
reg jnext;
reg inext;
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
	twiddle_addr_o <= twiddle_addr_reg;
	memsel_o <= memsel_reg;
end



// RC stato futuro e uscite
always @ (sreg or j or i or start_i or twiddle_addr_o)
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
		if(start_i) snext = ADDRESS_GENERATION;
		else snext = s0;
	end
	
	ADDRESS_GENERATION : 
	begin
		jnext = j + 1'b1;
		inext = i;
		memsel_reg = i[0];
		if(j == 9'd511) 
		begin
			address_a_reg = 0;
			address_b_reg = 0;
			memsel_reg = 0;
			twiddle_addr_reg = 0;  
			if(i == 4'd9) snext = s0;
			else snext = WAIT;
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
		memsel_reg = i[0];
		address_a_reg = 0;
		address_b_reg = 0;
		twiddle_addr_reg = 0; 
		if(j == 9'd3)
		begin
			snext = ADDRESS_GENERATION;
			inext = i + 1'b1;
			jnext = 9'd0;
		end
		else 
		begin
			snext = WAIT;
			jnext = j + 1b'1;
			inext = i;
		end
	end
	
	default: 
		snext = s0;
	endcase 
end


endmodule
