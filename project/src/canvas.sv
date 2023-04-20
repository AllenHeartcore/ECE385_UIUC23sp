module VGACanvas (
	input  logic clk, reset,
	input  logic avl_rden, avl_wren, avl_cs,
	input  logic [5:0] avl_addr,
	input  logic [7:0] avl_wdata,
	output logic [7:0] avl_rdata,
	output logic [3:0] red, green, blue,
	output logic hs, vs);


	/* [Register Arrangement]
	 *
	 * 0x00 - 0x07: |   SCORE   |  ACC  | B | C | D |
	 * 0x08 - 0x0F: | E | F | G | H | I | J | K | L |
	 * 0x10 - 0x17: | M | N | O | P |   | R | S | T |
	 * 0x18 - 0x1F: | U | V | W | X | Y |   |   | 2 |
	 * 0x20 - 0x27: | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 |
	 * 0x28 - 0x2F: |   |   |   |   |   | - | = | [ |
	 * 0x30 - 0x37: |   |   |   | ; |   |   | , | . |
	 * 0x38 - 0x3F: | NPURE | NFAR  | NLOST | NCOMBO|
	 *
	 * ["keystat" Register Format]
	 * | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
	 * |   BRGHT   | COLOR |   NSIZE   |
	 */

	logic [23:0] score;
	logic [15:0] acc, npure, nfar, nlost, ncombo;
	logic [ 7:0] keystat[51];

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
				default: keystat[avl_addr - 6'h05] <= avl_wdata;
			endcase
	end


	/* VGA Text Support */

	logic [10:0] font_rom_addr;
	logic [ 7:0] font_rom_data;
	logic [ 9:0] DrawX, DrawY;
	logic [11:0] CharIdx;
	logic [ 6:0] Char;
	logic pixel_clk, blank, Pixel;

	VGACtrl vga (.Clk(clk), .Reset(reset), .pixel_clk, .DrawX, .DrawY, .hs, .vs, .blank);
	FontROM font_rom (.addr(font_rom_addr), .data(font_rom_data));

	// always_comb begin
	// 	CharIdx = DrawY[9:4] * 80 + DrawX[9:3];
	// 	case (CharIdx[0])
	// 		1'b0: {Inv, Char, ColorIdxFG, ColorIdxBG} = ram_rdata_int[15: 0];
	// 		1'b1: {Inv, Char, ColorIdxFG, ColorIdxBG} = ram_rdata_int[31:16];
	// 	endcase
	// 	font_rom_addr = Char << 4 | DrawY[3:0];
	// 	Pixel    = font_rom_data[~DrawX[2:0]];

	// 	if (ColorIdxFG[0])	ColorFG = palette[ColorIdxFG[3:1]][24:13];
	// 	else				ColorFG = palette[ColorIdxFG[3:1]][12: 1];
	// 	if (ColorIdxBG[0])	ColorBG = palette[ColorIdxBG[3:1]][24:13];
	// 	else				ColorBG = palette[ColorIdxBG[3:1]][12: 1];
	// end

	// always_ff @ (posedge pixel_clk) begin
	// 	if (reset || blank)	{red, green, blue} <= 12'h0;
	// 	else if (Pixel)		{red, green, blue} <= ColorFG;
	// 	else				{red, green, blue} <= ColorBG;
	// end


	/*  --------------------
	 * |        GRID        |	left empty except for boundary w/width 1
	 * |   --------------   |
	 * |  |     GLOW     |  |	"glow" after each touch	0 <= COLOR <= 3
	 * |  |   --------   |  |	brightness				0 <= BRGHT <= 7
	 * |  |  |  NOTE  |  |  |	edge length is 4*NSIZE	0 <= NSIZE <= 7
	 * |  |  | ...... |  |  |
	 * 0  3  7       48 52 55
	 */

`define KBD_X_START 10'd12
`define KBD_X_END   10'd628
`define KBD_Y_START 10'd128
`define KBD_Y_END   10'd352
`define GRID_SIZE   10'd56
`define GLOW_SIZE   10'd50
`define NOTE_SIZE   10'd42
`define GRID_SIZE_HALF `GRID_SIZE / 2
`define GLOW_SIZE_HALF `GLOW_SIZE / 2
`define NOTE_SIZE_HALF `NOTE_SIZE / 2
`define NOTE_SIZE_UNIT `NOTE_SIZE_HALF / 7
`define GLOW_LO `GRID_SIZE_HALF - `GLOW_SIZE_HALF
`define GLOW_HI `GRID_SIZE_HALF + `GLOW_SIZE_HALF - 1
`define NOTE_LO `GRID_SIZE_HALF - `NOTE_SIZE_HALF
`define NOTE_HI `GRID_SIZE_HALF + `NOTE_SIZE_HALF - 1

`define COLOR_TOUCH 12'h222 // white (to be multiplied by BRGHT)
`define COLOR_PURE  12'h121 // green
`define COLOR_FAR   12'h112 // blue
`define COLOR_LOST  12'h211 // red
`define COLOR_GRAY  12'h333
`define COLOR_BLACK 12'h000

	logic [ 9:0] map_rom_addr;
	logic [19:0] map_rom_data;
	logic [ 5:0] DrawYAnch, DrawXRel, DrawYRel;
	logic [ 7:0] DrawXAnch;
	logic [ 5:0] keyidx, nsizeh_curr;
	logic [11:0] keycolor;
	logic [ 2:0] BRGHT, NSIZE;
	logic [ 1:0] COLOR;

	assign map_rom_addr = (DrawY - 128) / 56 * 160 + DrawX[9:2];
	assign {DrawYAnch, DrawXAnch, keyidx} = map_rom_data;

	MapROM map_rom (.addr(map_rom_addr), .data(map_rom_data));

	always_comb begin

		DrawXRel = DrawX - {DrawXAnch, 2'b0};
		DrawYRel = DrawY - {DrawYAnch, 3'b0};
		{BRGHT, COLOR, NSIZE} = keystat[keyidx];
		nsizeh_curr = NSIZE * `NOTE_SIZE_UNIT;

		case (COLOR)
			2'b00: keycolor = BRGHT * `COLOR_TOUCH;
			2'b01: keycolor = BRGHT * `COLOR_LOST;
			2'b10: keycolor = BRGHT * `COLOR_FAR;
			2'b11: keycolor = BRGHT * `COLOR_PURE;
		endcase

	end

	/* [Possible Patterns]
	 * Note entering: NSIZE > 0, COLOR = 0, BRGHT = 7 [NOTE]
	 * (Empty) touch: NSIZE = 0, COLOR = 0, BRGHT > 0        [GLOW]
	 * Lost exiting:  NSIZE > 0, COLOR = 1, BRGHT > 0 [NOTE]
	 * Far  exiting:  NSIZE > 0, COLOR = 2, BRGHT > 0 [NOTE] [GLOW]
	 * Pure exiting:  NSIZE > 0, COLOR = 3, BRGHT > 0 [NOTE] [GLOW]
	 */

	always_ff @ (posedge pixel_clk) begin

		if (DrawX >= `KBD_X_START && DrawX < `KBD_X_END &&
			DrawY >= `KBD_Y_START && DrawY < `KBD_Y_END &&
			map_rom_data != 20'hFFFFF) begin

			if ( (
				DrawXRel >= `NOTE_LO && DrawXRel <= `NOTE_HI &&
				(DrawYRel == `NOTE_LO || DrawYRel == `NOTE_HI)
			) || (
				DrawYRel >= `NOTE_LO && DrawYRel <= `NOTE_HI &&
				(DrawXRel == `NOTE_LO || DrawXRel == `NOTE_HI)
			) )
				{red, green, blue} <= `COLOR_GRAY;		// note boundary

			else if (
				DrawXRel >= `GRID_SIZE_HALF - nsizeh_curr &&
				DrawXRel <  `GRID_SIZE_HALF + nsizeh_curr &&
				DrawYRel >= `GRID_SIZE_HALF - nsizeh_curr &&
				DrawYRel <  `GRID_SIZE_HALF + nsizeh_curr
			)
				{red, green, blue} <= keycolor;			// enlarging note

			else if ( (
				DrawXRel >= `GLOW_LO && DrawXRel <= `GLOW_HI &&
				DrawYRel >= `GLOW_LO && DrawYRel <= `GLOW_HI	// inside glow area
			) && (
				DrawXRel <  `NOTE_LO || DrawXRel >  `NOTE_HI ||
				DrawYRel <  `NOTE_LO || DrawYRel >  `NOTE_HI	// outside note area
			) && (
				(NSIZE == 0 && COLOR == 0) ||			// empty touch OR
				(NSIZE >  0 && COLOR >  1)				// exiting note
			) )
				{red, green, blue} <= keycolor;			// fading glow

			else
				{red, green, blue} <= `COLOR_BLACK;		// empty

		end else
			{red, green, blue} <= `COLOR_BLACK;			// out of range
	end


endmodule
