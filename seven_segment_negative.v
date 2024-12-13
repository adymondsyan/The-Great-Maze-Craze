module seven_segment_negative(i,o);

input i;
output reg [6:0]o; // a, b, c, d, e, f, g

always @(*) begin
    case (i)
	 1'b0: o = 7'b1111111;
	 1'b1: o = 7'b0111111;
	 default: o = 7'b1111111;
	 endcase
	 
end



endmodule