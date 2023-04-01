module VGATextModeController (
	input  logic clk, reset,
	input  logic avl_read, avl_write, avl_cs,
	input  logic [ 3:0] avl_byte_en,
	input  logic [11:0] avl_addr,
	input  logic [31:0] avl_writedata,
	output logic [31:0] avl_readdata,
	output logic [ 3:0] red, green, blue,
	output logic hs, vs);


	logic [10:0] rom_addr;
	logic [ 7:0] rom_data;
	logic [31:0] ram_rdata_a, ram_rdata_b, reg_rdata;
	logic [31:0] palette [8];
	logic reg_access;

	logic [ 9:0] DrawX, DrawY;
	logic [11:0] CharIdx;
	logic [ 6:0] Char;
	logic [ 3:0] ColorIdxFG, ColorIdxBG;
	logic [11:0] ColorFG, ColorBG;
	logic blank, Pixel, Inv;


	/* clk, avl_* -> [RAM] -> avl_readdata */

	assign reg_access = avl_addr[11];

	ram ram0 (
		.clock		(clk),

		/* AVL R/W */
		.byteena_a	(avl_byte_en),
		.rden_a		(avl_cs && avl_read  && !reg_access),
		.wren_a		(avl_cs && avl_write && !reg_access),
		.address_a	(avl_addr[10:0]),
		.data_a		(avl_writedata),
		.q_a		(ram_rdata_a),

		/* Char Dedicated */
		.rden_b		(1'b1),
		.wren_b		(1'b0),
		.address_b	(CharIdx[11:1]),
		.data_b		(32'h0),
		.q_b		(ram_rdata_b)
	);

	always_ff @ (posedge clk) begin
		if (reg_access) begin

			if (avl_cs && avl_read)  begin
				reg_rdata <= palette[avl_addr[2:0]];

			end else if (avl_cs && avl_write) begin
				if (avl_byte_en[0]) palette[avl_addr[2:0]][ 7: 0] <= avl_writedata[ 7: 0];
				if (avl_byte_en[1]) palette[avl_addr[2:0]][15: 8] <= avl_writedata[15: 8];
				if (avl_byte_en[2]) palette[avl_addr[2:0]][23:16] <= avl_writedata[23:16];
				if (avl_byte_en[3]) palette[avl_addr[2:0]][31:24] <= avl_writedata[31:24];
			end

		end
	end

	always_comb begin
		if (reg_access) avl_readdata = reg_rdata;
		else			avl_readdata = ram_rdata_a;
	end


	/* clk, reset -> [VGACtrl] -> DrawX, DrawY, hs, vs */

	VGACtrl vga (.Clk(clk), .Reset(reset), .DrawX, .DrawY, .hs, .vs, .blank);
	FontROM rom (.addr(rom_addr), .data(rom_data));


	/* clk, DrawX, DrawY -> [ColorMapper] -> red, green, blue */

	always_comb begin
		CharIdx = DrawY[9:4] * 80 + DrawX[9:3];
		case (CharIdx[0])
			1'b0: {Inv, Char, ColorIdxFG, ColorIdxBG} = ram_rdata_b[15: 0];
			1'b1: {Inv, Char, ColorIdxFG, ColorIdxBG} = ram_rdata_b[31:16];
		endcase
		rom_addr = Char << 4 | DrawY[3:0];
		Pixel    = rom_data[~DrawX[2:0]];

		if (ColorIdxFG[0])	ColorFG = palette[ColorIdxFG[3:1]][24:13];
		else				ColorFG = palette[ColorIdxFG[3:1]][12: 1];
		if (ColorIdxBG[0])	ColorBG = palette[ColorIdxBG[3:1]][24:13];
		else				ColorBG = palette[ColorIdxBG[3:1]][12: 1];
	end

	always_ff @ (posedge clk) begin
		if (reset || blank)		{red, green, blue} <= 12'h0;
		else if (Pixel ^ Inv)	{red, green, blue} <= ColorFG;
		else					{red, green, blue} <= ColorBG;
	end


endmodule
