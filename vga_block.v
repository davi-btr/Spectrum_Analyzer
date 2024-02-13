module vga_block (
	vga_clk,
	vga_blank,
	vga_sync,
	vga_h_sync,
	vga_v_sync,
	vga_R,
	vga_G,
	vga_B,
	//input
	clk,
	rst_n,
	fft_sample1_real_i,
	fft_sample1_img_i,
	fft_sample2_real_i,
	fft_sample2_img_i,
	write_vga_buffer_address1_i,
	write_vga_buffer_address2_i,
	fft_done_i,
	vga_start_i
);


output vga_clk;
output vga_blank;
output vga_sync;
output vga_h_sync;
output vga_v_sync;
output [9:0]vga_R;
output [9:0]vga_G;
output [9:0]vga_B;
input clk;
input rst_n;
input [31:0] fft_sample1_real_i;
input [31:0] fft_sample1_img_i;
input [31:0] fft_sample2_real_i;
input [31:0] fft_sample2_img_i;
input [9:0] write_vga_buffer_address1_i;
input [9:0] write_vga_buffer_address2_i;
input fft_done_i;
input vga_start_i;


wire [63:0] fft_sample1_magn_w;
wire [63:0] fft_sample2_magn_w;
wire [63:0] vga_buff_q1_w;
wire [63:0] vga_buff_q2_w;
wire searching_max_w;
wire [9:0] vga_buffer_address1_w;
wire [9:0] vga_buffer_address2_w;
wire [9:0] vga_buffer_address1_def_w;
wire [9:0] vga_buffer_address2_def_w;
wire [9:0] read_vga_buffer_address_w;
wire max_found_w;
wire [63:0] max_value_w;
wire [9:0] adapter_read_buffer_addr1_w;
wire [9:0] adapter_read_buffer_addr2_w;
wire adapter_wen_w;
wire [9:0] pipe_adapter_write_address1_w;
wire [9:0] pipe_adapter_write_address2_w;
wire [15:0] adapt_buff_q1_w;
wire [15:0] adapt_buff_q2_w;
wire [5:0] MSB_w;
wire adaptation_done_w;
wire vga_reading_w;
wire [9:0]vga_radd_a_w;
wire [9:0]vga_radd_b_w;
wire [9:0]adapted_add_a_w;
wire [9:0]adapted_add_b_w;
wire vga_R_w;
wire vga_G_w;
wire vga_B_w;


reg [15:0] adapt_buff_data1_reg;
reg [15:0] adapt_buff_data2_reg;
reg adaptation_done_reg;


assign vga_buffer_address1_w = searching_max_w ? read_vga_buffer_address_w : write_vga_buffer_address1_i;
assign vga_buffer_address2_w = searching_max_w ? read_vga_buffer_address_w : write_vga_buffer_address2_i;
assign vga_buffer_address1_def_w = adapter_wen_w ? adapter_read_buffer_addr1_w : vga_buffer_address1_w;
assign vga_buffer_address2_def_w = adapter_wen_w ? adapter_read_buffer_addr2_w : vga_buffer_address2_w;
assign adapted_add_a_w = (vga_reading_w) ? vga_radd_a_w : pipe_adapter_write_address1_w; 
assign adapted_add_b_w = (vga_reading_w) ? vga_radd_b_w : pipe_adapter_write_address2_w; 
assign vga_clk = clk;
assign vga_R = {10{vga_R_w}};
assign vga_G = {10{vga_G_w}};
assign vga_B = {10{vga_B_w}};

always @ (posedge clk) 
begin
	adaptation_done_reg <= adaptation_done_w;
end

magn_calc sample1_magn (
	.sample_real(fft_sample1_real_i),
	.sample_img(fft_sample1_img_i),
	.sample_magn(fft_sample1_magn_w)
);

magn_calc sample2_magn (
	.sample_real(fft_sample2_real_i),
	.sample_img(fft_sample2_img_i),
	.sample_magn(fft_sample2_magn_w)
);

ram2port64 vga_input_buffer(
	.address_a(vga_buffer_address1_def_w),
	.address_b(vga_buffer_address2_def_w),
	.clock(clk),
	.data_a(fft_sample1_magn_w),
	.data_b(fft_sample2_magn_w),
	.wren_a(fft_done_i),
	.wren_b(fft_done_i),
	.q_a(vga_buff_q1_w),
	.q_b(vga_buff_q2_w)
);

