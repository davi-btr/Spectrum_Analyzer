module vga_time_generator(

input       pixel_clk,
input			draw_i,

input [11:0]h_disp,
input [11:0]h_fporch,
input [11:0]h_sync,   
input [11:0]h_bporch,

input [11:0]v_disp,
input [11:0]v_fporch,
input [11:0]v_sync,   
input [11:0]v_bporch,

output     vga_hs,
output     vga_vs,
output     vga_blank,
output  reg[15:0]CounterY,
output  reg[15:0]CounterX

);

///////h sync////////
//h total sum//
wire [11:0]h_total;
assign h_total = h_disp+h_fporch+h_sync+h_bporch;	
//h counter gen //
reg [11:0]h_counter;
reg VGA_HS_o;
reg VGA_BLANK_HS_o;

always @(posedge pixel_clk)begin
	if (draw_i && (h_counter  < (h_total-11'd1)) ) h_counter <= h_counter+11'd1;
	else h_counter <= 0;
end

// h timing generator 
always @(posedge pixel_clk)begin
	if (h_counter < h_fporch) {VGA_BLANK_HS_o,VGA_HS_o}=2'b01;
	else if (h_counter < h_fporch+h_sync) {VGA_BLANK_HS_o,VGA_HS_o}=2'b00;
	else if (h_counter < h_fporch+h_sync+h_bporch) {VGA_BLANK_HS_o,VGA_HS_o}=2'b01;
	else {VGA_BLANK_HS_o,VGA_HS_o}=2'b11;
	/*if (!draw_i) begin	// blank, no synch
		VGA_BLANK_HS_o <= 0;
		VGA_HS_o <= 1;
	end else begin*/
		/*case(h_counter)
										0:{VGA_BLANK_HS_o,VGA_HS_o}=2'b01; //front hs = 1
							  h_fporch:{VGA_BLANK_HS_o,VGA_HS_o}=2'b00;	// hs = 0 
					 h_fporch+h_sync:{VGA_BLANK_HS_o,VGA_HS_o}=2'b01;	// hs torna 1
		 h_fporch+h_sync+h_bporch:{VGA_BLANK_HS_o,VGA_HS_o}=2'b11;	// display window: no synch no blank
		endcase*/
	/*end*/
end

/////v sync///// 
//v total sum//
wire [11:0]v_total;
assign v_total = v_disp+v_fporch+v_sync+v_bporch;
//v counter gen
reg [11:0]v_counter;
reg VGA_VS_o;
reg VGA_BLANK_VS_o;

always @(posedge vga_hs)begin
	if (draw_i && (v_counter < (v_total-11'd1)) ) v_counter <= v_counter+11'd1;//805
	else v_counter <= 0;
end
//v timing generator// 
always @(posedge vga_hs)begin
	/*if (!draw_i) begin	// blank, no synch
		VGA_BLANK_VS_o <= 0;
		VGA_VS_o <= 1;
	end else begin*/
	  if (v_counter < v_fporch) {VGA_BLANK_VS_o,VGA_VS_o}=2'b01;
	  else if (v_counter < v_fporch+v_sync) {VGA_BLANK_VS_o,VGA_VS_o}=2'b00;
	  else if (v_counter < v_fporch+v_sync+v_bporch) {VGA_BLANK_VS_o,VGA_VS_o}=2'b01;
	  else {VGA_BLANK_VS_o,VGA_VS_o}=2'b11;
		  /*	case(v_counter)
									0:{VGA_BLANK_VS_o,VGA_VS_o}=2'b01;
						  v_fporch:{VGA_BLANK_VS_o,VGA_VS_o}=2'b00;
				 v_fporch+v_sync:{VGA_BLANK_VS_o,VGA_VS_o}=2'b01;
	 v_fporch+v_sync+v_bporch:{VGA_BLANK_VS_o,VGA_VS_o}=2'b11;
	endcase*/
	/*end*/
end

//sync timing output//
assign vga_hs=VGA_HS_o;
assign vga_vs=VGA_VS_o;
assign vga_blank=VGA_BLANK_VS_o & VGA_BLANK_HS_o;

always @(posedge pixel_clk)begin
if(!VGA_BLANK_HS_o)CounterX <= 0;
else CounterX <= CounterX+15'd1;
end

always @(posedge vga_hs)begin
if(!VGA_BLANK_VS_o)CounterY <= 0;
else CounterY <= CounterY+15'd1;
end



endmodule
