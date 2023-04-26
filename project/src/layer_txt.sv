`include "utils.sv"


module layer_txt (
	input  logic pixel_clk,
	input  logic [23:0] score,
	input  logic [15:0] acc, npure, nfar, nlost, ncombo,
	input  logic [ 1:0] gst_state, gst_fig,
	input  logic [ 7:0] life, skill,
	input  logic [ 9:0] DrawX, DrawY,
	output logic [11:0] color);

	logic [ 6:0] DrawXCoord, DrawXAnch, DrawXLim, Char;
	logic [ 8:0] CharIdx, CharIdxBase;
	logic [ 5:0] DrawYCoord;
	logic [10:0] font_addr;
	logic [ 7:0] font_data;
	logic [ 2:0] colorcode;
	logic [11:0] txt_color, life_color, skill_color;
	logic Pixel;

`define COLOR_WHITE 12'hFFF
`define COLOR_RED   12'hF88
`define COLOR_GREEN 12'h8F8
`define COLOR_BLUE  12'h88F

	rom_txt  rom_txt  (.*, .addr(CharIdx));
	rom_font rom_font (.addr(font_addr), .data(font_data));
	palette_txt palette_txt (.*, .color(txt_color));

	always_comb begin

		DrawXCoord = DrawX[9:3];
		DrawYCoord = DrawY[9:4];

		case (gst_state)
			2'b00: begin
				DrawXAnch = 7'd26;
				case (DrawYCoord)
					6'd20: {DrawXLim, CharIdxBase} = {7'd53, 9'd0};
					6'd21: {DrawXLim, CharIdxBase} = {7'd50, 9'd27};
					default: {DrawXLim, CharIdxBase} = {7'd0, 9'd0};
				endcase
			end
			2'b01: begin
				DrawXAnch = 7'd16;
				case (DrawYCoord)
					6'd14: case (gst_fig)
						2'b00: {DrawXLim, CharIdxBase} = {7'd27, 9'd51};
						2'b01: {DrawXLim, CharIdxBase} = {7'd27, 9'd81};
						2'b10: {DrawXLim, CharIdxBase} = {7'd25, 9'd111};
						2'b11: {DrawXLim, CharIdxBase} = {7'd28, 9'd147};
					endcase
					6'd15: case (gst_fig)
						2'b00: {DrawXLim, CharIdxBase} = {7'd35, 9'd62};
						2'b01: {DrawXLim, CharIdxBase} = {7'd35, 9'd92};
						2'b10: {DrawXLim, CharIdxBase} = {7'd43, 9'd120};
						2'b11: {DrawXLim, CharIdxBase} = {7'd44, 9'd159};
					endcase
					default: {DrawXLim, CharIdxBase} = {7'd0, 9'd0};
				endcase
			end
			2'b10: begin
				DrawXAnch = 7'd19;
				case (DrawYCoord)
					6'd2: {DrawXLim, CharIdxBase} = {7'd53, 9'd187};
					6'd3: {DrawXLim, CharIdxBase} = {7'd53, 9'd221};
					6'd4: {DrawXLim, CharIdxBase} = {7'd43, 9'd255};
					6'd5: {DrawXLim, CharIdxBase} = {7'd43, 9'd279};
					default: {DrawXLim, CharIdxBase} = {7'd0, 9'd0};
				endcase
			end
			2'b11: begin
				DrawXAnch = 7'd51;
				case (DrawYCoord)
					6'd12: {DrawXLim, CharIdxBase} = life == 0 ? {7'd66, 9'd303} : {7'd67, 9'd318};
					6'd13: {DrawXLim, CharIdxBase} = {7'd69, 9'd334};
					6'd14: {DrawXLim, CharIdxBase} = {7'd69, 9'd352};
					6'd15: {DrawXLim, CharIdxBase} = {7'd69, 9'd370};
					6'd16: {DrawXLim, CharIdxBase} = {7'd69, 9'd388};
					6'd17: {DrawXLim, CharIdxBase} = {7'd69, 9'd406};
					6'd18: {DrawXLim, CharIdxBase} = {7'd69, 9'd424};
					default: {DrawXLim, CharIdxBase} = {7'd0, 9'd0};
				endcase
			end
		endcase

		CharIdx   = CharIdxBase + DrawXCoord - DrawXAnch;
		font_addr = Char << 4 | DrawY[3:0];
		Pixel     = font_data[~DrawX[2:0]];

		if (life[7:6] == 2'b00)
			life_color = `COLOR_RED;
		else
			life_color = `COLOR_WHITE;
		if (skill == 8'hFF)
			skill_color = `COLOR_GREEN;
		else if (skill[0])
			skill_color = `COLOR_WHITE;
		else
			skill_color = `COLOR_BLUE;
	end

	always_ff @ (posedge pixel_clk) begin
		if (
			Pixel &&
			DrawXLim != 0 &&
			DrawXCoord >= DrawXAnch &&
			DrawXCoord < DrawXLim
		)
			color <= txt_color;		// text
		else if (
			gst_state == `GST_STATE_PLAY &&
			DrawX >= `GAUGE_X_START &&
			DrawX <  `GAUGE_X_START + life[7:1] &&
			DrawY >= `GAUGE_Y_START_L &&
			DrawY <  `GAUGE_Y_END_L
		)
			color <= life_color;	// life gauge
		else if (
			gst_state == `GST_STATE_PLAY &&
			DrawX >= `GAUGE_X_START &&
			DrawX <  `GAUGE_X_START + skill[7:1] &&
			DrawY >= `GAUGE_Y_START_S &&
			DrawY <  `GAUGE_Y_END_S
		)
			color <= skill_color;	// skill gauge
		else
			color <= 12'h000;
	end

