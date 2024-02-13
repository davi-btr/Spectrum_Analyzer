module max_finder (
	//input
	clk,
	vga_start_i,
	vga_buffer_data_i,
	//output
	read_vga_buff_add_o, //forse avere due indirizzi complica estremamente la vita
	searching_max_o,
	max_found_o,
	max_value_o,
	max_value_address_o
);


input clk;
input vga_start_i;
input [63:0] vga_buffer_data_i;


output reg max_found_o = 1'b0;
output reg searching_max_o = 1'b0;
output reg [9:0] read_vga_buff_add_o = 10'b0;
output [63:0] max_value_o;
output [9:0] max_value_address_o;


localparam s0 = 2'b00, FIND_MAX = 2'b01, WAIT = 2'b10;


reg [9:0] read_vga_buff_add_reg = 10'b0;
reg searching_max_reg = 1'b0;
reg max_found_reg = 1'b0;

reg [63:0] max_value_next = 64'b0;
reg [9:0] max_value_address_next = 10'b0;
reg [63:0] max_value = 64'b0;
reg [9:0] max_value_address = 10'b0;
reg j = 1'b0;
reg jnext = 1'b0;
reg [1:0] sreg = s0;
reg [1:0] snext = s0;
//registri di pipeline di searching_max
reg searching_max_p1 = 1'b0;
//reg searching_max_p2 = 1'b0;


wire [9:0] pipe_read_vga_buff_add_w;

assign max_value_o = max_found_o ? max_value : 64'b0;
assign max_value_address_o = max_found_o ? max_value_address : 10'b0;
	
	
//aggiornamento uscite e stato
always @ (posedge clk)
begin
	//registri interni
	j <= jnext;
	sreg <= snext;
	max_value <= max_value_next;
	max_value_address <= max_value_address_next;
	//uscite
	read_vga_buff_add_o <= read_vga_buff_add_reg;
	searching_max_o <= searching_max_reg;
	max_found_o <= max_found_reg;
	//pipeline di searching_max
	searching_max_p1 <= searching_max_o;
	//searching_max_p2 <= searching_max_p1;
end

always @ (sreg or vga_start_i or j or read_vga_buff_add_o or searching_max_o)
begin

	max_found_reg = 1'b0;
	
	case(sreg)
		s0 : begin
			read_vga_buff_add_reg = 10'b0;
			searching_max_reg = 1'b0;
			jnext = 1'b0;
			if(vga_start_i) snext = FIND_MAX;
			else snext = s0;
		end
		
		FIND_MAX : begin
			jnext = 1'b0;
			searching_max_reg = 1'b1;
			read_vga_buff_add_reg = read_vga_buff_add_o + 1'b1;
			if(read_vga_buff_add_o == 10'd512) snext = WAIT; //oltre la metà è speculare, quindi non serve cercare oltre
			else snext = FIND_MAX;
		end
		
		WAIT : begin
			jnext = j + 1'b1;
			read_vga_buff_add_reg = 10'b0;
			searching_max_reg = 1'b0; //tanto c'è la pipeline
			if(j) 
			begin
				snext = s0;
				max_found_reg = 1'b1;
			end
			else snext = WAIT;
		end
		
		default : begin
			read_vga_buff_add_reg = 10'b0;
			searching_max_reg = 1'b0;
			jnext = 1'b0;
			snext = s0;
		end
	endcase
end

//RC che cerca il max e il suo indirizzo
always @ (searching_max_p1 or vga_buffer_data_i or pipe_read_vga_buff_add_w or max_value or max_value_address)
begin
	if(searching_max_p1)
	begin
		if(vga_buffer_data_i > max_value)
		begin
			max_value_next = vga_buffer_data_i;
			max_value_address_next = pipe_read_vga_buff_add_w;
		end
		else
		begin
			max_value_next = max_value;
			max_value_address_next = max_value_address;
		end
	end
	else 
	begin
		max_value_address_next = 10'b0;
		max_value_next = 64'b0;
	end
end


pipe2 pipe_read_vga_buff_add (
	.in(read_vga_buff_add_o), 
	.out(pipe_read_vga_buff_add_w), 
	.ck(clk)
);

endmodule


	
