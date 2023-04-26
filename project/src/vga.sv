`include "utils.sv"


module VGACtrl (
	input  logic clk, reset,
	output logic [9:0] DrawX, DrawY,
	output logic pixel_clk, hs, vs);

	always_ff @ (posedge clk or posedge reset) begin
		if (reset) pixel_clk <= 0;
		else pixel_clk <= ~pixel_clk;
	end

	always_ff @ (posedge pixel_clk or posedge reset) begin

		if (reset) begin
			DrawX <= 0;
			DrawY <= 0;
		end else if (DrawX == `VGA_MAX_X - 1) begin
			DrawX <= 0;
			if (DrawY == `VGA_MAX_Y - 1)
				DrawY <= 0;
			else DrawY <= DrawY + 10'd1;
		end else DrawX <= DrawX + 10'd1;

		if (reset) hs <= 0;
		else if ((DrawX + 1 >= `VGA_HSYNC_START & DrawX + 1 < `VGA_HSYNC_END)) hs <= 0;
		else hs <= 1;

		if (reset) vs <= 0;
		else if ((DrawY + 1 >= `VGA_VSYNC_START & DrawY + 1 < `VGA_VSYNC_END)) vs <= 0;
		else vs <= 1;

	end

endmodule
