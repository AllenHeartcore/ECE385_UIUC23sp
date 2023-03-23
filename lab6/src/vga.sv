`include "utils.sv"

module VGAController (
	input  logic Clk, Reset,			// 50 MHz
	output logic pixel_clk,				// 25 MHz
	output logic hs, vs, blank,			// AL sync pulse, blanking interval
	output logic sync,					// Composite Sync, unused but required by DE2 video DAC
	output logic [9:0] DrawX, DrawY);	// line counters, coords on 800x525 display

	assign sync = 0;	// disable Composite Sync

	always_ff @ (posedge Clk or posedge Reset) begin
		if (Reset) pixel_clk <= 0;
		else pixel_clk <= ~pixel_clk;	// cut Clk in half
	end

	// "hs", "vs" are registered to ensure clean output waveform
	// "blank" is registered within the DAC chip and written as combinational logic here

	always_ff @ (posedge pixel_clk or posedge Reset) begin

		if (Reset) begin
			DrawX <= 0;
			DrawY <= 0;
		end else if (DrawX == `VGA_MAX_X - 1) begin	// DrawX reached end of pixel count
			DrawX <= 0;
			if (DrawY == `VGA_MAX_Y - 1)			// DrawY reached end of line count
				DrawY <= 0;
			else DrawY <= DrawY + 1;
		end else DrawX <= DrawX + 1;				// implied DrawY <= DrawY

		if (Reset) hs <= 0;
		else if ((DrawX + 1 >= `VGA_HSYNC_START & DrawX + 1 < `VGA_HSYNC_END)) hs <= 0;
		else hs <= 1;
		
		if (Reset) vs <= 0;
		else if ((DrawY + 1 >= `VGA_VSYNC_START & DrawY + 1 < `VGA_VSYNC_END)) vs <= 0;
		else vs <= 1;

	end

	always_comb begin
		if ((DrawX >= `VGA_DISP_X) | (DrawY >= `VGA_DISP_Y)) blank = 0;
		else blank = 1;
	end

endmodule
