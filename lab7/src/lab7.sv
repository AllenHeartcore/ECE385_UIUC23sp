module Lab7 (
	input  logic MAX10_CLK1_50,
	inout  logic [15:0] DRAM_DQ,
	output logic [12:0] DRAM_ADDR,
	output logic [ 1:0] DRAM_BA,
	output logic DRAM_CLK,  DRAM_CKE,  DRAM_WE_N,  DRAM_CS_N,
	output logic DRAM_LDQM, DRAM_UDQM, DRAM_RAS_N, DRAM_CAS_N,
	output logic [ 3:0] VGA_R, VGA_G, VGA_B,
	output logic VGA_HS, VGA_VS);


	lab7_soc m_lab7_soc (
		.clk_clk(MAX10_CLK1_50),
		.reset_reset_n(1'b1),
		.altpll_0_locked_conduit_export(),
		.altpll_0_phasedone_conduit_export(),
		.altpll_0_areset_conduit_export(),

		.sdram_clk_clk   (DRAM_CLK),
		.sdram_wire_cke  (DRAM_CKE),
		.sdram_wire_we_n (DRAM_WE_N),
		.sdram_wire_cs_n (DRAM_CS_N),
		.sdram_wire_dq   (DRAM_DQ),
		.sdram_wire_addr (DRAM_ADDR),
		.sdram_wire_ba   (DRAM_BA),
		.sdram_wire_ras_n(DRAM_RAS_N),
		.sdram_wire_cas_n(DRAM_CAS_N),
		.sdram_wire_dqm  ({DRAM_UDQM, DRAM_LDQM}),

		.vga_port_red  (VGA_R),
		.vga_port_green(VGA_G),
		.vga_port_blue (VGA_B),
		.vga_port_hs   (VGA_HS),
		.vga_port_vs   (VGA_VS));


endmodule
