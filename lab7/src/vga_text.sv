`define NUM_REGS	601
`define CTRL_REG	600


module VGATextModeController (
	input  logic clk, reset,
	input  logic avl_read, avl_write, avl_cs,
	input  logic [ 3:0] avl_byte_en,
	input  logic [ 9:0] avl_addr,
	input  logic [31:0] avl_writedata,
	output logic [31:0] avl_readdata,
	output logic [ 3:0] red, green, blue,
	output logic hs, vs);


	/* clk, reset, avl_* -> [Regs] -> avl_readdata */

	logic [31:0] regs [`NUM_REGS];

	always_ff @ (posedge clk) begin

		if (reset) begin
			for (int i = 0; i < `NUM_REGS; i = i + 1)
				regs[i] <= 32'h0;

		end else if (avl_cs && avl_read)  begin
			avl_readdata <= regs[avl_addr];

		end else if (avl_cs && avl_write) begin
			if (avl_byte_en[0]) regs[avl_addr][ 7: 0] <= avl_writedata[ 7: 0];
			if (avl_byte_en[1]) regs[avl_addr][15: 8] <= avl_writedata[15: 8];
			if (avl_byte_en[2]) regs[avl_addr][23:16] <= avl_writedata[23:16];
			if (avl_byte_en[3]) regs[avl_addr][31:24] <= avl_writedata[31:24];

		end else
			avl_readdata <= 32'hZ;

	end


	/* clk, reset -> [VGACtrl] -> DrawX, DrawY, hs, vs */

	logic [10:0] rom_addr;
	logic [ 7:0] rom_data;
	logic [ 9:0] DrawX, DrawY;
	logic blank;

	VGACtrl vga (.Clk(clk), .Reset(reset), .DrawX, .DrawY, .hs, .vs, .blank);
	FontROM rom (.addr(rom_addr), .data(rom_data));


	/* clk, DrawX, DrawY -> [ColorMapper] -> red, green, blue */

	logic [11:0] CharIdx;
	logic [ 7:0] Char;
	logic Pixel, Inv;

	always_comb begin
		CharIdx = DrawY[9:4] * 80 + DrawX[9:3];
		case (CharIdx[1:0])
			2'b00: Char = regs[CharIdx[11:2]][ 7: 0];
			2'b01: Char = regs[CharIdx[11:2]][15: 8];
			2'b10: Char = regs[CharIdx[11:2]][23:16];
			2'b11: Char = regs[CharIdx[11:2]][31:24];
		endcase
		rom_addr = Char << 4 | DrawY[3:0];
		Pixel    = rom_data[~DrawX[2:0]];
		Inv      = Char[7];
	end

	always_ff @ (posedge clk) begin
		if (reset || blank)		{red, green, blue} <= 12'h0;
		else if (Pixel ^ Inv)	{red, green, blue} <= regs[`CTRL_REG][24:13];
		else					{red, green, blue} <= regs[`CTRL_REG][12: 1];
	end


endmodule
