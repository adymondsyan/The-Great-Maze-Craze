module vga_driver_to_frame_buf	(
    	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	//input 		          		AUD_ADCDAT,
	//inout 		          		AUD_ADCLRCK,
	//inout 		          		AUD_BCLK,
	//output		          		AUD_DACDAT,
	//inout 		          		AUD_DACLRCK,
	//output		          		AUD_XCK,

	//////////// CLOCK //////////
	//input 		          		CLOCK2_50,
	//input 		          		CLOCK3_50,
	//input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SDRAM //////////
	//output		    [12:0]		DRAM_ADDR,
	//output		     [1:0]		DRAM_BA,
	//output		          		DRAM_CAS_N,
	//output		          		DRAM_CKE,
	//output		          		DRAM_CLK,
	//output		          		DRAM_CS_N,
	//inout 		    [15:0]		DRAM_DQ,
	//output		          		DRAM_LDQM,
	//output		          		DRAM_RAS_N,
	//output		          		DRAM_UDQM,
	//output		          		DRAM_WE_N,

	//////////// I2C for Audio and Video-In //////////
	//output		          		FPGA_I2C_SCLK,
	//inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output 		     [6:0]		HEX3,
	output 		     [6:0]		HEX4,
	output 		     [6:0]		HEX5,

	//////////// IR //////////
	//input 		          		IRDA_RXD,
	//output		          		IRDA_TXD,

	//////////// KEY //////////
	input 		     [8:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// PS2 //////////
	//inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	//inout 		          		PS2_DAT,
	//inout 		          		PS2_DAT2,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// Video-In //////////
	//input 		          		TD_CLK27,
	//input 		     [7:0]		TD_DATA,
	//input 		          		TD_HS,
	//output		          		TD_RESET_N,
	//input 		          		TD_VS,

	//////////// VGA //////////
	output		          		VGA_BLANK_N,
	output		     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_1

);


three_decimal_vals_w_neg player_output(
.val(player_location),
.seg7_neg_sign(HEX5),
.seg7_dig0(HEX0),
.seg7_dig1(HEX1),
.seg7_dig2(HEX2),
.seg7_dig3(HEX3),
.seg7_dig4(HEX4)
);

// Turn off all displays.



// DONE STANDARD PORT DECLARATION ABOVE
/* HANDLE SIGNALS FOR CIRCUIT */
wire clk;
wire rst;

assign clk = CLOCK_50;
assign rst = SW[5];

wire [9:0]SW_db;

reg [25:0]time_Count;

debounce_switches db(
.clk(clk),
.rst(rst),
.SW(SW), 
.SW_db(SW_db)
);

// VGA DRIVER
wire active_pixels; // is on when we're in the active draw space
wire frame_done;
wire [9:0]x; // current x
wire [9:0]y; // current y - 10 bits = 1024 ... a little bit more than we need

/* the 3 signals to set to write to the picture */
reg [14:0] the_vga_draw_frame_write_mem_address;
reg [23:0] the_vga_draw_frame_write_mem_data;
reg the_vga_draw_frame_write_a_pixel;

/* This is the frame driver point that you can write to the draw_frame */
vga_frame_driver my_frame_driver(
	.clk(clk),
	.rst(rst),

	.active_pixels(active_pixels),
	.frame_done(frame_done),

	.x(x),
	.y(y),

	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_CLK(VGA_CLK),
	.VGA_HS(VGA_HS),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_VS(VGA_VS),
	.VGA_B(VGA_B),
	.VGA_G(VGA_G),
	.VGA_R(VGA_R),

	/* writes to the frame buf - you need to figure out how x and y or other details provide a translation */
	.the_vga_draw_frame_write_mem_address(the_vga_draw_frame_write_mem_address),
	.the_vga_draw_frame_write_mem_data(the_vga_draw_frame_write_mem_data),
	.the_vga_draw_frame_write_a_pixel(the_vga_draw_frame_write_a_pixel)
);

reg [15:0]i;
reg [7:0]S;
reg [7:0]NS;

reg [7:0] x_player;
reg [7:0] y_player;
reg is_wall;

parameter MEMORY_SIZE = 16'd19200; // 160*120 // Number of memory spots ... highly reduced since memory is slow
parameter PIXEL_VIRTUAL_SIZE = 16'd4; // Pixels per spot - therefore 4x4 pixels are drawn per memory location

/* ACTUAL VGA RESOLUTION */
parameter VGA_WIDTH = 16'd640; 
parameter VGA_HEIGHT = 16'd480;

/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide */
parameter VIRTUAL_PIXEL_WIDTH = VGA_WIDTH/PIXEL_VIRTUAL_SIZE; // 160
parameter VIRTUAL_PIXEL_HEIGHT = VGA_HEIGHT/PIXEL_VIRTUAL_SIZE; // 120

/* idx_location stores all the locations in the */
reg [14:0] player_location;
reg[14:0] next_step_up;
reg[14:0] next_step_down;
reg[14:0] next_step_left;
reg[14:0] next_step_right;

parameter 	START = 8'd0, 
				MOVE_LEFT = 8'd1, 
				MOVE_RIGHT = 8'd2,
				MOVE_UP = 8'd3,
				MOVE_DOWN = 8'd4,
				UP_CHAR = 8'd5,
				DOWN_CHAR = 8'd6,
				LEFT_CHAR = 8'd7,
				RIGHT_CHAR = 8'd8,
				IS_WALL_DOWN = 8'd9,
				WAIT_INPUT = 8'd10,
				WAIT_MEM0 = 8'd11,
				INIT_PLAYER = 8'd12,
				INIT_GOAL = 8'd13,
				WAIT_MEM1 = 8'd14,
				UPDATE_TRAIL_UP = 8'd15,
				UPDATE_TRAIL_DOWN = 8'd16,
				UPDATE_TRAIL_LEFT = 8'd17,
				UPDATE_TRAIL_RIGHT = 8'd18,
				WAIT_MEM2 = 8'd19,
				DONE_MEM2 = 8'd20,
				DONE_MEM1 = 8'd21,
				WAIT_MEM3 = 8'd22,
				DONE_MEM3 = 8'd23,
				WAIT_MEM4 = 8'd24,
				DONE_MEM4 = 8'd25,
				WAIT_MEM5 = 8'd26,
				DONE_MEM5 = 8'd27,
				TIME_WAIT = 8'd28,
				ERROR = 8'b11111111;

// Just so I can see the address being calculated
assign LEDR = S;

//State Switcher
always @(posedge clk or negedge rst) begin

	if(rst == 1'b0) begin
		S <= START;
		
		end
	else
		S <= NS;

end

/*
the_vga_draw_frame_write_mem_address <= idx_location; location number
the_vga_draw_frame_write_mem_data <= {SW[7:0], SW[7:0], SW[7:0]}; RGB
the_vga_draw_frame_write_a_pixel <= 1'b1; Enabler
*/

always @(*) begin	
	case(S)
		START: NS = INIT_PLAYER;
		INIT_PLAYER: NS = WAIT_MEM0;
		WAIT_MEM0: NS = INIT_GOAL;
		INIT_GOAL: NS = WAIT_MEM1;
		WAIT_MEM1: NS = DONE_MEM1;
		DONE_MEM1: NS = TIME_WAIT;
		
		TIME_WAIT: if (time_Count >= 25'd5000000) begin
							NS = WAIT_INPUT;
						end
						else begin
							NS = TIME_WAIT;
						end
		
		WAIT_INPUT: begin
			if (KEY[0] == 1'b0) begin
				// Handle key press for down movement
				NS = DOWN_CHAR; 
			end
			else if (KEY[1] == 1'b0) begin
				// Handle key press for up movement
				NS = UP_CHAR; 
			end
			else if (KEY[2] == 1'b0) begin
				// Handle key press for right movement
				NS = RIGHT_CHAR; 
			end
			else if (KEY[3] == 1'b0) begin
				// Handle key press for left movement
				NS = LEFT_CHAR; 
			end 
			else if (player_location == 15'd14395) begin
			
				NS = START;
			end
			else begin
				// If no key is pressed, stay in WAIT_INPUT
				NS = WAIT_INPUT;
			end
		end
		
		// Handle player movement up
		UP_CHAR: NS = MOVE_UP;
		MOVE_UP: NS = WAIT_MEM2;
		WAIT_MEM2: NS = DONE_MEM2;
		DONE_MEM2: NS = UPDATE_TRAIL_UP;
		UPDATE_TRAIL_UP: NS = WAIT_MEM1;

		DOWN_CHAR: NS = MOVE_DOWN;
		MOVE_DOWN: NS = WAIT_MEM3;
		WAIT_MEM3: NS = DONE_MEM3;
		DONE_MEM3: NS = UPDATE_TRAIL_DOWN;
		UPDATE_TRAIL_DOWN: NS = WAIT_MEM1;
		
		LEFT_CHAR: NS = MOVE_LEFT;
		MOVE_LEFT: NS = WAIT_MEM4;
		WAIT_MEM4: NS = DONE_MEM4;
		DONE_MEM4: NS = UPDATE_TRAIL_LEFT;
		UPDATE_TRAIL_LEFT: NS = WAIT_MEM1;
		
		RIGHT_CHAR: NS = MOVE_RIGHT;
		MOVE_RIGHT: NS = WAIT_MEM5;
		WAIT_MEM5: NS = DONE_MEM5;
		DONE_MEM5: NS = UPDATE_TRAIL_RIGHT;
		UPDATE_TRAIL_RIGHT: NS = WAIT_MEM1;
		
		default: NS = ERROR;
	endcase
end


always @(posedge clk or negedge rst) begin	
	if(rst == 1'b0) begin
		time_Count <= 25'd0;
		the_vga_draw_frame_write_mem_address <= 15'd0;
		the_vga_draw_frame_write_mem_data <= 24'd0;
		the_vga_draw_frame_write_a_pixel <= 1'b0;
		player_location <= 15'd7260;  // Initialize player location
	end else begin
		case(S)
			START: begin
				time_Count <= 25'd0;
				the_vga_draw_frame_write_mem_address <= 15'd0;
				the_vga_draw_frame_write_mem_data <= 24'd0;
				the_vga_draw_frame_write_a_pixel <= 1'b0;
				player_location <= 15'd7260;
			end
			INIT_PLAYER: begin
				// Initialize player location on the screen
				the_vga_draw_frame_write_mem_address <= player_location;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd0, 8'd0};  // Red color
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			WAIT_MEM0: begin
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
			INIT_GOAL: begin
				// Initialize goal on the screen
				the_vga_draw_frame_write_mem_address <= 15'd14395;  // Goal location
				the_vga_draw_frame_write_mem_data <= {8'd0, 8'd255, 8'd0};  // Green color
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			WAIT_MEM1: begin
				// Handle memory writes during this state (if needed)
				
			end
			DONE_MEM1: begin
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
			TIME_WAIT: begin
				time_Count <= time_Count + 1'b1;
			end
			WAIT_INPUT: begin
				is_wall <= 1'b0;
				time_Count <= 25'd0;
			end
			UP_CHAR: begin
				// Update player location (move up)
				player_location <= player_location - 1'b1;
			end
			DOWN_CHAR: begin
				// Update player location (move up)
				player_location <= player_location + 1'b1;
			end
			LEFT_CHAR: begin
				// Update player location (move up)
				player_location <= player_location - 25'd120;
			end
			RIGHT_CHAR: begin
				// Update player location (move up)
				player_location <= player_location + 25'd120;
			end
			MOVE_UP: begin
				// Draw player at the new location
				the_vga_draw_frame_write_mem_address <= player_location;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd0, 8'd0};  // Red color
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			MOVE_DOWN: begin
				// Draw player at the new location
				the_vga_draw_frame_write_mem_address <= player_location;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd0, 8'd0};  // Red color
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			MOVE_LEFT: begin
				// Draw player at the new location
				the_vga_draw_frame_write_mem_address <= player_location;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd0, 8'd0};  // Red color
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			MOVE_RIGHT: begin
				// Draw player at the new location
				the_vga_draw_frame_write_mem_address <= player_location;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd0, 8'd0};  // Red color
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			WAIT_MEM2: begin
				// Handle memory writes during this state (if needed)
			end
			WAIT_MEM3: begin
				// Handle memory writes during this state (if needed)
			end
			WAIT_MEM4: begin
				// Handle memory writes during this state (if needed)
			end
			WAIT_MEM5: begin
				// Handle memory writes during this state (if needed)
			end
			DONE_MEM3: begin
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
			DONE_MEM4: begin
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
			DONE_MEM5: begin
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
			UPDATE_TRAIL_UP: begin
				// Update trail (e.g., erase previous location or mark the trail)
				the_vga_draw_frame_write_mem_address <= player_location + 1'b1;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd255, 8'd255};  // WHITE color for trail
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			UPDATE_TRAIL_DOWN: begin
				// Update trail (e.g., erase previous location or mark the trail)
				the_vga_draw_frame_write_mem_address <= player_location - 1'b1;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd255, 8'd255};  // WHITE color for trail
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			UPDATE_TRAIL_LEFT: begin
				// Update trail (e.g., erase previous location or mark the trail)
				the_vga_draw_frame_write_mem_address <= player_location + 25'd120;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd255, 8'd255};  // WHITE color for trail
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			UPDATE_TRAIL_RIGHT: begin
				// Update trail (e.g., erase previous location or mark the trail)
				the_vga_draw_frame_write_mem_address <= player_location - 25'd120;
				the_vga_draw_frame_write_mem_data <= {8'd255, 8'd255, 8'd255};  // WHITE color for trail
				the_vga_draw_frame_write_a_pixel <= 1'b1;
			end
			default: begin
				the_vga_draw_frame_write_a_pixel <= 1'b0;
			end
		endcase
	end
end


endmodule