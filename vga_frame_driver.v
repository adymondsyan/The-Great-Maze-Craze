module vga_frame_driver(

input clk,
input rst,

output active_pixels, // is on when we're in the active draw space
output frame_done, // is on when we're done writing 640*480

// NOTE x and y that are passed out go greater than 640 for x and 480 for y as those signals need to be sent for hsync and vsync
output [9:0]x, // current x 
output [9:0]y, // current y - 10 bits = 1024 ... a little bit more than we need

//////////// VGA //////////
output		          		VGA_BLANK_N,
output		          		VGA_CLK,
output		          		VGA_HS,
output reg	     [7:0]		VGA_B,
output reg	     [7:0]		VGA_G,
output reg	     [7:0]		VGA_R,
output		          		VGA_SYNC_N,
output		          		VGA_VS,

/* access ports to the frame we draw from */
input [14:0] the_vga_draw_frame_write_mem_address,
input [23:0] the_vga_draw_frame_write_mem_data,
input the_vga_draw_frame_write_a_pixel

);

/* MEMORIES -------------------------------- */
/* signals that will be combinationally swapped in each cycle - this is the double buffer */
reg [1:0] wr_id;
reg [15:0] write_buf_mem_address;
reg [23:0] write_buf_mem_data;
reg write_buf_mem_wren;
reg [23:0] read_buf_mem_q;
reg [15:0] read_buf_mem_address;

/* MEMORY to STORE a the framebuffers.  Problem is the FPGA's on-chip memory can't hold an entire frame 640*480 , so some clock
form of compression is needed. */
reg [15:0] frame_buf_mem_address0;
reg [23:0] frame_buf_mem_data0;
reg frame_buf_mem_wren0;
wire [23:0]frame_buf_mem_q0;
/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide - This memory is 24-bit words of size 32768 spots */
vga_frame vga_memory0(
	frame_buf_mem_address0,
	clk,
	frame_buf_mem_data0,
	frame_buf_mem_wren0,
	frame_buf_mem_q0);
	
reg [15:0] frame_buf_mem_address1;
reg [23:0] frame_buf_mem_data1;
reg frame_buf_mem_wren1;
wire [23:0]frame_buf_mem_q1;
/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide - This memory is 24-bit words of size 32768 spots */
vga_frame vga_memory1(
	frame_buf_mem_address1,
	clk,
	frame_buf_mem_data1,
	frame_buf_mem_wren1,
	frame_buf_mem_q1);

/* This is the frame that is written to and readfrom into the double buffering */
reg [15:0] the_vga_draw_frame_mem_address;
reg [23:0] the_vga_draw_frame_mem_data;
reg the_vga_draw_frame_mem_wren;
wire [23:0] the_vga_draw_frame_mem_q;

/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide - This memory is 24-bit words of size 32768 spots */
/* This is the main memory to write to */
vga_frame the_vga_draw_frame(
	the_vga_draw_frame_mem_address,
	clk,
	the_vga_draw_frame_mem_data,
	the_vga_draw_frame_mem_wren,
	the_vga_draw_frame_mem_q);