endmodule


module palette_txt (
	input  logic [ 2:0] colorcode,
	output logic [11:0] color);

	localparam [0:7][11:0] palette = {
	`COLOR_WHITE, `COLOR_RED, `COLOR_BLUE, `COLOR_GREEN,
	12'hECC, 12'hADE, 12'hBDF, 12'hAAB};

	assign color = palette[colorcode];

endmodule


module rom_txt (
	input  logic [23:0] score,
	input  logic [15:0] acc, npure, nfar, nlost, ncombo,
	input  logic [ 8:0] addr,
	output logic [ 6:0] Char,
	output logic [ 2:0] colorcode);

	/* [GST_STATE_IDLE]   (X 26-52, Y 20-21)
	 * (  0) TrapoTempo ft. Shizuku Lulu
	 * ( 27)    --- Press [Enter] ---
	 *
	 * [GST_STATE_CONFIG] (X 16-43, Y 14-15)
	 * ( 51) FLOWER Lulu
	 * ( 62) - Score +20% for 5s
	 * ( 81) CASUAL Lulu
	 * ( 92) - Recovers 30% life
	 * (111) IDOL Lulu
	 * (120) - Score of PURE +30% for 5s
	 * (147) UNIFORM Lulu
	 * (159) - Turns FAR into PURE for 5s
	 *
	 * [GST_STATE_PLAY]   (X 19-60, Y 02-05)
	 * (187) PURE   ????        SCORE  ????????
	 * (221) FAR    ????     ACCURACY   ???.??%
	 * (255) LOST   ????         LIFE  [==============]
	 * (279) COMBO  ????        SKILL  [==============]
	 *
	 * [GST_STATE_REPORT] (X 51-68, Y 12-18)
	 * (303)    LIVE CLEAR!!
	 * (318)   LIVE FAILED...
	 * (334) SCORE     ????????
	 * (352) ACCURACY   ???.??%
	 * (370) PURE          ????
	 * (388) FAR           ????
	 * (406) LOST          ????
	 * (424) COMBO         ????
	 *
	 * [Verbatim Content] (_ = whitespace)
	 * TrapoTempo_ft._Shizuku_Lulu___---_Press_[Enter]_---FLOWER_Lulu-_
	 * Score_+20%_for_5sCASUAL_Lulu-_Recovers_30%_lifeIDOL_Lulu-_Score_
	 * of_PURE_+30%_for_5sUNIFORM_Lulu-_Turns_FAR_into_PURE_for_5sPURE_
	 * __????________SCORE__????????FAR____????_____ACCURACY___???.??%L
	 * OST___????_________LIFECOMBO__????________SKILL___LIVE_CLEAR!!__
	 * LIVE_FAILED...SCORE_____????????ACCURACY___???.??%PURE__________
	 * ????FAR___________????LOST__________????COMBO_________????
	 *
	 * [Colorcode Map]
	 * 0000000000000006666666044440000000000000333333300004444444444400
	 * 0000003333000002255555555555000000000003330000066666666600000000
	 * 0000000033330000022777777777777000000002220000003333000002233330
	 * 0033330000000000000000000000022200002222000004444444400044444441
	 * 1110001111000000000000055555005555000000000000000066666666666600
	 * 7777777777777700000000000000000044444444000444444433330000000000
	 * 3333222000000000002222111100000000001111555550000000005555
	 */

	localparam [0:441][9:0] ROM = {
	10'h054, 10'h072, 10'h061, 10'h070, 10'h06F, 10'h054, 10'h065, 10'h06D,
	10'h070, 10'h06F, 10'h020, 10'h066, 10'h074, 10'h02E, 10'h020, 10'h353,
	10'h368, 10'h369, 10'h37A, 10'h375, 10'h36B, 10'h375, 10'h020, 10'h24C,
	10'h275, 10'h26C, 10'h275, 10'h020, 10'h020, 10'h020, 10'h02D, 10'h02D,
	10'h02D, 10'h020, 10'h050, 10'h072, 10'h065, 10'h073, 10'h073, 10'h020,
	10'h1DB, 10'h1C5, 10'h1EE, 10'h1F4, 10'h1E5, 10'h1F2, 10'h1DD, 10'h020,
	10'h02D, 10'h02D, 10'h02D, 10'h246, 10'h24C, 10'h24F, 10'h257, 10'h245,
	10'h252, 10'h220, 10'h24C, 10'h275, 10'h26C, 10'h275, 10'h02D, 10'h020,
	10'h053, 10'h063, 10'h06F, 10'h072, 10'h065, 10'h020, 10'h1AB, 10'h1B2,
	10'h1B0, 10'h1A5, 10'h020, 10'h066, 10'h06F, 10'h072, 10'h020, 10'h135,
	10'h173, 10'h2C3, 10'h2C1, 10'h2D3, 10'h2D5, 10'h2C1, 10'h2CC, 10'h2A0,
	10'h2CC, 10'h2F5, 10'h2EC, 10'h2F5, 10'h02D, 10'h020, 10'h052, 10'h065,
	10'h063, 10'h06F, 10'h076, 10'h065, 10'h072, 10'h073, 10'h020, 10'h1B3,
	10'h1B0, 10'h1A5, 10'h020, 10'h06C, 10'h069, 10'h066, 10'h065, 10'h349,
	10'h344, 10'h34F, 10'h34C, 10'h320, 10'h34C, 10'h375, 10'h36C, 10'h375,
	10'h02D, 10'h020, 10'h053, 10'h063, 10'h06F, 10'h072, 10'h065, 10'h020,
	10'h06F, 10'h066, 10'h020, 10'h050, 10'h055, 10'h052, 10'h045, 10'h020,
	10'h1AB, 10'h1B3, 10'h1B0, 10'h1A5, 10'h020, 10'h066, 10'h06F, 10'h072,
	10'h020, 10'h135, 10'h173, 10'h3D5, 10'h3CE, 10'h3C9, 10'h3C6, 10'h3CF,
	10'h3D2, 10'h3CD, 10'h3A0, 10'h3CC, 10'h3F5, 10'h3EC, 10'h3F5, 10'h02D,
	10'h020, 10'h054, 10'h075, 10'h072, 10'h06E, 10'h073, 10'h020, 10'h146,
	10'h141, 10'h152, 10'h020, 10'h069, 10'h06E, 10'h074, 10'h06F, 10'h020,
	10'h1D0, 10'h1D5, 10'h1D2, 10'h1C5, 10'h020, 10'h066, 10'h06F, 10'h072,
	10'h020, 10'h135, 10'h173, 10'h1D0, 10'h1D5, 10'h1D2, 10'h1C5, 10'h020,
	10'h020, 10'h020, 10'h1BF, 10'h1BF, 10'h1BF, 10'h1BF, 10'h020, 10'h020,
	10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h053, 10'h043,
	10'h04F, 10'h052, 10'h045, 10'h020, 10'h020, 10'h03F, 10'h03F, 10'h03F,
	10'h03F, 10'h03F, 10'h03F, 10'h03F, 10'h03F, 10'h146, 10'h141, 10'h152,
	10'h020, 10'h020, 10'h020, 10'h020, 10'h13F, 10'h13F, 10'h13F, 10'h13F,
	10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h241, 10'h243, 10'h243,
	10'h255, 10'h252, 10'h241, 10'h243, 10'h259, 10'h020, 10'h020, 10'h020,
	10'h23F, 10'h23F, 10'h23F, 10'h22E, 10'h23F, 10'h23F, 10'h225, 10'h0CC,
	10'h0CF, 10'h0D3, 10'h0D4, 10'h020, 10'h020, 10'h020, 10'h0BF, 10'h0BF,
	10'h0BF, 10'h0BF, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020,
	10'h020, 10'h020, 10'h020, 10'h04C, 10'h049, 10'h046, 10'h045, 10'h2C3,
	10'h2CF, 10'h2CD, 10'h2C2, 10'h2CF, 10'h020, 10'h020, 10'h2BF, 10'h2BF,
	10'h2BF, 10'h2BF, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020,
	10'h020, 10'h020, 10'h053, 10'h04B, 10'h049, 10'h04C, 10'h04C, 10'h020,
	10'h020, 10'h020, 10'h34C, 10'h349, 10'h356, 10'h345, 10'h320, 10'h343,
	10'h34C, 10'h345, 10'h341, 10'h352, 10'h321, 10'h321, 10'h020, 10'h020,
	10'h3CC, 10'h3C9, 10'h3D6, 10'h3C5, 10'h3A0, 10'h3C6, 10'h3C1, 10'h3C9,
	10'h3CC, 10'h3C5, 10'h3C4, 10'h3AE, 10'h3AE, 10'h3AE, 10'h053, 10'h043,
	10'h04F, 10'h052, 10'h045, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020,
	10'h03F, 10'h03F, 10'h03F, 10'h03F, 10'h03F, 10'h03F, 10'h03F, 10'h03F,
	10'h241, 10'h243, 10'h243, 10'h255, 10'h252, 10'h241, 10'h243, 10'h259,
	10'h020, 10'h020, 10'h020, 10'h23F, 10'h23F, 10'h23F, 10'h22E, 10'h23F,
	10'h23F, 10'h225, 10'h1D0, 10'h1D5, 10'h1D2, 10'h1C5, 10'h020, 10'h020,
	10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020,
	10'h1BF, 10'h1BF, 10'h1BF, 10'h1BF, 10'h146, 10'h141, 10'h152, 10'h020,
	10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020,
	10'h020, 10'h020, 10'h13F, 10'h13F, 10'h13F, 10'h13F, 10'h0CC, 10'h0CF,
	10'h0D3, 10'h0D4, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020,
	10'h020, 10'h020, 10'h020, 10'h020, 10'h0BF, 10'h0BF, 10'h0BF, 10'h0BF,
	10'h2C3, 10'h2CF, 10'h2CD, 10'h2C2, 10'h2CF, 10'h020, 10'h020, 10'h020,
	10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h020, 10'h2BF, 10'h2BF,
	10'h2BF, 10'h2BF};

	logic [6:0] Char_rom, Char_val;
	logic [15:0] acc_r;

	always_comb begin

		{colorcode, Char_rom} = ROM[addr];
		acc_r = acc * 10000 / 65535;

		case (addr)
			9'd213, 9'd344: Char_val = (score / 10000000) % 10;
			9'd214, 9'd345: Char_val = (score / 1000000) % 10;
			9'd215, 9'd346: Char_val = (score / 100000) % 10;
			9'd216, 9'd347: Char_val = (score / 10000) % 10;
			9'd217, 9'd348: Char_val = (score / 1000) % 10;
			9'd218, 9'd349: Char_val = (score / 100) % 10;
			9'd219, 9'd350: Char_val = (score / 10) % 10;
			9'd220, 9'd351: Char_val = (score) % 10;
			9'd248, 9'd363: Char_val = (acc_r / 10000) % 10;
			9'd249, 9'd364: Char_val = (acc_r / 1000) % 10;
			9'd250, 9'd365: Char_val = (acc_r / 100) % 10;
			9'd252, 9'd367: Char_val = (acc_r / 10) % 10;
			9'd253, 9'd368: Char_val = (acc_r) % 10;
			9'd194, 9'd384: Char_val = (npure / 1000) % 10;
			9'd195, 9'd385: Char_val = (npure / 100) % 10;
			9'd196, 9'd386: Char_val = (npure / 10) % 10;
			9'd197, 9'd387: Char_val = (npure) % 10;
			9'd228, 9'd402: Char_val = (nfar / 1000) % 10;
			9'd229, 9'd403: Char_val = (nfar / 100) % 10;
			9'd230, 9'd404: Char_val = (nfar / 10) % 10;
			9'd231, 9'd405: Char_val = (nfar) % 10;
			9'd262, 9'd420: Char_val = (nlost / 1000) % 10;
			9'd263, 9'd421: Char_val = (nlost / 100) % 10;
			9'd264, 9'd422: Char_val = (nlost / 10) % 10;
			9'd265, 9'd423: Char_val = (nlost) % 10;
			9'd286, 9'd438: Char_val = (ncombo / 1000) % 10;
			9'd287, 9'd439: Char_val = (ncombo / 100) % 10;
			9'd288, 9'd440: Char_val = (ncombo / 10) % 10;
			9'd289, 9'd441: Char_val = (ncombo) % 10;
			default: Char_val = 7'b1111111;
		endcase

		if (Char_val == 7'b1111111)
			Char = Char_rom;
		else
			Char = Char_val + 7'd48;

	end

endmodule


module rom_font (
	input  logic [10:0] addr,
	output logic [ 7:0] data);

	localparam [0:2047][7:0] ROM = {
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7E, 8'h81, 8'hA5, 8'h81, 8'h81, 8'hBD, 8'h99, 8'h81, 8'h81, 8'h7E, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7E, 8'hFF, 8'hDB, 8'hFF, 8'hFF, 8'hC3, 8'hE7, 8'hFF, 8'hFF, 8'h7E, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h6C, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'h7C, 8'h38, 8'h10, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h10, 8'h38, 8'h7C, 8'hFE, 8'h7C, 8'h38, 8'h10, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h18, 8'h3C, 8'h3C, 8'hE7, 8'hE7, 8'hE7, 8'h18, 8'h18, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h18, 8'h3C, 8'h7E, 8'hFF, 8'hFF, 8'h7E, 8'h18, 8'h18, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h18, 8'h3C, 8'h3C, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hE7, 8'hC3, 8'hC3, 8'hE7, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h3C, 8'h66, 8'h42, 8'h42, 8'h66, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hC3, 8'h99, 8'hBD, 8'hBD, 8'h99, 8'hC3, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
	8'h00, 8'h00, 8'h1E, 8'h0E, 8'h1A, 8'h32, 8'h78, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'h78, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h3C, 8'h66, 8'h66, 8'h66, 8'h66, 8'h3C, 8'h18, 8'h7E, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h3F, 8'h33, 8'h3F, 8'h30, 8'h30, 8'h30, 8'h30, 8'h70, 8'hF0, 8'hE0, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7F, 8'h63, 8'h7F, 8'h63, 8'h63, 8'h63, 8'h63, 8'h67, 8'hE7, 8'hE6, 8'hC0, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'hDB, 8'h3C, 8'hE7, 8'h3C, 8'hDB, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h80, 8'hC0, 8'hE0, 8'hF0, 8'hF8, 8'hFE, 8'hF8, 8'hF0, 8'hE0, 8'hC0, 8'h80, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h02, 8'h06, 8'h0E, 8'h1E, 8'h3E, 8'hFE, 8'h3E, 8'h1E, 8'h0E, 8'h06, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h3C, 8'h7E, 8'h18, 8'h18, 8'h18, 8'h7E, 8'h3C, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h00, 8'h66, 8'h66, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7F, 8'hDB, 8'hDB, 8'hDB, 8'h7B, 8'h1B, 8'h1B, 8'h1B, 8'h1B, 8'h1B, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h7C, 8'hC6, 8'h60, 8'h38, 8'h6C, 8'hC6, 8'hC6, 8'h6C, 8'h38, 8'h0C, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hFE, 8'hFE, 8'hFE, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h3C, 8'h7E, 8'h18, 8'h18, 8'h18, 8'h7E, 8'h3C, 8'h18, 8'h7E, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h3C, 8'h7E, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h7E, 8'h3C, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h18, 8'h0C, 8'hFE, 8'h0C, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h30, 8'h60, 8'hFE, 8'h60, 8'h30, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC0, 8'hC0, 8'hC0, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h24, 8'h66, 8'hFF, 8'h66, 8'h24, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h10, 8'h38, 8'h38, 8'h7C, 8'h7C, 8'hFE, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'hFE, 8'hFE, 8'h7C, 8'h7C, 8'h38, 8'h38, 8'h10, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h3C, 8'h3C, 8'h3C, 8'h18, 8'h18, 8'h18, 8'h00, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h66, 8'h66, 8'h66, 8'h24, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h6C, 8'h6C, 8'hFE, 8'h6C, 8'h6C, 8'h6C, 8'hFE, 8'h6C, 8'h6C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h18, 8'h18, 8'h7C, 8'hC6, 8'hC2, 8'hC0, 8'h7C, 8'h06, 8'h06, 8'h86, 8'hC6, 8'h7C, 8'h18, 8'h18, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'hC2, 8'hC6, 8'h0C, 8'h18, 8'h30, 8'h60, 8'hC6, 8'h86, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h38, 8'h6C, 8'h6C, 8'h38, 8'h76, 8'hDC, 8'hCC, 8'hCC, 8'hCC, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h30, 8'h30, 8'h30, 8'h60, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h0C, 8'h18, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h18, 8'h0C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h30, 8'h18, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h18, 8'h30, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h66, 8'h3C, 8'hFF, 8'h3C, 8'h66, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'h7E, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'h18, 8'h30, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h7E, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h02, 8'h06, 8'h0C, 8'h18, 8'h30, 8'h60, 8'hC0, 8'h80, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'hCE, 8'hDE, 8'hF6, 8'hE6, 8'hC6, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h38, 8'h78, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h7E, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'h06, 8'h0C, 8'h18, 8'h30, 8'h60, 8'hC0, 8'hC6, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'h06, 8'h06, 8'h3C, 8'h06, 8'h06, 8'h06, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h0C, 8'h1C, 8'h3C, 8'h6C, 8'hCC, 8'hFE, 8'h0C, 8'h0C, 8'h0C, 8'h1E, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFE, 8'hC0, 8'hC0, 8'hC0, 8'hFC, 8'h06, 8'h06, 8'h06, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h38, 8'h60, 8'hC0, 8'hC0, 8'hFC, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFE, 8'hC6, 8'h06, 8'h06, 8'h0C, 8'h18, 8'h30, 8'h30, 8'h30, 8'h30, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'hC6, 8'h7C, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'hC6, 8'h7E, 8'h06, 8'h06, 8'h06, 8'h0C, 8'h78, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h18, 8'h18, 8'h30, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h06, 8'h0C, 8'h18, 8'h30, 8'h60, 8'h30, 8'h18, 8'h0C, 8'h06, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h7E, 8'h00, 8'h00, 8'h7E, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h60, 8'h30, 8'h18, 8'h0C, 8'h06, 8'h0C, 8'h18, 8'h30, 8'h60, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'h0C, 8'h18, 8'h18, 8'h18, 8'h00, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'hC6, 8'hDE, 8'hDE, 8'hDE, 8'hDC, 8'hC0, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h10, 8'h38, 8'h6C, 8'hC6, 8'hC6, 8'hFE, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFC, 8'h66, 8'h66, 8'h66, 8'h7C, 8'h66, 8'h66, 8'h66, 8'h66, 8'hFC, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h3C, 8'h66, 8'hC2, 8'hC0, 8'hC0, 8'hC0, 8'hC0, 8'hC2, 8'h66, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hF8, 8'h6C, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h6C, 8'hF8, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFE, 8'h66, 8'h62, 8'h68, 8'h78, 8'h68, 8'h60, 8'h62, 8'h66, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFE, 8'h66, 8'h62, 8'h68, 8'h78, 8'h68, 8'h60, 8'h60, 8'h60, 8'hF0, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h3C, 8'h66, 8'hC2, 8'hC0, 8'hC0, 8'hDE, 8'hC6, 8'hC6, 8'h66, 8'h3A, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hFE, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h3C, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h1E, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'hCC, 8'hCC, 8'hCC, 8'h78, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hE6, 8'h66, 8'h66, 8'h6C, 8'h78, 8'h78, 8'h6C, 8'h66, 8'h66, 8'hE6, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hF0, 8'h60, 8'h60, 8'h60, 8'h60, 8'h60, 8'h60, 8'h62, 8'h66, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC3, 8'hE7, 8'hFF, 8'hFF, 8'hDB, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC6, 8'hE6, 8'hF6, 8'hFE, 8'hDE, 8'hCE, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFC, 8'h66, 8'h66, 8'h66, 8'h7C, 8'h60, 8'h60, 8'h60, 8'h60, 8'hF0, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hD6, 8'hDE, 8'h7C, 8'h0C, 8'h0E, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFC, 8'h66, 8'h66, 8'h66, 8'h7C, 8'h6C, 8'h66, 8'h66, 8'h66, 8'hE6, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'h60, 8'h38, 8'h0C, 8'h06, 8'hC6, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFF, 8'hDB, 8'h99, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'h66, 8'h3C, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'hDB, 8'hDB, 8'hFF, 8'h66, 8'h66, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC3, 8'hC3, 8'h66, 8'h3C, 8'h18, 8'h18, 8'h3C, 8'h66, 8'hC3, 8'hC3, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hC3, 8'hC3, 8'hC3, 8'h66, 8'h3C, 8'h18, 8'h18, 8'h18, 8'h18, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hFF, 8'hC3, 8'h86, 8'h0C, 8'h18, 8'h30, 8'h60, 8'hC1, 8'hC3, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h3C, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h30, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h80, 8'hC0, 8'hE0, 8'h70, 8'h38, 8'h1C, 8'h0E, 8'h06, 8'h02, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h3C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h0C, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h10, 8'h38, 8'h6C, 8'hC6, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hFF, 8'h00, 8'h00,
	8'h30, 8'h30, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h78, 8'h0C, 8'h7C, 8'hCC, 8'hCC, 8'hCC, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'hE0, 8'h60, 8'h60, 8'h78, 8'h6C, 8'h66, 8'h66, 8'h66, 8'h66, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC0, 8'hC0, 8'hC0, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h1C, 8'h0C, 8'h0C, 8'h3C, 8'h6C, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h7C, 8'hC6, 8'hFE, 8'hC0, 8'hC0, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h38, 8'h6C, 8'h64, 8'h60, 8'hF0, 8'h60, 8'h60, 8'h60, 8'h60, 8'hF0, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h76, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'h7C, 8'h0C, 8'hCC, 8'h78, 8'h00,
	8'h00, 8'h00, 8'hE0, 8'h60, 8'h60, 8'h6C, 8'h76, 8'h66, 8'h66, 8'h66, 8'h66, 8'hE6, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h18, 8'h00, 8'h38, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h06, 8'h06, 8'h00, 8'h0E, 8'h06, 8'h06, 8'h06, 8'h06, 8'h06, 8'h06, 8'h66, 8'h66, 8'h3C, 8'h00,
	8'h00, 8'h00, 8'hE0, 8'h60, 8'h60, 8'h66, 8'h6C, 8'h78, 8'h78, 8'h6C, 8'h66, 8'hE6, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h38, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h3C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hE6, 8'hFF, 8'hDB, 8'hDB, 8'hDB, 8'hDB, 8'hDB, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hDC, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h7C, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hDC, 8'h66, 8'h66, 8'h66, 8'h66, 8'h66, 8'h7C, 8'h60, 8'h60, 8'hF0, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h76, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'h7C, 8'h0C, 8'h0C, 8'h1E, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hDC, 8'h76, 8'h66, 8'h60, 8'h60, 8'h60, 8'hF0, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h7C, 8'hC6, 8'h60, 8'h38, 8'h0C, 8'hC6, 8'h7C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h10, 8'h30, 8'h30, 8'hFC, 8'h30, 8'h30, 8'h30, 8'h30, 8'h36, 8'h1C, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'hCC, 8'h76, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC3, 8'hC3, 8'hC3, 8'hC3, 8'h66, 8'h3C, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC3, 8'hC3, 8'hC3, 8'hDB, 8'hDB, 8'hFF, 8'h66, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC3, 8'h66, 8'h3C, 8'h18, 8'h3C, 8'h66, 8'hC3, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'hC6, 8'h7E, 8'h06, 8'h0C, 8'hF8, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hFE, 8'hCC, 8'h18, 8'h30, 8'h60, 8'hC6, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h0E, 8'h18, 8'h18, 8'h18, 8'h70, 8'h18, 8'h18, 8'h18, 8'h18, 8'h0E, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h18, 8'h18, 8'h18, 8'h18, 8'h00, 8'h18, 8'h18, 8'h18, 8'h18, 8'h18, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h70, 8'h18, 8'h18, 8'h18, 8'h0E, 8'h18, 8'h18, 8'h18, 8'h18, 8'h70, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h76, 8'hDC, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
	8'h00, 8'h00, 8'h00, 8'h00, 8'h10, 8'h38, 8'h6C, 8'hC6, 8'hC6, 8'hC6, 8'hFE, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

	assign data = ROM[addr];

endmodule
