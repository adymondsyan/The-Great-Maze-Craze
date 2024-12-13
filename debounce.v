module debounce_switches(
input clk,
input rst,
input [17:0]SW, 
output [17:0]SW_db
);

debounce db0(clk, rst, SW[0], SW_db[0]);
debounce db1(clk, rst, SW[1], SW_db[1]);
debounce db2(clk, rst, SW[2], SW_db[2]);
debounce db3(clk, rst, SW[3], SW_db[3]);
debounce db4(clk, rst, SW[4], SW_db[4]);
debounce db5(clk, rst, SW[5], SW_db[5]);
debounce db6(clk, rst, SW[6], SW_db[6]);
debounce db7(clk, rst, SW[7], SW_db[7]);
debounce db10(clk, rst, SW[8], SW_db[8]);
debounce db11(clk, rst, SW[9], SW_db[9]);
debounce db12(clk, rst, SW[10], SW_db[10]);
debounce db13(clk, rst, SW[11], SW_db[11]);
debounce db14(clk, rst, SW[12], SW_db[12]);
debounce db15(clk, rst, SW[13], SW_db[13]);
debounce db16(clk, rst, SW[14], SW_db[14]);
debounce db17(clk, rst, SW[15], SW_db[15]);
debounce db18(clk, rst, SW[16], SW_db[16]);
debounce db19(clk, rst, SW[17], SW_db[17]);

endmodule

module debounce (
input clk,
input rst,
input SW, 
output reg SW_db
);

reg [7:0]count;
parameter CALMING_WINDOW = 8'd100;

reg [2:0]S;
reg [2:0]NS;
parameter
	START = 3'd0,
	ONE = 3'd1,
	MAYBE_ONE = 3'd2,
	ZERO = 3'd3,
	MAYBE_ZERO = 3'd4,
	ERROR = 3'b111;

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
		S <= START;
	else
		S <= NS;
end

always @(*)
begin
	case (S)
		START: NS = ZERO; // typically switches are off
		ONE: 
			if (SW == 1'b0)
				NS = MAYBE_ZERO;
			else
				NS = ONE;
		MAYBE_ONE:
			if (SW == 1'b1 && count > 8'd100)
				NS = ONE;
			else if (SW == 1'b1)
				NS = MAYBE_ONE;
			else
				NS = ZERO;
		ZERO:
			if (SW == 1'b1)
				NS = MAYBE_ONE;
			else
				NS = ZERO;
		MAYBE_ZERO:
			if (SW == 1'b0 && count > 8'd100)
				NS = ONE;
			else if (SW == 1'b0)
				NS = MAYBE_ZERO;
			else
				NS = ONE;
		default: NS = ERROR;
	endcase
end

	
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
		count <= 8'd0;
	else
		case (S)
			START:
			begin
				count <= 8'd0;
			end
			ONE: 
			begin
				count <= 8'd0;
				SW_db <= 1'b1;
			end
			MAYBE_ONE:
			begin
				count <= count + 1'b1;
				SW_db <= 1'b0;
			end
			ZERO:
			begin
				count <= 8'd0;				
				SW_db <= 1'b0;
			end
			MAYBE_ZERO:
			begin
				count <= count + 1'b1;
				SW_db <= 1'b1;
			end
		endcase
end

endmodule