module vga_block (
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
	vga_start_i,
	//output
	max_value_address_o, //mi serve davvero?
	adapt_buff_q1_o,
	adapt_buff_q2_o,
	adaptation_done_o
);

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

output [9:0] max_value_address_o;
output [15:0] adapt_buff_q1_o;
output [15:0] adapt_buff_q2_o;
output reg adaptation_done_o;

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


reg [15:0] adapt_buff_data1_reg;
reg [15:0] adapt_buff_data2_reg;
//reg adaptation_done_reg;



assign vga_buffer_address1_w = searching_max_w ? read_vga_buffer_address_w : write_vga_buffer_address1_i;
assign vga_buffer_address2_w = searching_max_w ? read_vga_buffer_address_w : write_vga_buffer_address2_i;
assign vga_buffer_address1_def_w = adapter_wen_w ? adapter_read_buffer_addr1_w : vga_buffer_address1_w;
assign vga_buffer_address2_def_w = adapter_wen_w ? adapter_read_buffer_addr2_w : vga_buffer_address2_w;
//assign adapt_buff_data1_w = {6'd0, vga_buff_q1_w[MSB_w:MSB_w-9]};
//assign adapt_buff_data2_w = {6'd0, vga_buff_q2_w[MSB_w:MSB_w-9]};
assign adapt_buff_q1_o = adapt_buff_q1_w;
assign adapt_buff_q2_o = adapt_buff_q2_w;

always @ (posedge clk)
begin
	//adaptation_done_reg <= adaptation_done_w;
	adaptation_done_o <= adaptation_done_w;
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

//ADATTATA FFT1024
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


//ADATTATA FFT1024
max_finder find_max (
	//input
	.clk(clk),
	.vga_start_i(vga_start_i),
	.vga_buffer_data_i(vga_buff_q1_w),
	//output
	.read_vga_buff_add_o(read_vga_buffer_address_w),
	.searching_max_o(searching_max_w),
	.max_found_o(max_found_w),
	.max_value_o(max_value_w),
	.max_value_address_o(max_value_address_o)
);

//ADATTATA FFT1024
vga_adapter adapt_word_width (
	//input
	.clk(clk),
	.adaptation_start_i(max_found_w),
	.max_value_i(max_value_w),
	//output
	.read_in_buffer_addr1_o(adapter_read_buffer_addr1_w),
	.read_in_buffer_addr2_o(adapter_read_buffer_addr2_w),
	.wen_o(adapter_wen_w),
	.MSB_o(MSB_w),
	.adaptation_done_o(adaptation_done_w)
);

//ADATTATA FFT1024
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

//ADATTATA FFT1024
ram2port_adapted adapted_out_buffer (
	.address_a(pipe_adapter_write_address1_w),
	.address_b(pipe_adapter_write_address2_w),
	.clock(clk),
	.data_a(adapt_buff_data1_reg),
	.data_b(adapt_buff_data2_reg),
	.wren_a(adapter_wen_w),
	.wren_b(adapter_wen_w),
	.q_a(adapt_buff_q1_w),
	.q_b(adapt_buff_q2_w)
);


always @ (MSB_w or vga_buff_q1_w or vga_buff_q2_w)
begin
	case(MSB_w) 
	
		6'd63 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[63:54]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[63:54]};
       end

      6'd62 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[62:53]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[62:53]};
       end

      6'd61 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[61:52]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[61:52]};
       end

      6'd60 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[60:51]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[60:51]};
       end

      6'd59 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[59:50]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[59:50]};
       end

      6'd58 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[58:49]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[58:49]};
       end

      6'd57 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[57:48]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[57:48]};
       end

      6'd56 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[56:47]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[56:47]};
       end

      6'd55 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[55:46]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[55:46]};
       end

      6'd54 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[54:45]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[54:45]};
       end

      6'd53 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[53:44]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[53:44]};
       end

      6'd52 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[52:43]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[52:43]};
       end

      6'd51 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[51:42]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[51:42]};
       end

      6'd50 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[50:41]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[50:41]};
       end

      6'd49 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[49:40]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[49:40]};
       end

      6'd48 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[48:39]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[48:39]};
       end

      6'd47 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[47:38]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[47:38]};
       end

      6'd46 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[46:37]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[46:37]};
       end

      6'd45 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[45:36]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[45:36]};
       end

      6'd44 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[44:35]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[44:35]};
       end

      6'd43 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[43:34]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[43:34]};
       end

      6'd42 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[42:33]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[42:33]};
       end

      6'd41 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[41:32]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[41:32]};
       end

      6'd40 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[40:31]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[40:31]};
       end

      6'd39 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[39:30]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[39:30]};
       end

      6'd38 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[38:29]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[38:29]};
       end

      6'd37 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[37:28]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[37:28]};
       end

      6'd36 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[36:27]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[36:27]};
       end

      6'd35 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[35:26]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[35:26]};
       end

      6'd34 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[34:25]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[34:25]};
       end

      6'd33 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[33:24]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[33:24]};
       end

      6'd32 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[32:23]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[32:23]};
       end

      6'd31 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[31:22]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[31:22]};
       end

      6'd30 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[30:21]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[30:21]};
       end

      6'd29 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[29:20]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[29:20]};
       end

      6'd28 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[28:19]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[28:19]};
       end

      6'd27 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[27:18]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[27:18]};
       end

      6'd26 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[26:17]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[26:17]};
       end

      6'd25 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[25:16]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[25:16]};
       end

      6'd24 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[24:15]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[24:15]};
       end

      6'd23 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[23:14]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[23:14]};
       end

      6'd22 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[22:13]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[22:13]};
       end

      6'd21 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[21:12]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[21:12]};
       end

      6'd20 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[20:11]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[20:11]};
       end

      6'd19 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[19:10]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[19:10]};
       end

      6'd18 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[18:9]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[18:9]};
       end

      6'd17 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[17:8]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[17:8]};
       end

      6'd16 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[16:7]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[16:7]};
       end

      6'd15 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[15:6]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[15:6]};
       end

      6'd14 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[14:5]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[14:5]};
       end

      6'd13 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[13:4]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[13:4]};
       end

      6'd12 : begin
          adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[12:3]};
          adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[12:3]};
       end

		
		6'd11 : begin
			adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[11:2]};
			adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[11:2]};
		end
		
		6'd10 : begin
			adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[10:1]};
			adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[10:1]};
		end
		
		6'd9 : begin
			adapt_buff_data1_reg = {6'b0, vga_buff_q1_w[9:0]};
			adapt_buff_data2_reg = {6'b0, vga_buff_q2_w[9:0]};
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
