module seven_segment(
	input wire[3:0]i,
	output reg[6:0]o
);

// HEX out - rewire DE1
//  ---0---
// |       |
// 5       1
// |       |
//  ---6---
// |       |
// 4       2
// |       |
//  ---3---

always @(*) begin
    case (i)
        4'b0000: o = 7'b1000000;  
        4'b0001: o = 7'b1111001;  
        4'b0010: o = 7'b0100100;  
        4'b0011: o = 7'b0110000;  
        4'b0100: o = 7'b0011001;  
        4'b0101: o = 7'b0010010;  
        4'b0110: o = 7'b0000010;  
        4'b0111: o = 7'b1111000;  
        4'b1000: o = 7'b0000000;  
        4'b1001: o = 7'b0010000;  
        default: o = 7'b1111111;  
    endcase
end



endmodule