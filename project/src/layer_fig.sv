`include "utils.sv"


module layer_fig (
	input  logic pixel_clk, pos_select,
	input  logic [ 1:0] fig_select,
	input  logic [ 9:0] DrawX, DrawY,
	output logic [11:0] color);

	logic [16:0] rom_addr;
	logic [ 5:0] rom_data;
	logic [ 9:0] DrawXAnch, DrawYAnch;
	logic [11:0] palette_color;

	rom_fig rom_fig (
		.clk  (pixel_clk),
		.addr (rom_addr),
		.data (rom_data));

	palette_fig palette_fig (
		.index (rom_data),
		.color (palette_color));

	assign DrawXAnch = `FIG_X_START;
	assign DrawYAnch = pos_select ? `FIG_Y_START_F : `FIG_Y_START_H;
	assign rom_addr =
		fig_select * `FIG_X_SIZE * `FIG_Y_SIZE +
		(DrawY - DrawYAnch) * `FIG_X_SIZE +
		(DrawX - DrawXAnch);

	always_ff @ (posedge pixel_clk) begin
		color <= palette_color;
	end

endmodule


module rom_fig (
	input  logic clk,
	input  logic [16:0] addr,
	output logic [ 5:0] data);

	logic [5:0] memory [0:131071] /* synthesis ram_init_file = "./sprite/sprite_fig.mif" */;

	always_ff @ (posedge clk) begin
		data <= memory[addr];
	end

endmodule


module palette_fig (
	input  logic [ 5:0] index,
	output logic [11:0] color);

	localparam [0:63][11:0] palette = {
	12'hFDD, 12'h000, 12'h58A, 12'hBBC, 12'h878, 12'h656, 12'h323, 12'h8BC,
	12'hCBB, 12'hBAB, 12'h989, 12'hFEE, 12'h656, 12'hDCB, 12'h877, 12'hACE,
	12'hCDE, 12'h9CD, 12'h223, 12'h200, 12'hA99, 12'h212, 12'h445, 12'hAAB,
	12'hEDD, 12'hA88, 12'h755, 12'hA47, 12'h212, 12'hDBA, 12'hBAA, 12'h69B,
	12'h544, 12'h988, 12'hDCC, 12'hCCD, 12'h568, 12'h656, 12'h334, 12'hEEE,
	12'h99A, 12'h88A, 12'h877, 12'h212, 12'hCCC, 12'hCAA, 12'hC79, 12'hADD,
	12'h322, 12'hA9A, 12'hB99, 12'hFFF, 12'hFED, 12'h7AE, 12'hEEE, 12'hEDC,
	12'h656, 12'hDDD, 12'hDDD, 12'h877, 12'h778, 12'h534, 12'hA99, 12'h544};

	assign color = palette[index];

endmodule
