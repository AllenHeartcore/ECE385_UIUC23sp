`include "utils.sv"


module VGACtrl (
	input  logic Clk, Reset,
	output logic [9:0] DrawX, DrawY,
	output logic hs, vs, blank);

	logic pixel_clk;

	always_ff @ (posedge Clk or posedge Reset) begin
		if (Reset) pixel_clk <= 0;
		else pixel_clk <= ~pixel_clk;
	end

	always_ff @ (posedge pixel_clk or posedge Reset) begin

		if (Reset) begin
			DrawX <= 0;
			DrawY <= 0;
		end else if (DrawX == `VGA_MAX_X - 1) begin
			DrawX <= 0;
			if (DrawY == `VGA_MAX_Y - 1)
				DrawY <= 0;
			else DrawY <= DrawY + 10'd1;
		end else DrawX <= DrawX + 10'd1;

		if (Reset) hs <= 0;
		else if ((DrawX + 1 >= `VGA_HSYNC_START & DrawX + 1 < `VGA_HSYNC_END)) hs <= 0;
		else hs <= 1;
		
		if (Reset) vs <= 0;
		else if ((DrawY + 1 >= `VGA_VSYNC_START & DrawY + 1 < `VGA_VSYNC_END)) vs <= 0;
		else vs <= 1;

	end

	always_comb begin
		if ((DrawX >= `VGA_DISP_X) | (DrawY >= `VGA_DISP_Y)) blank = 1;
		else blank = 0;
	end

endmodule