max_finder find_max (
	//input
	.clk(clk),
	.vga_start_i(vga_start_i),
	.vga_buffer_data_i(vga_buff_q1_w),
	.rst_n(rst_n),
	//output
	.read_vga_buff_add_o(read_vga_buffer_address_w),
	.searching_max_o(searching_max_w),
	.max_found_o(max_found_w),
	.max_value_o(max_value_w)
);

vga_adapter adapt_word_width (
	//input
	.clk(clk),
	.rst_n(rst_n),
	.adaptation_start_i(max_found_w),
	.max_value_i(max_value_w),
	//output
	.read_in_buffer_addr1_o(adapter_read_buffer_addr1_w),
	.read_in_buffer_addr2_o(adapter_read_buffer_addr2_w),
	.wen_o(adapter_wen_w),
	.MSB_o(MSB_w),
	.adaptation_done_o(adaptation_done_w)
);

pipe2 pipe_write_address1 (
	.ck(clk),
	.in(adapter_read_buffer_addr1_w),
	.out(pipe_adapter_write_address1_w)
);

pipe2 pipe_write_address2 (
	.ck(clk),
	.in(adapter_read_buffer_addr2_w),
	.out(pipe_adapter_write_address2_w)
);

ram2port_adapted adapted_out_buffer (
	.address_a(adapted_add_a_w),
	.address_b(adapted_add_b_w),
	.clock(clk),
	.data_a(adapt_buff_data1_reg),
	.data_b(adapt_buff_data2_reg),
	.wren_a(adapter_wen_w),
	.wren_b(adapter_wen_w),
	.q_a(adapt_buff_q1_w),
	.q_b(adapt_buff_q2_w)
);

vga_controller vga_display(
	.clk(clk),	
	.rst_n(rst_n),
	.display_start_i(adaptation_done_reg),
	.vga_buff_rdata_a_i(adapt_buff_q1_w),	//16 bit ogni campione
	.vga_buff_rdata_b_i(adapt_buff_q2_w),	//16 bit ogni campione
	.vga_buff_reading_o(vga_reading_w), // vga buffer in uso, si può mettere direttamente come buff read_en senza passare da altri reg
	.vga_buff_radd_a_o(vga_radd_a_w), // 
	.vga_buff_radd_b_o(vga_radd_b_w), //
	.vga_sync(vga_sync),	
	.vga_h_sync(vga_h_sync),
	.vga_v_sync(vga_v_sync),
	.inDisplayArea(vga_blank),	
	.vga_R(vga_R_w),
	.vga_G(vga_G_w), 
	.vga_B(vga_B_w)
);


