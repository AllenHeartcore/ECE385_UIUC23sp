module ece385proj (
	input  logic MAX10_CLK1_50,
	input  logic [ 1:0] KEY,
	output logic [ 7:0] LEDR,
	output logic [ 7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

	inout  logic [15:0] DRAM_DQ,
	output logic [12:0] DRAM_ADDR,
	output logic [ 1:0] DRAM_BA,
	output logic DRAM_LDQM, DRAM_UDQM, DRAM_RAS_N, DRAM_CAS_N,
	output logic DRAM_CKE,  DRAM_CLK,  DRAM_WE_N,  DRAM_CS_N,

	output logic [ 3:0] VGA_R, VGA_G, VGA_B,
	output logic VGA_HS, VGA_VS,

	inout  logic [15:0] ARDUINO_IO,
	inout  logic ARDUINO_RESET_N);


	logic USB_GPX, USB_IRQ, USB_RST;
	logic SPI0_CS_N, SPI0_SCLK, SPI0_MISO, SPI0_MOSI;
	logic [ 9:0] DrawX, DrawY, BallX, BallY, BallS;
	logic [ 7:0] keycode;
	logic [ 1:0] signs, hundreds;
	logic [15:0] hexnum;

	assign ARDUINO_IO[13:6] = {SPI0_SCLK, 1'bZ, SPI0_MOSI, SPI0_CS_N, 1'bZ, 1'bZ, USB_RST, 1'b1};
	assign ARDUINO_RESET_N = USB_RST;
	assign SPI0_MISO = ARDUINO_IO[12];
	assign USB_IRQ = ARDUINO_IO[9];
	assign USB_GPX = 1'b0;

	HexDriver hexdriver[4] (hexnum, {HEX4[6:0], HEX3[6:0], HEX1[6:0], HEX0[6:0]});
	assign {HEX4[7], HEX3[7], HEX1[7], HEX0[7]} = 4'b1111;
	assign HEX5 = {1'b1, ~signs[1], 3'b111, ~hundreds[1], ~hundreds[1], 1'b1};
	assign HEX2 = {1'b1, ~signs[0], 3'b111, ~hundreds[0], ~hundreds[0], 1'b1};


	proj_soc m_proj_soc (
		.clk_clk(MAX10_CLK1_50),
		.reset_reset_n(1'b1),
		.altpll_0_locked_conduit_export(),
		.altpll_0_phasedone_conduit_export(),
		.altpll_0_areset_conduit_export(),

		.hex_digits_export(hexnum),
		.leds_export({hundreds, signs, LEDR}),
		.key_external_connection_export(KEY),

		.sdram_clk_clk   (DRAM_CLK),
		.sdram_wire_dq   (DRAM_DQ),
		.sdram_wire_addr (DRAM_ADDR),
		.sdram_wire_ba   (DRAM_BA),
		.sdram_wire_dqm  ({DRAM_UDQM, DRAM_LDQM}),
		.sdram_wire_ras_n(DRAM_RAS_N),
		.sdram_wire_cas_n(DRAM_CAS_N),
		.sdram_wire_cke  (DRAM_CKE),
		.sdram_wire_we_n (DRAM_WE_N),
		.sdram_wire_cs_n (DRAM_CS_N),

		.vga_port_red  (VGA_R),
		.vga_port_green(VGA_G),
		.vga_port_blue (VGA_B),
		.vga_port_hs   (VGA_HS),
		.vga_port_vs   (VGA_VS),

		.spi0_SS_n(SPI0_CS_N),
		.spi0_SCLK(SPI0_SCLK),
		.spi0_MOSI(SPI0_MOSI),
		.spi0_MISO(SPI0_MISO),

		.keycode_export(keycode),
		.usb_irq_export(USB_IRQ),
		.usb_gpx_export(USB_GPX),
		.usb_rst_export(USB_RST));


endmodule
