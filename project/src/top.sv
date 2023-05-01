module ece385proj (
	input  logic MAX10_CLK1_50, MAX10_CLK2_50,
	input  logic [ 1:0] KEY,
	output logic [ 9:0] LEDR,
	output logic [ 6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

	inout  wire  [15:0] DRAM_DQ,
	output logic [12:0] DRAM_ADDR,
	output logic [ 1:0] DRAM_BA,
	output logic DRAM_LDQM, DRAM_UDQM, DRAM_RAS_N, DRAM_CAS_N,
	output logic DRAM_CKE,  DRAM_CLK,  DRAM_WE_N,  DRAM_CS_N,

	output logic [ 3:0] VGA_R, VGA_G, VGA_B,
	output logic VGA_HS, VGA_VS,

	inout  logic [15:0] ARDUINO_IO,
	inout  logic ARDUINO_RESET_N);


	/* Arduino IO assignments
	 * [15-14]: I2C_SCL,  I2C_SDA,
	 * [13-10]: SPI_SCLK, SPI_MISO,  SPI_MOSI, SPI_CS_N,
	 * [ 9- 6]: USB_IRQ,  USB_GPX,   USB_RST,  uSD_CS,
	 * [ 5- 0]: I2S_SCLK, I2S_LRCLK, I2S_MCLK, I2S_DIN, I2S_DOUT, (unused)
	 */

	logic i2c_serial_scl_in, i2c_serial_scl_oe;
	logic i2c_serial_sda_in, i2c_serial_sda_oe;
	logic SPI_CS_N, SPI_SCLK, SPI_MISO, SPI_MOSI;
	logic USB_GPX, USB_IRQ, USB_RST;
	logic I2S_SCLK, I2S_LRCLK, I2S_DIN, I2S_DOUT;
	logic [ 1:0] mclk_ctr;
	logic [23:0] hexnum;

	assign ARDUINO_IO[15:1] = {
		i2c_serial_scl_oe ? 1'b0 : 1'bZ,
		i2c_serial_sda_oe ? 1'b0 : 1'bZ,
		SPI_SCLK, 1'bZ, SPI_MOSI, SPI_CS_N,
		1'bZ, 1'bZ, USB_RST, 1'b1,
		1'bZ, 1'bZ, mclk_ctr[1], I2S_DIN, 1'bZ};

	assign ARDUINO_RESET_N   = USB_RST;
	assign i2c_serial_scl_in = ARDUINO_IO[15];
	assign i2c_serial_sda_in = ARDUINO_IO[14];
	assign SPI_MISO  = ARDUINO_IO[12];
	assign USB_IRQ   = ARDUINO_IO[9];
	assign I2S_SCLK  = ARDUINO_IO[5];
	assign I2S_LRCLK = ARDUINO_IO[4];
	assign I2S_DOUT  = ARDUINO_IO[1];
	assign USB_GPX   = 1'b0;

	always_ff @ (posedge MAX10_CLK2_50) begin
		mclk_ctr <= mclk_ctr + 2'd1;
	end


	HexDriver hexdriver[6] (hexnum, {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0});

	proj_soc m_proj_soc (
		.clk_clk(MAX10_CLK1_50),
		.reset_reset_n(1'b1),

		.hex_export(hexnum),
		.led_export(LEDR),
		.key_export(KEY),

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

		.spi_SS_n(SPI_CS_N),
		.spi_SCLK(SPI_SCLK),
		.spi_MOSI(SPI_MOSI),
		.spi_MISO(SPI_MISO),

		.usb_irq_export(USB_IRQ),
		.usb_gpx_export(USB_GPX),
		.usb_rst_export(USB_RST),

		.i2c_serial_scl_in,
		.i2c_serial_scl_oe,
		.i2c_serial_sda_in,
		.i2c_serial_sda_oe,

		.i2s_port_sclk(I2S_SCLK),
		.i2s_port_lrclk(I2S_LRCLK),
		.i2s_port_din(I2S_DIN),
		.i2s_port_dout(I2S_DOUT));


endmodule
