`include "utils.sv"


module layer_kbd (
	input  logic pixel_clk,
	input  logic [ 7:0] keystat[51],
	input  logic [ 9:0] DrawX, DrawY,
	output logic [11:0] color);

	/*     [Keyboard Map]
	 *  --------------------
	 * |        GRID        |	left empty except for boundary w/width 1
	 * |   --------------   |
	 * |  |     GLOW     |  |	"glow" after each touch	0 <= COLOR <= 3
	 * |  |   --------   |  |	brightness				0 <= BRGHT <= 7
	 * |  |  |  NOTE  |  |  |	edge length is 4*NSIZE	0 <= NSIZE <= 7
	 * |  |  | ...... |  |  |
	 * 0  3  7       48 52 55
	 */

`define GRID_SIZE       10'd56
`define GLOW_SIZE       10'd50
`define NOTE_SIZE       10'd42
`define GRID_SIZE_HALF  10'd28
`define GLOW_SIZE_HALF  10'd25
`define NOTE_SIZE_HALF  10'd21
`define NOTE_SIZE_UNIT  10'd3
`define GLOW_LO `GRID_SIZE_HALF - `GLOW_SIZE_HALF
`define GLOW_HI `GRID_SIZE_HALF + `GLOW_SIZE_HALF - 1
`define NOTE_LO `GRID_SIZE_HALF - `NOTE_SIZE_HALF
`define NOTE_HI `GRID_SIZE_HALF + `NOTE_SIZE_HALF - 1