/* ALWAYS block writes to the memory or otherwise is just being read into the framebuffer */
always @(*)
begin
	/* writing from external code */
	if (the_vga_draw_frame_write_a_pixel == 1'b1) 
	begin
		the_vga_draw_frame_mem_address = the_vga_draw_frame_write_mem_address;
		the_vga_draw_frame_mem_data = the_vga_draw_frame_write_mem_data;
		the_vga_draw_frame_mem_wren = 1'b1;
	end
	else
	begin
		/* just reading */
		the_vga_draw_frame_mem_address = (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE);
		the_vga_draw_frame_mem_data = 14'd0;
		the_vga_draw_frame_mem_wren = 1'b0;	
	end
end

reg [7:0]S;
reg [7:0]NS;

parameter 
	START 			= 8'd0,
	// W2M is write to memory
	W2M_DONE 		= 8'd4, // skipped since using mif file
	// The RFM = READ_FROM_MEMOERY reading cycles
	RFM_INIT_START 	= 8'd5,
	RFM_INIT_WAIT 	= 8'd6,
	RFM_DRAWING 	= 8'd7,
	ERROR 			= 8'hFF;

parameter MEMORY_SIZE = 16'd19200; // 160*120 // Number of memory spots ... highly reduced since memory is slow
parameter PIXEL_VIRTUAL_SIZE = 16'd4; // Pixels per spot - therefore 4x4 pixels per memory location

/* ACTUAL VGA RESOLUTION */
parameter VGA_WIDTH = 16'd640; 
parameter VGA_HEIGHT = 16'd480;

/* Our reduced RESOLUTION 160 by 120 needs a memory of 19,200 words each 24 bits wide */
parameter VIRTUAL_PIXEL_WIDTH = VGA_WIDTH/PIXEL_VIRTUAL_SIZE; // 160
parameter VIRTUAL_PIXEL_HEIGHT = VGA_HEIGHT/PIXEL_VIRTUAL_SIZE; // 120

vga_driver the_vga(
.clk(clk),
.rst(rst),

.vga_clk(VGA_CLK),

.hsync(VGA_HS),
.vsync(VGA_VS),

.active_pixels(active_pixels),
.frame_done(frame_done),

.xPixel(x),
.yPixel(y),

.VGA_BLANK_N(VGA_BLANK_N),
.VGA_SYNC_N(VGA_SYNC_N)
);

always @(*)
begin
	/* This part is for taking the memory value read out from memory and sending to the VGA */
	if (S == RFM_INIT_WAIT || S == RFM_INIT_START || S == RFM_DRAWING)
	begin
		{VGA_R, VGA_G, VGA_B} = read_buf_mem_q;
	end
	else // BLACK OTHERWISE
		{VGA_R, VGA_G, VGA_B} = 24'hFFFFFF;
end

/* -------------------------------- */
/* 	FSM to control the writing and reading of the framebuffer. */

/* Calculate NS */
always @(*)
	case (S)
		START: NS = W2M_DONE;
		W2M_DONE: 
			if (frame_done == 1'b1)
				NS = RFM_INIT_START;
			else
				NS = W2M_DONE;
	
		RFM_INIT_START: NS = RFM_INIT_WAIT;
		RFM_INIT_WAIT: 
			if (frame_done == 1'b0)
				NS = RFM_DRAWING;
			else	
				NS = RFM_INIT_WAIT;
		RFM_DRAWING:
			if (frame_done == 1'b1)
				NS = RFM_INIT_START;
			else
				NS = RFM_DRAWING;
		default:	NS = ERROR;
	endcase

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
			S <= START;
	end
	else
	begin
			S <= NS;
	end
end

/* 
The code goes through a write phase (after reset) and an endless read phase once writing is done.

The W2M (write to memory) code is roughly:
for (i = 0; i < MEMORY_SIZE; i++)
	mem[i] = color // where color is a mif file

The RFM (read from memory) is synced with the VGA display (via vga_driver modules x and y) which goes row by row
for (y = 0; y < 480; y++) // height
	for (x = 0; x < 640; x++) // width
		color = mem[(x/4 * VP_HEIGHT) + j/4] reads from one of the buffers while you can write to the other buffer
*/
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		write_buf_mem_address <= 14'd0;
		write_buf_mem_data <= 24'd0;
		write_buf_mem_wren <= 1'd0;
		wr_id <= MEM_INIT_WRITE;
	end
	else
	begin
		case (S)
			START:
			begin
				write_buf_mem_address <= 14'd0;
				write_buf_mem_data <= 24'd0;
				write_buf_mem_wren <= 1'd0;
				wr_id <= MEM_INIT_WRITE;
			end
			W2M_DONE: write_buf_mem_wren <= 1'd0; // turn off writing to memory
			
			RFM_INIT_START: 
			begin
				write_buf_mem_wren <= 1'd0; // turn off writing to memory
				
				/* swap the buffers after each frame...the double buffer */
				if (wr_id == MEM_INIT_WRITE)
					wr_id <= MEM_M0_READ_M1_WRITE;
				else if (wr_id == MEM_M0_READ_M1_WRITE)
					wr_id <= MEM_M0_WRITE_M1_READ;
				else
					wr_id <= MEM_M0_READ_M1_WRITE;
								
				if (y < VGA_HEIGHT-1 && x < VGA_WIDTH-1) // or use the active_pixels signal
					read_buf_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE) ;
			end
			RFM_INIT_WAIT:
			begin
				if (y < VGA_HEIGHT-1 && x < VGA_WIDTH-1) // or use the active_pixels signal
					read_buf_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE) ;
			end
			RFM_DRAWING:
			begin		
				if (y < VGA_HEIGHT-1 && x < VGA_WIDTH-1)
					read_buf_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE) ;
				
				write_buf_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE);
				write_buf_mem_data <= the_vga_draw_frame_mem_q;
				write_buf_mem_wren <= 1'b1;
						
			end	
		endcase
	end
end

parameter MEM_INIT_WRITE = 2'd0,
		  MEM_M0_READ_M1_WRITE = 2'd1,
		  MEM_M0_WRITE_M1_READ = 2'd2,
		  MEM_ERROR = 2'd3;

/* signals that will be combinationally swapped in each buffer output that swaps between wr_id where wr_id = 0 is for initialize */
always @(*)
begin
	if (wr_id == MEM_INIT_WRITE) // WRITING to BOTH
	begin
		frame_buf_mem_address0 = write_buf_mem_address;
		frame_buf_mem_data0 = write_buf_mem_data;
		frame_buf_mem_wren0 = write_buf_mem_wren;
		frame_buf_mem_address1 = write_buf_mem_address;
		frame_buf_mem_data1 = write_buf_mem_data;
		frame_buf_mem_wren1 = write_buf_mem_wren;
		
		read_buf_mem_q = frame_buf_mem_q1; // doesn't matter
	end
	else if (wr_id == MEM_M0_WRITE_M1_READ) // WRITING to MEM 0 READING FROM MEM 1
	begin
		// MEM 0 - WRITE
		frame_buf_mem_address0 = write_buf_mem_address;
		frame_buf_mem_data0 = write_buf_mem_data;
		frame_buf_mem_wren0 = write_buf_mem_wren;
		// MEM 1 - READ
		frame_buf_mem_address1 = read_buf_mem_address;
		frame_buf_mem_data1 = 24'd0;
		frame_buf_mem_wren1 = 1'b0;
		read_buf_mem_q = frame_buf_mem_q1;
	end
	else //if (wr_id == MEM_M0_READ_M1_WRITE) WRITING to MEM 1 READING FROM MEM 0
	begin
		// MEM 0 - READ
		frame_buf_mem_address0 = read_buf_mem_address;
		frame_buf_mem_data0 = 24'd0;
		frame_buf_mem_wren0 = 1'b0;
		read_buf_mem_q = frame_buf_mem_q0;
		// MEM 1 - WRITE
		frame_buf_mem_address1 = write_buf_mem_address;
		frame_buf_mem_data1 = write_buf_mem_data;
		frame_buf_mem_wren1 = write_buf_mem_wren;
	end
end

endmodule