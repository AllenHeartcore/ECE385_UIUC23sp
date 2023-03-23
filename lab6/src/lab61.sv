module lab61 (
	input  logic MAX10_CLK1_50,
	input  logic [1:0]  KEY,
	input  logic [7:0]  SW,
	output logic [7:0]  LEDR,
	output logic [7:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
	inout  logic [15:0] DRAM_DQ,
	output logic [12:0] DRAM_ADDR,
	output logic [1:0]  DRAM_BA,
	output logic DRAM_LDQM, DRAM_UDQM, DRAM_RAS_N, DRAM_CAS_N,
	output logic DRAM_CKE, DRAM_CLK, DRAM_WE_N, DRAM_CS_N);

	lab6_soc m_lab61_soc (
		.clk_clk         (MAX10_CLK1_50),
		.reset_reset_n   (KEY[0]),
		.key1_wire_export(KEY[1]),
		.sw_wire_export  (SW),
		.led_wire_export (LEDR),
		.hex0_wire_export(HEX0),
		.hex1_wire_export(HEX1),
		.hex2_wire_export(HEX2),
		.hex3_wire_export(HEX3),
		.hex4_wire_export(HEX4),
		.hex5_wire_export(HEX5),
		.sdram_wire_dq   (DRAM_DQ),
		.sdram_wire_addr (DRAM_ADDR),
		.sdram_wire_ba   (DRAM_BA),
		.sdram_wire_dqm  ({DRAM_UDQM, DRAM_LDQM}),
		.sdram_wire_ras_n(DRAM_RAS_N),
		.sdram_wire_cas_n(DRAM_CAS_N),
		.sdram_wire_cke  (DRAM_CKE),
		.sdram_clk_clk   (DRAM_CLK),
		.sdram_wire_we_n (DRAM_WE_N),
		.sdram_wire_cs_n (DRAM_CS_N));

	// Instantiate additional FPGA fabric modules as needed

endmodule
