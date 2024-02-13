module pipe3 (
	in, 
	out2, 
	out3, 
	ck
);

input ck;
input [9:0] in;
output reg [9:0] out2 = 10'b0;
output reg [9:0] out3 = 10'b0;

reg [9:0] q1 = 10'b0;

always @ (posedge ck)
begin
	q1 <= in;
	out2 <= q1;
	out3 <= out2;
end

endmodule
