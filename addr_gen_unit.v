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
//reg [9:0] j_double = 10'b0;

//Private assignments

//assign j_double[9:0] = {0, j[8:0]};

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
	s0 : begin
		address_a_o = 0;
		address_b_o = 0;
		memsel_o = 0;
		twiddle_addr = 0;
		if(start_i) snext = ADDRESS_GENERATION;
		else snext = s0;
		end
	ADDRESS_GENERATION : 
	begin
		if(i == 4'd9 && j == 9'd511) begin
			snext = s0;
			address_a_o = 0;
			address_b_o = 0;
			memsel_o = 0;
			twiddle_addr = 0; end
		else
		begin
			snext = ADDRESS_GENERATION;
			case (i)
			0	: begin
				address_a_o[9:0] = {j[8:0],1'b0/*(j_double << 1)[(9-i)9:0], j_double(j_double << 1)[9:0(9-i+1)]*/};
				address_b_o[9:0] = {j[8:0],1'b1/*((j_double << 1) + 1'b1)[(9-i):0], ((j_double << 1)+1'b1)[9:(9-i+1)]*/};
				end
			1	: begin
				address_a_o[9:0] = {j[7:0],1'b0,j[8]};
				address_b_o[9:0] = {j[7:0],1'b1,j[8]};
				end
			2	: begin
				address_a_o[9:0] = {j[6:0],1'b0,j[8:7]};
				address_b_o[9:0] = {j[6:0],1'b1,j[8:7]};
				end
			3	: begin
				address_a_o[9:0] = {j[5:0],1'b0,j[8:6]};
				address_b_o[9:0] = {j[5:0],1'b1,j[8:6]};
				end
			4	: begin
				address_a_o[9:0] = {j[4:0],1'b0,j[8:5]};
				address_b_o[9:0] = {j[4:0],1'b1,j[8:5]};
				end
			5	: begin
				address_a_o[9:0] = {j[3:0],1'b0,j[8:4]};
				address_b_o[9:0] = {j[3:0],1'b1,j[8:4]};
				end
			6	: begin
				address_a_o[9:0] = {j[2:0],1'b0,j[8:3]};
				address_b_o[9:0] = {j[2:0],1'b1,j[8:3]};
				end
			7	: begin
				address_a_o[9:0] = {j[1:0],1'b0,j[8:2]};
				address_b_o[9:0] = {j[1:0],1'b1,j[8:2]};
				end
			8	: begin
				address_a_o[9:0] = {j[0],1'b0,j[8:1]};
				address_b_o[9:0] = {j[0],1'b1,j[8:1]};
				end
			9	: begin
				address_a_o[9:0] = {1'b0,j};
				address_b_o[9:0] = {1'b1,j};
				end
			default	: begin
				address_a_o = 9'd0;
				address_b_o = 9'd0;
				end
				endcase
			twiddle_addr = twiddle_addr + (9'b1 << 9-i);
			memsel_o = i[0]; 
		end
	end
	default: 
		snext = s0;
	endcase 
end





endmodule
