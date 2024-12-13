module three_decimal_vals_w_neg (
input [14:0]val,
output [6:0]seg7_neg_sign,
output [6:0]seg7_dig0,
output [6:0]seg7_dig1,
output [6:0]seg7_dig2,
output [6:0]seg7_dig3,
output [6:0]seg7_dig4
);

reg [3:0] result_one_digit;
reg [3:0] result_ten_digit;
reg [3:0] result_hundred_digit;
reg [3:0] num4;
reg [3:0] num5;
reg result_is_negative;

reg [14:0]twos_comp;

always @(*) begin
   
    if (val[14] == 1'b1) begin
        result_is_negative = 1'b0;
        twos_comp = val;                
    end else begin
		  result_is_negative = 1'b0;
        twos_comp = val;                
    end

    num5 = (twos_comp / 10000) % 10;
	 num4 = (twos_comp / 1000) % 10;
	 result_hundred_digit = (twos_comp / 100) % 10;
    result_ten_digit = (twos_comp / 10) % 10;  
    result_one_digit = twos_comp % 10;         
end

seven_segment dig0 (
    .i(result_one_digit),
    .o(seg7_dig0)
);

seven_segment dig1 (
    .i(result_ten_digit),
    .o(seg7_dig1)
);

seven_segment dig2 (
    .i(result_hundred_digit),
    .o(seg7_dig2)
);
seven_segment dig3 (
    .i(num4),
    .o(seg7_dig3)
);
seven_segment dig4 (
    .i(num5),
    .o(seg7_dig4)
);

seven_segment_negative neg_sign (
    .i(result_is_negative),
    .o(seg7_neg_sign)
);


endmodule