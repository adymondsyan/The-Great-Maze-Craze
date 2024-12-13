/////////////////////////////////////////////////////////////////////////////////////
// Adaption by Peter Jamieson for DE2-115 from:
// 640x480 from https://projectf.io/posts/fpga-graphics/ 
// and ideas from Alejandro and Wills project: https://github.com/alecamaracm/Verilog-Game-Engine-with-PowerPoint-designer/wiki
//
// This module handles all the VGA signals for 640x480 with the exception of the R, G, B0
// The other modules use x, y, active_pixels, and frame_done to draw by setting the 
// appropriate colors.  Note the clock is 25MHz for the VGA based on clock division below.
/////////////////////////////////////////////////////////////////////////////////////

module vga_driver(

input clk,
input rst,

output reg vga_clk,

output reg hsync, // horizontal sync
output reg vsync, // vertical sync

output reg active_pixels, // is on when we're in the active draw space
output reg frame_done, // is on when we're done writing 640*480

// NOTE x and y that are passed out go greater than 640 for x and 480 for y as those signals need to be sent for hsync and vsync
output reg [9:0]xPixel, // current x 
output reg [9:0]yPixel, // current y - 10 bits = 1024 ... a little bit more than we need

output reg VGA_BLANK_N,	//	VGA BLANK = !BLANK Composite Blank Control Input (TTL Compatible). A Logic 0 on this control input drives the analog outputs, IOR, IOB, and IOG, to  the blanking level.  The  BLANK  signal is latched on the rising edge  of CLOCK.  While BLANK  is a Logic 0, the R0 to  R9, G0  to  G9, and B0 to  B9 pixel inputs are  ignored. 

output reg VGA_SYNC_N		//	VGA SYNC = !SYNC Composite Sync Control Input (TTL Compatible). A Logic 0 on the  SYNC source.  This is internally connected to  the IOG analog output.  SYNC  input switches off a 40 IRE current  does  not override any other control  or data input; therefore, it should only be asserted during the blanking interval.  SYNC edge of CLOCK.  If  sync information is not required  on the green channel, the  SYNC Logic  0. 
);

//Timings from https://timetoexplore.net/blog/video-timings-vga-720p-1080p
// 640 by 480

// horizontal timings
parameter HA_END = 10'd639;           // end of active pixels
parameter HS_STA = HA_END + 16;   // sync starts after front porch
parameter HS_END = HS_STA + 96;   // sync ends
parameter WIDTH   = 10'd799;           // last pixel on line (after back porch)

// vertical timings
parameter VA_END = 10'd479;           // end of active pixels
parameter VS_STA = VA_END + 10;   // sync starts after front porch
parameter VS_END = VS_STA + 2;    // sync ends
parameter HEIGHT = 10'd524;           // last line on screen (after back porch)

always @(*)
begin 
	hsync = ~((xPixel >= HS_STA) && (xPixel < HS_END));
	vsync = ~((yPixel >= VS_STA) && (yPixel < VS_END));
	active_pixels = (xPixel <= HA_END && yPixel <= VA_END);
	//frame_done = (xPixel >= HA_END && yPixel >= VA_END);
	frame_done = (yPixel >= VA_END);
	
	VGA_BLANK_N = active_pixels;
	VGA_SYNC_N = 1'b1;
end

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		vga_clk <= 1'b0;
		xPixel <= 10'd0;
		yPixel <= 10'd0;
	end
	else
	begin
		vga_clk = ~vga_clk; // clock divider
		
		if (vga_clk == 1'b1)
			if(xPixel == WIDTH)
			begin
				xPixel <= 10'd0;
				if(yPixel == HEIGHT)
				begin
					yPixel<=10'd0;
				end
				else
				begin
					yPixel <= yPixel+1'b1;
				end
			end
			else
			begin
				xPixel <= xPixel+1'b1;
			end
		end
end

endmodule