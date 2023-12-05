module addr_gen_unit(
    clk,
    rst_n,
    address_a_o,
    address_b_o,
	 memsel_o,
	 twiddle_addr,
	 start_i
);

//Parameters
localparam s0 = 1'b0, ADDRESS_GENERATION = 1'b1;

//Ports definition
input clk;
input rst_n;
input start_i;
output reg memsel_o;
output reg [8:0]twiddle_addr = 9'b0;
output reg [9:0]address_a_o;
output reg [9:0]address_b_o;

//Private wires

//Private regs

reg sreg = s0;
reg snext;
reg [8:0] j = 9'b0;
reg [3:0] i = 4'b0;
reg [9:0] j_double = 10'b0;

//Private assignments

assign j_double[9:0] = {0, j[8:0]};

//Aggiornamento stato FSM e contatori
always @(posedge clk) begin
	if(!rst_n)
	begin
			sreg <= s0;
			i <= 4'b0;
			j <= 9'b0;
	end
   else
	begin
			sreg <= snext;
			j <= j+1'b1;
			if(j == 9'd511)
				i <= i + 1'b1;
			else
				i <= i;
	end
			
end




// stato futuro e uscite
always @ (sreg or j or i or start_i)
begin
	case(sreg)
	s0 :
		if(start_i) snext = ADDRESS_GENERATION;
		else snext = s0;
	ADDRESS_GENERATION : 
	begin
		if(i == 4'd9 && j == 9'd511)
			snext = s0;
		else
		begin
			snext = CALC_FFT;
			address_a_o[9:0] = {(j_double << 1)[9-i:0], (j_double << 1)[9:9-i+1]};
			address_b_o[9:0] = {((j_double << 1) + 1'b1)[9-i:0], ((j_double << 1)+1'b1)[9:9-i+1]};
			twiddle_addr[8:0] += (1 << 9-i);
			memsel_o = i[0]; 
		end
	end
	default: 
		snext = s0;
	endcase 
end





endmodule
