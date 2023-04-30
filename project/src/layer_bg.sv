`include "utils.sv"


module layer_bg (
	input  logic pixel_clk, bg_select,
	input  logic [ 9:0] DrawX, DrawY,
	output logic [11:0] color);

	logic [16:0] rom_addr;
	logic [ 7:0] rom_data;
	logic [11:0] palette_color;

	rom_bg rom_bg (
		.clk  (pixel_clk),
		.addr (rom_addr),
		.data (rom_data));

	palette_bg palette_bg (
		.index (rom_data),
		.color (palette_color));

	assign rom_addr =
		bg_select * `BG_X_SIZE * `BG_Y_SIZE +
		DrawY / 3 * `BG_X_SIZE +
		DrawX / 3;

	always_ff @ (posedge pixel_clk) begin
		color <= palette_color;
	end

endmodule


module rom_bg (
	input  logic clk,
	input  logic [16:0] addr,
	output logic [ 7:0] data);

	logic [7:0] memory [0:68159] /* synthesis ram_init_file = "./media/sprite_bg.mif" */;

	always_ff @ (posedge clk) begin
		data <= memory[addr];
	end

endmodule


module palette_bg (
	input  logic [ 7:0] index,
	output logic [11:0] color);

	localparam [0:255][11:0] palette = {
	12'hA9B, 12'h445, 12'hFEB, 12'hCC7, 12'hFD4, 12'h67A, 12'hDDE, 12'h28A,
	12'h8A8, 12'h146, 12'hDD9, 12'hF62, 12'hFEE, 12'h488, 12'hCBC, 12'h367,
	12'h223, 12'h989, 12'h879, 12'hBBD, 12'hE97, 12'h865, 12'h568, 12'h896,
	12'h78B, 12'hAB8, 12'h279, 12'hCD8, 12'h256, 12'hBA2, 12'hEC6, 12'hFEC,
	12'hBCD, 12'h9A7, 12'hECD, 12'hEEA, 12'h125, 12'h688, 12'h38A, 12'h39B,
	12'h678, 12'h358, 12'hBAB, 12'h334, 12'hCA5, 12'hF84, 12'hC98, 12'h59B,
	12'h79C, 12'h346, 12'hBAA, 12'hFD3, 12'hEEE, 12'h9A9, 12'hFC4, 12'hAEF,
	12'hEDB, 12'hECC, 12'hFC5, 12'h98A, 12'hBC8, 12'hBCA, 12'hDAB, 12'h024,
	12'h679, 12'hFD7, 12'h576, 12'hFA8, 12'h893, 12'hA77, 12'hAAB, 12'hDDD,
	12'hFAB, 12'h156, 12'hEC5, 12'h59A, 12'h9AD, 12'h112, 12'h577, 12'hF96,
	12'hEE9, 12'hFFE, 12'h136, 12'h742, 12'h9A7, 12'h334, 12'h68B, 12'h768,
	12'h99A, 12'h699, 12'h9A8, 12'h289, 12'hDDA, 12'h389, 12'h366, 12'hA92,
	12'h577, 12'h797, 12'h569, 12'hDD8, 12'h278, 12'hBB7, 12'hE8A, 12'h798,
	12'hBC8, 12'hFD6, 12'hB88, 12'h8AA, 12'hEA8, 12'hFC5, 12'hCEF, 12'h458,
	12'hCCD, 12'hAAC, 12'hAB9, 12'h323, 12'h598, 12'hEEC, 12'h235, 12'h7BE,
	12'hFEE, 12'hEED, 12'h478, 12'h88A, 12'hF72, 12'hCDA, 12'h49C, 12'h9BB,
	12'hAA6, 12'h167, 12'h687, 12'h569, 12'hFD8, 12'hAB6, 12'hA9A, 12'h996,
	12'hFEA, 12'h754, 12'hDDA, 12'hEEE, 12'hBDD, 12'hCDE, 12'hFFE, 12'h6AB,
	12'hC85, 12'h778, 12'hDD9, 12'h489, 12'h155, 12'hDB7, 12'h267, 12'hFB6,
	12'h667, 12'hCC7, 12'hDD9, 12'hABB, 12'h588, 12'hFFF, 12'hDBB, 12'hEB3,
	12'hEEB, 12'h39B, 12'hCC6, 12'hC9A, 12'h889, 12'h57B, 12'h543, 12'h29B,
	12'hBEE, 12'h347, 12'hCCD, 12'hA94, 12'h897, 12'hCC9, 12'hBBC, 12'h89B,
	12'hCA8, 12'h569, 12'h8AC, 12'hDCD, 12'h8A8, 12'hDCD, 12'h698, 12'h567,
	12'h675, 12'h236, 12'hFD5, 12'hABC, 12'hBBC, 12'h457, 12'hEEE, 12'hC78,
	12'h9A7, 12'h247, 12'hFA7, 12'h49B, 12'hDA6, 12'h278, 12'h333, 12'h445,
	12'h7AB, 12'h466, 12'h259, 12'h68C, 12'hDC6, 12'hACC, 12'hEC7, 12'hF96,
	12'h477, 12'h9CE, 12'h459, 12'h953, 12'hCCC, 12'h024, 12'h8A8, 12'h89A,
	12'hEEE, 12'hD62, 12'h99B, 12'h146, 12'h245, 12'hF73, 12'hEDE, 12'hCC8,
	12'h289, 12'h668, 12'hBA9, 12'hEEB, 12'h556, 12'hBB6, 12'hCC9, 12'hFDD,
	12'hEBC, 12'hDDE, 12'h013, 12'h156, 12'hA74, 12'h898, 12'hA98, 12'hF95,
	12'hCB6, 12'hB97, 12'h234, 12'h257, 12'h243, 12'hFD6, 12'h789, 12'hAB7,
	12'h246, 12'hB9A, 12'h79A, 12'h786, 12'h877, 12'hAB8, 12'h698, 12'h377};

	assign color = palette[index];

endmodule