always @ (MSB_w or vga_buff_q1_w or vga_buff_q2_w)
begin
	case(MSB_w) 
		 6'd63 : begin 
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[63:55]}; // i dati a 64 bit devono essere resi numeri a 9 bit (<= 511) prima di essere 
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[63:55]}; // mandati a schermo. I 7 bit iniziali tutti nulli servono per adattare
       end																	   // i numeri ai 16 bit di larghezza della RAM

      6'd62 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[62:54]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[62:54]};
       end

      6'd61 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[61:53]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[61:53]};
       end

      6'd60 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[60:52]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[60:52]};
       end

      6'd59 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[59:51]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[59:51]};
       end

      6'd58 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[58:50]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[58:50]};
       end

      6'd57 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[57:49]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[57:49]};
       end

      6'd56 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[56:48]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[56:48]};
       end

      6'd55 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[55:47]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[55:47]};
       end

      6'd54 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[54:46]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[54:46]};
       end

      6'd53 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[53:45]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[53:45]};
       end

      6'd52 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[52:44]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[52:44]};
       end

      6'd51 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[51:43]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[51:43]};
       end

      6'd50 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[50:42]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[50:42]};
       end

      6'd49 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[49:41]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[49:41]};
       end

      6'd48 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[48:40]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[48:40]};
       end

      6'd47 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[47:39]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[47:39]};
       end

      6'd46 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[46:38]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[46:38]};
       end

      6'd45 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[45:37]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[45:37]};
       end

      6'd44 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[44:36]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[44:36]};
       end

      6'd43 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[43:35]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[43:35]};
       end

      6'd42 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[42:34]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[42:34]};
       end

      6'd41 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[41:33]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[41:33]};
       end

      6'd40 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[40:32]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[40:32]};
       end

      6'd39 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[39:31]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[39:31]};
       end

      6'd38 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[38:30]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[38:30]};
       end

      6'd37 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[37:29]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[37:29]};
       end

      6'd36 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[36:28]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[36:28]};
       end

      6'd35 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[35:27]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[35:27]};
       end

      6'd34 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[34:26]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[34:26]};
       end

      6'd33 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[33:25]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[33:25]};
       end

      6'd32 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[32:24]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[32:24]};
       end

      6'd31 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[31:23]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[31:23]};
       end

      6'd30 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[30:22]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[30:22]};
       end

      6'd29 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[29:21]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[29:21]};
       end

      6'd28 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[28:20]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[28:20]};
       end

      6'd27 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[27:19]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[27:19]};
       end

      6'd26 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[26:18]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[26:18]};
       end

      6'd25 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[25:17]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[25:17]};
       end

      6'd24 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[24:16]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[24:16]};
       end

      6'd23 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[23:15]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[23:15]};
       end

      6'd22 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[22:14]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[22:14]};
       end

      6'd21 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[21:13]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[21:13]};
       end

      6'd20 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[20:12]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[20:12]};
       end

      6'd19 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[19:11]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[19:11]};
       end

      6'd18 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[18:10]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[18:10]};
       end

      6'd17 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[17:9]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[17:9]};
       end

      6'd16 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[16:8]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[16:8]};
       end

      6'd15 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[15:7]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[15:7]};
       end

      6'd14 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[14:6]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[14:6]};
       end

      6'd13 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[13:5]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[13:5]};
       end

      6'd12 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[12:4]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[12:4]};
       end

      6'd11 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[11:3]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[11:3]};
       end

      6'd10 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[10:2]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[10:2]};
       end

      6'd9 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[9:1]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[9:1]};
       end

      6'd8 : begin
          adapt_buff_data1_reg = {7'b0, vga_buff_q1_w[8:0]};
          adapt_buff_data2_reg = {7'b0, vga_buff_q2_w[8:0]};
       end
		
		
		6'd7 : begin
			adapt_buff_data1_reg = {8'b0, vga_buff_q1_w[7:0]};
			adapt_buff_data2_reg = {8'b0, vga_buff_q2_w[7:0]};
		end
		
		6'd6 : begin
			adapt_buff_data1_reg = {9'b0, vga_buff_q1_w[6:0]};
			adapt_buff_data2_reg = {9'b0, vga_buff_q2_w[6:0]};
		end
		
		6'd5 : begin
			adapt_buff_data1_reg = {10'b0, vga_buff_q1_w[5:0]};
			adapt_buff_data2_reg = {10'b0, vga_buff_q2_w[5:0]};
		end
		
		6'd4 : begin
			adapt_buff_data1_reg = {11'b0, vga_buff_q1_w[4:0]};
			adapt_buff_data2_reg = {11'b0, vga_buff_q2_w[4:0]};
		end
		
		6'd3 : begin
			adapt_buff_data1_reg = {12'b0, vga_buff_q1_w[3:0]};
			adapt_buff_data2_reg = {12'b0, vga_buff_q2_w[3:0]};
		end
		
		6'd2 : begin
			adapt_buff_data1_reg = {13'b0, vga_buff_q1_w[2:0]};
			adapt_buff_data2_reg = {13'b0, vga_buff_q2_w[2:0]};
		end
		
		6'd1 : begin
			adapt_buff_data1_reg = {14'b0, vga_buff_q1_w[1:0]};
			adapt_buff_data2_reg = {14'b0, vga_buff_q2_w[1:0]};
		end
		
		6'd0 : begin
			adapt_buff_data1_reg = {15'b0, vga_buff_q1_w[0]};
			adapt_buff_data2_reg = {15'b0, vga_buff_q2_w[0]};
		end
		
		default : begin
			adapt_buff_data1_reg = 16'b0;
			adapt_buff_data2_reg = 16'b0;
		end
	endcase
end

endmodule
