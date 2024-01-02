module magn_calc (
	sample_real,
	sample_img,
	sample_magn
);

input [31:0] sample_real;
input [31:0] sample_img;
output [63:0] sample_magn;

wire [63:0] real_squared;
wire [63:0] img_squared;

assign sample_magn = real_squared + img_squared;

multiplyer real_part_squared (
	.dataa(sample_real),
	.datab(sample_real),
	.result(real_squared)
);

multiplyer img_part_squared (
	.dataa(sample_img),
	.datab(sample_img),
	.result(img_squared)
);

endmodule
