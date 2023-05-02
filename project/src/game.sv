`include "utils.sv"


module Game (
	input  logic clk, reset,
	input  logic avl_rden, avl_wren, avl_cs,
	input  logic [5:0] avl_addr,
	input  logic [7:0] avl_wdata,
	output logic [7:0] avl_rdata,

	output logic [3:0] red, green, blue,
	output logic hs, vs,

	input  logic sclk, lrclk, dout,
	output logic din);


	/* [Register Arrangement]
	 *
	 * 0x00 - 0x07: |   SCORE   |  ACC  | B | C | D |
	 * 0x08 - 0x0F: | E | F | G | H | I | J | K | L |
	 * 0x10 - 0x17: | M | N | O | P |   | R | S | T |
	 * 0x18 - 0x1F: | U | V | W | X | Y |   |   | 2 |
	 * 0x20 - 0x27: | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 |
	 * 0x28 - 0x2F: |SDRAM_ADDR |DAT|   | - | = | [ |
	 * 0x30 - 0x37: |FLG|LFE|SKL| ; |   |   | , | . |
	 * 0x38 - 0x3F: | NPURE | NFAR  | NLOST | NCOMBO|
	 *
	 * ["keystat" Register Format]
	 * | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
	 * |   BRGHT   | COLOR |   NSIZE   |
	 *
	 * ["flags" Register Format]
	 * | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
	 * |   |   |   |PLY| STATE |  FIG  |
	 */

	logic [ 7:0] keystat[51];
	logic [23:0] score;
	logic [15:0] acc, npure, nfar, nlost, ncombo;
	logic [ 7:0] life, skill;

	logic [23:0] sdram_addr;
	logic [ 7:0] sdram_data;
	logic [ 1:0] gst_state, gst_fig;
	logic audio_play;

	always_ff @ (posedge clk) begin

		if (avl_cs && avl_rden)
			case (avl_addr)
				6'h00: avl_rdata <= score [ 7: 0];
				6'h01: avl_rdata <= score [15: 8];
				6'h02: avl_rdata <= score [23:16];
				6'h03: avl_rdata <= acc   [ 7: 0];
				6'h04: avl_rdata <= acc   [15: 8];
				6'h38: avl_rdata <= npure [ 7: 0];
				6'h39: avl_rdata <= npure [15: 8];
				6'h3A: avl_rdata <= nfar  [ 7: 0];
				6'h3B: avl_rdata <= nfar  [15: 8];
				6'h3C: avl_rdata <= nlost [ 7: 0];
				6'h3D: avl_rdata <= nlost [15: 8];
				6'h3E: avl_rdata <= ncombo[ 7: 0];
				6'h3F: avl_rdata <= ncombo[15: 8];

				6'h28: avl_rdata <= sdram_addr[ 7: 0];
				6'h29: avl_rdata <= sdram_addr[15: 8];
				6'h2A: avl_rdata <= sdram_addr[23:16];
				6'h2B: avl_rdata <= sdram_data;
				6'h30: avl_rdata <= {audio_play, gst_state, gst_fig};
				6'h31: avl_rdata <= life;
				6'h32: avl_rdata <= skill;

				default: avl_rdata <= keystat[avl_addr - 6'h05];
			endcase

		else if (avl_cs && avl_wren)
			case (avl_addr)

				6'h00: score [ 7: 0] <= avl_wdata;
				6'h01: score [15: 8] <= avl_wdata;
				6'h02: score [23:16] <= avl_wdata;
				6'h03: acc   [ 7: 0] <= avl_wdata;
				6'h04: acc   [15: 8] <= avl_wdata;
				6'h38: npure [ 7: 0] <= avl_wdata;
				6'h39: npure [15: 8] <= avl_wdata;
				6'h3A: nfar  [ 7: 0] <= avl_wdata;
				6'h3B: nfar  [15: 8] <= avl_wdata;
				6'h3C: nlost [ 7: 0] <= avl_wdata;
				6'h3D: nlost [15: 8] <= avl_wdata;
				6'h3E: ncombo[ 7: 0] <= avl_wdata;
				6'h3F: ncombo[15: 8] <= avl_wdata;

				6'h2B: sdram_data <= avl_wdata;
				6'h30: {audio_play, gst_state, gst_fig} <= avl_wdata[4:0];
				6'h31: life  <= avl_wdata;
				6'h32: skill <= avl_wdata;

				default: keystat[avl_addr - 6'h05] <= avl_wdata;
			endcase
	end


	I2S i2s (.sclk, .lrclk, .din, .dout,
		.addr(sdram_addr), .sample(sdram_data), .play(audio_play));


	/* Canvas Formatter */

	logic pixel_clk;
	logic [ 9:0] DrawX, DrawY;
	logic [11:0] color_bg, color_fig, color_kbd, color_txt;

	VGACtrl vga (.clk, .reset, .pixel_clk, .DrawX, .DrawY, .hs, .vs);

	layer_bg  layer_bg  (.*,
		.color(color_bg),
		.bg_select(gst_state[1] & gst_state[0]));

	layer_fig layer_fig (.*,
		.color(color_fig),
		.pos_select(gst_state[0]),
		.fig_select(gst_fig));

	layer_kbd layer_kbd (.*,
		.color(color_kbd));

	layer_txt layer_txt (.*,
		.color(color_txt));

	always_comb begin

		if (color_txt != 12'h000)
			{red, green, blue} = color_txt;

		else if (gst_state == `GST_STATE_CONFIG
			&& DrawX >= `FIG_X_START   && DrawX < `FIG_X_START + `FIG_X_SIZE
			&& DrawY >= `FIG_Y_START_F && DrawY < `FIG_Y_START_F + `FIG_Y_SIZE
			&& color_fig != 12'h000)
			{red, green, blue} = color_fig;

		else if (gst_state == `GST_STATE_PLAY
			&& DrawX >= `FIG_X_START   && DrawX < `FIG_X_START + `FIG_X_SIZE
			&& DrawY >= `FIG_Y_START_H && DrawY < `VGA_DISP_Y
			&& color_fig != 12'h000)
			{red, green, blue} = color_fig;

		else if (gst_state == `GST_STATE_PLAY
			&& DrawX >= `KBD_X_START && DrawX < `KBD_X_END
			&& DrawY >= `KBD_Y_START && DrawY < `KBD_Y_END
			&& color_kbd != 12'h000)
			{red, green, blue} = color_kbd;

		else if (gst_state == `GST_STATE_IDLE)
			{red, green, blue} = color_bg;

		else begin
			red   = {1'b0, color_bg[11:9]};
			green = {1'b0, color_bg[ 7:5]};
			blue  = {1'b0, color_bg[ 3:1]};
		end
	end


endmodule