`define COLOR_TOUCH 12'h222 // white (to be multiplied by BRGHT)
`define COLOR_PURE  12'h121 // green
`define COLOR_FAR   12'h112 // blue
`define COLOR_LOST  12'h211 // red
`define COLOR_WHITE 12'hFFF
`define COLOR_BLACK 12'h000

	logic [ 9:0] rom_addr;
	logic [19:0] rom_data;
	logic [ 5:0] DrawYAnch, DrawXRel, DrawYRel;
	logic [ 7:0] DrawXAnch;
	logic [ 5:0] keyidx, nsizeh_curr;
	logic [11:0] keycolor;
	logic [ 2:0] BRGHT, NSIZE;
	logic [ 1:0] COLOR;

	assign rom_addr = (DrawY - 128) / 56 * 160 + DrawX[9:2];
	assign {DrawYAnch, DrawXAnch, keyidx} = rom_data;

	rom_kbd map_rom (.addr(rom_addr), .data(rom_data));

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

	always_ff @ (posedge pixel_clk) begin

		if (rom_data != 20'hFFFFF) begin

			/* [Possible Patterns]
			 * Note entering: NSIZE > 0, COLOR = 0, BRGHT = 7 [NOTE]
			 * (Empty) touch: NSIZE = 0, COLOR = 0, BRGHT > 0        [GLOW]
			 * Lost exiting:  NSIZE > 0, COLOR = 1, BRGHT > 0 [NOTE]
			 * Far  exiting:  NSIZE > 0, COLOR = 2, BRGHT > 0 [NOTE] [GLOW]
			 * Pure exiting:  NSIZE > 0, COLOR = 3, BRGHT > 0 [NOTE] [GLOW]
			 */

			if ( (
				DrawXRel >= `NOTE_LO && DrawXRel <= `NOTE_HI &&
				(DrawYRel == `NOTE_LO || DrawYRel == `NOTE_HI)
			) || (
				DrawYRel >= `NOTE_LO && DrawYRel <= `NOTE_HI &&
				(DrawXRel == `NOTE_LO || DrawXRel == `NOTE_HI)
			) )
				color <= `COLOR_WHITE;		// note boundary

			else if (
				DrawXRel >= `GRID_SIZE_HALF - nsizeh_curr &&
				DrawXRel <  `GRID_SIZE_HALF + nsizeh_curr &&
				DrawYRel >= `GRID_SIZE_HALF - nsizeh_curr &&
				DrawYRel <  `GRID_SIZE_HALF + nsizeh_curr
			)
				color <= keycolor;			// enlarging note

			else if ( (
				DrawXRel >= `GLOW_LO && DrawXRel <= `GLOW_HI &&
				DrawYRel >= `GLOW_LO && DrawYRel <= `GLOW_HI	// inside glow area
			) && (
				DrawXRel <  `NOTE_LO || DrawXRel >  `NOTE_HI ||
				DrawYRel <  `NOTE_LO || DrawYRel >  `NOTE_HI	// outside note area
			) && (
				(NSIZE == 0 && COLOR == 0) ||	// empty touch OR
				(NSIZE >  0 && COLOR >  1)		// exiting note
			) )
				color <= keycolor;			// fading glow

			else
				color <= `COLOR_BLACK;		// empty

		end else
			color <= `COLOR_BLACK;			// empty
	end

endmodule


/* [rom_kbd Entry Format]
 * |     19-14      |      13-6      |  5-0   |
 * | DrawYAnch[9:4] | DrawXAnch[9:2] | keyidx |
 *
 * Each entry encodes the region assignment of a 56x4 block.
 *
 * [keyidx (keycode - 5) Positions]
 * 26  27  28  29  30  31  32  33  34  40  41
 *   21   3  16  18  23  19   7  13  14  42
 *     17   2   4   5   6   8   9  10  46
 *       22   1  20   0  12  11  49  50
 */


module rom_kbd (
	input  logic [ 9:0] addr,
	output logic [19:0] data);

	localparam [0:639][19:0] ROM = {
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'h400DA, 20'h400DA, 20'h400DA, 20'h400DA, 20'h400DA,
	20'h400DA, 20'h400DA, 20'h400DA, 20'h400DA, 20'h400DA, 20'h400DA, 20'h400DA, 20'h400DA,
	20'h400DA, 20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B,
	20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B, 20'h4045B, 20'h407DC,
	20'h407DC, 20'h407DC, 20'h407DC, 20'h407DC, 20'h407DC, 20'h407DC, 20'h407DC, 20'h407DC,
	20'h407DC, 20'h407DC, 20'h407DC, 20'h407DC, 20'h407DC, 20'h40B5D, 20'h40B5D, 20'h40B5D,
	20'h40B5D, 20'h40B5D, 20'h40B5D, 20'h40B5D, 20'h40B5D, 20'h40B5D, 20'h40B5D, 20'h40B5D,
	20'h40B5D, 20'h40B5D, 20'h40B5D, 20'h40EDE, 20'h40EDE, 20'h40EDE, 20'h40EDE, 20'h40EDE,
	20'h40EDE, 20'h40EDE, 20'h40EDE, 20'h40EDE, 20'h40EDE, 20'h40EDE, 20'h40EDE, 20'h40EDE,
	20'h40EDE, 20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F,
	20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F, 20'h4125F, 20'h415E0,
	20'h415E0, 20'h415E0, 20'h415E0, 20'h415E0, 20'h415E0, 20'h415E0, 20'h415E0, 20'h415E0,
	20'h415E0, 20'h415E0, 20'h415E0, 20'h415E0, 20'h415E0, 20'h41961, 20'h41961, 20'h41961,
	20'h41961, 20'h41961, 20'h41961, 20'h41961, 20'h41961, 20'h41961, 20'h41961, 20'h41961,
	20'h41961, 20'h41961, 20'h41961, 20'h41CE2, 20'h41CE2, 20'h41CE2, 20'h41CE2, 20'h41CE2,
	20'h41CE2, 20'h41CE2, 20'h41CE2, 20'h41CE2, 20'h41CE2, 20'h41CE2, 20'h41CE2, 20'h41CE2,
	20'h41CE2, 20'h42068, 20'h42068, 20'h42068, 20'h42068, 20'h42068, 20'h42068, 20'h42068,
	20'h42068, 20'h42068, 20'h42068, 20'h42068, 20'h42068, 20'h42068, 20'h42068, 20'h423E9,
	20'h423E9, 20'h423E9, 20'h423E9, 20'h423E9, 20'h423E9, 20'h423E9, 20'h423E9, 20'h423E9,
	20'h423E9, 20'h423E9, 20'h423E9, 20'h423E9, 20'h423E9, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295,
	20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295, 20'h5C295,
	20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603,
	20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603, 20'h5C603, 20'h5C990, 20'h5C990,
	20'h5C990, 20'h5C990, 20'h5C990, 20'h5C990, 20'h5C990, 20'h5C990, 20'h5C990, 20'h5C990,
	20'h5C990, 20'h5C990, 20'h5C990, 20'h5C990, 20'h5CD12, 20'h5CD12, 20'h5CD12, 20'h5CD12,
	20'h5CD12, 20'h5CD12, 20'h5CD12, 20'h5CD12, 20'h5CD12, 20'h5CD12, 20'h5CD12, 20'h5CD12,
	20'h5CD12, 20'h5CD12, 20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097,
	20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097, 20'h5D097,
	20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413,
	20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413, 20'h5D413, 20'h5D787, 20'h5D787,
	20'h5D787, 20'h5D787, 20'h5D787, 20'h5D787, 20'h5D787, 20'h5D787, 20'h5D787, 20'h5D787,
	20'h5D787, 20'h5D787, 20'h5D787, 20'h5D787, 20'h5DB0D, 20'h5DB0D, 20'h5DB0D, 20'h5DB0D,
	20'h5DB0D, 20'h5DB0D, 20'h5DB0D, 20'h5DB0D, 20'h5DB0D, 20'h5DB0D, 20'h5DB0D, 20'h5DB0D,
	20'h5DB0D, 20'h5DB0D, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E,
	20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E, 20'h5DE8E,
	20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A,
	20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A, 20'h5E22A, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'h78451, 20'h78451, 20'h78451, 20'h78451, 20'h78451, 20'h78451, 20'h78451,
	20'h78451, 20'h78451, 20'h78451, 20'h78451, 20'h78451, 20'h78451, 20'h78451, 20'h787C2,
	20'h787C2, 20'h787C2, 20'h787C2, 20'h787C2, 20'h787C2, 20'h787C2, 20'h787C2, 20'h787C2,
	20'h787C2, 20'h787C2, 20'h787C2, 20'h787C2, 20'h787C2, 20'h78B44, 20'h78B44, 20'h78B44,
	20'h78B44, 20'h78B44, 20'h78B44, 20'h78B44, 20'h78B44, 20'h78B44, 20'h78B44, 20'h78B44,
	20'h78B44, 20'h78B44, 20'h78B44, 20'h78EC5, 20'h78EC5, 20'h78EC5, 20'h78EC5, 20'h78EC5,
	20'h78EC5, 20'h78EC5, 20'h78EC5, 20'h78EC5, 20'h78EC5, 20'h78EC5, 20'h78EC5, 20'h78EC5,
	20'h78EC5, 20'h79246, 20'h79246, 20'h79246, 20'h79246, 20'h79246, 20'h79246, 20'h79246,
	20'h79246, 20'h79246, 20'h79246, 20'h79246, 20'h79246, 20'h79246, 20'h79246, 20'h795C8,
	20'h795C8, 20'h795C8, 20'h795C8, 20'h795C8, 20'h795C8, 20'h795C8, 20'h795C8, 20'h795C8,
	20'h795C8, 20'h795C8, 20'h795C8, 20'h795C8, 20'h795C8, 20'h79949, 20'h79949, 20'h79949,
	20'h79949, 20'h79949, 20'h79949, 20'h79949, 20'h79949, 20'h79949, 20'h79949, 20'h79949,
	20'h79949, 20'h79949, 20'h79949, 20'h79CCA, 20'h79CCA, 20'h79CCA, 20'h79CCA, 20'h79CCA,
	20'h79CCA, 20'h79CCA, 20'h79CCA, 20'h79CCA, 20'h79CCA, 20'h79CCA, 20'h79CCA, 20'h79CCA,
	20'h79CCA, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E,
	20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'h7A06E, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'h94616, 20'h94616, 20'h94616, 20'h94616, 20'h94616, 20'h94616, 20'h94616, 20'h94616,
	20'h94616, 20'h94616, 20'h94616, 20'h94616, 20'h94616, 20'h94616, 20'h94981, 20'h94981,
	20'h94981, 20'h94981, 20'h94981, 20'h94981, 20'h94981, 20'h94981, 20'h94981, 20'h94981,
	20'h94981, 20'h94981, 20'h94981, 20'h94981, 20'h94D14, 20'h94D14, 20'h94D14, 20'h94D14,
	20'h94D14, 20'h94D14, 20'h94D14, 20'h94D14, 20'h94D14, 20'h94D14, 20'h94D14, 20'h94D14,
	20'h94D14, 20'h94D14, 20'h95080, 20'h95080, 20'h95080, 20'h95080, 20'h95080, 20'h95080,
	20'h95080, 20'h95080, 20'h95080, 20'h95080, 20'h95080, 20'h95080, 20'h95080, 20'h95080,
	20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C,
	20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C, 20'h9540C, 20'h9578B, 20'h9578B,
	20'h9578B, 20'h9578B, 20'h9578B, 20'h9578B, 20'h9578B, 20'h9578B, 20'h9578B, 20'h9578B,
	20'h9578B, 20'h9578B, 20'h9578B, 20'h9578B, 20'h95B31, 20'h95B31, 20'h95B31, 20'h95B31,
	20'h95B31, 20'h95B31, 20'h95B31, 20'h95B31, 20'h95B31, 20'h95B31, 20'h95B31, 20'h95B31,
	20'h95B31, 20'h95B31, 20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2,
	20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2, 20'h95EB2,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF,
	20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF, 20'hFFFFF};

	assign data = ROM[addr];

endmodule
