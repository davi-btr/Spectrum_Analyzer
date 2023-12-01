module addr_gen_unit(
    clk,
    rst_n,
    address_a_o,
    address_b_o,
	 memsel_o,
	 twiddle_addr
);

//Parameters


//Ports definition
input clk;
input rst_n;
output memsel_o;
output [8:0]twiddle_addr;
output [9:0]address_a_o;
output [9:0]address_b_o;

//Private wires

//Private regs

//Private assignments

//Main FSM
always @(posedge clk) begin
	if(!rst_n) begin
			fsm_state <= 0;
   end else //case(fsm_state)
			fsm_state <= 1;
end

endmodule
