module pipe2 (
	in, 
	out, 
	ck
);

input ck;
input [9:0] in;
output reg [9:0] out;

reg [9:0] q1 = 10'b0;

always @ (posedge ck)
begin
	q1 <= in;
	out <= q1;
end

endmodule
