module vga_adapter (
	//input
	clk,
	adaptation_start_i,
	max_value_i,
	//output
	read_in_buffer_addr1_o,
	read_in_buffer_addr2_o,
	wen_o,
	MSB_o,
	adaptation_done_o
);


input clk;
input adaptation_start_i;
input [63:0] max_value_i;

output reg [9:0] read_in_buffer_addr1_o;
output reg [9:0] read_in_buffer_addr2_o;
output reg wen_o = 1'b0;
output [5:0] MSB_o;
output reg adaptation_done_o = 1'b0;


localparam s0 = 2'b00, ADAPT = 2'b01, WAIT = 2'b10, SEARCH_MSB = 2'b11;


reg adaptation_done_reg = 1'b0;
reg [63:0] max_value_reg = 64'b0;
reg [63:0] shift;
reg [63:0] shift_next;
reg [5:0] MSB = 6'd0;
reg [5:0] MSB_next = 6'd0;
reg [5:0] n = 6'd0;
reg [5:0] n_next = 6'd0;
reg MSB_found = 1'b0;
reg MSB_found_next = 1'b0;
reg [9:0] read_in_buffer_addr1_reg;
reg [9:0] read_in_buffer_addr2_reg;
reg wen_reg;
reg [2:0] sreg = s0;
reg [2:0] snext = s0;

reg [8:0] j = 9'b0;
reg [8:0] jnext = 9'b0;

assign MSB_o = MSB;

//è legale?
always @ (posedge adaptation_start_i) 
	max_value_reg <= max_value_i;
	
always @ (posedge clk)
begin
	MSB <= MSB_next;
	MSB_found <= MSB_found_next;
	read_in_buffer_addr1_o <= read_in_buffer_addr1_reg;
	read_in_buffer_addr2_o <= read_in_buffer_addr2_reg;
	adaptation_done_o <= adaptation_done_reg;
	j <= jnext;
	sreg <= snext;
	wen_o <= wen_reg;
	shift <= shift_next;
	n <= n_next;
end

/*
always @ (max_value_reg or MSB)
begin
	for(n = 0; n < 64; n = n + 1'b1)
	begin
		if(max_value_reg[n]) MSB_next = n[5:0];
		else MSB_next = MSB;
		if(n == 6'd63) MSB_found_next = 1'b1;
		else MSB_found_next = 1'b0;
	end
end
*/

always @ (sreg or MSB_found or j or max_value_reg or MSB or adaptation_start_i or shift or n) 
begin
	adaptation_done_reg = 1'b0;
	case(sreg)
		s0 : begin
			n_next = 6'b0;
			shift_next = 64'd0;
			jnext = 9'b0;
			read_in_buffer_addr1_reg = 10'b0;
			read_in_buffer_addr2_reg = 10'b0;
			wen_reg = 1'b0;
			MSB_next = 1'b0;
			MSB_found_next = 1'b0;
			if(adaptation_start_i) 
			begin
				snext = SEARCH_MSB;
				n_next = 6'd63;
				shift_next = 64'h8000000000000000;
			end
			else snext = s0;
		end
		
		SEARCH_MSB : begin
			if((shift & max_value_reg) || (shift == 64'd0))
			begin
				MSB_next = n;
				snext = ADAPT;
				n_next = 6'b0;
				shift_next = 64'b0;
				MSB_found_next = 1'b1;
				wen_reg = 1'b1;
			end
			else
			begin
				MSB_next = 6'b0;
				snext = SEARCH_MSB;
				n_next = n - 1'b1;
				shift_next = (shift >> 1);
				MSB_found_next = 1'b0;
				wen_reg = 1'b0;
			end
			jnext = 9'b0;
			read_in_buffer_addr1_reg = 10'b0;
			read_in_buffer_addr2_reg = 10'b0;
		end 
		
		ADAPT : begin
			shift_next = 64'd0;
			n_next = 6'b0;
			MSB_next = MSB;
			MSB_found_next = 1'b1;
			wen_reg = 1'b1;
			jnext = j + 1'b1;
			read_in_buffer_addr1_reg = {j,1'b0};
			read_in_buffer_addr2_reg = {j,1'b1};
			if(j == 9'd511) snext = WAIT;
			else snext = ADAPT;
		end
		
		WAIT : begin
			shift_next = 64'd0;
			n_next = 6'b0;
			MSB_next = MSB;
			MSB_found_next = 1'b1;
			wen_reg = 1'b1;
			jnext = j + 1'b1;
			read_in_buffer_addr1_reg = {j,1'b0}; //per avere indirizzi diversi
			read_in_buffer_addr2_reg = {j,1'b1};
			if(j == 9'd1) 
			begin
				snext = s0;
				adaptation_done_reg = 1'b1;
			end
			else snext = WAIT;
		end
		
		default : begin
			shift_next = 64'd0;
			n_next = 6'd0;
			jnext = 9'b0;
			read_in_buffer_addr1_reg = 10'b0;
			read_in_buffer_addr2_reg = 10'b0;
			wen_reg = 1'b0;
			snext = s0;
		end
	endcase
end
	


	
endmodule
