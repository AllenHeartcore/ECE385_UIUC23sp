create_clock -period "10.0 MHz" [get_ports ADC_CLK_10]
create_clock -period "50.0 MHz" [get_ports MAX10_CLK1_50]
create_clock -period "50.0 MHz" [get_ports MAX10_CLK2_50]
create_generated_clock -source [get_pins { u0|altpll_0|sd1|pll7|clk[1] }] -name clk_dram_ext [get_ports {DRAM_CLK}]
derive_pll_clocks
derive_clock_uncertainty

set_input_delay -max -clock clk_dram_ext 5.9 [get_ports DRAM_DQ*]
set_input_delay -min -clock clk_dram_ext 3.0 [get_ports DRAM_DQ*]
set_multicycle_path -from [get_clocks {clk_dram_ext}] -to [get_clocks { u0|altpll_0|sd1|pll7|clk[0] }] -setup 2
set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_DQ* DRAM_*DQM}]
set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_DQ* DRAM_*DQM}]
set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]
set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]

set_false_path -from [get_ports {KEY* SW* DRAM* altera*}] -to *
set_false_path -from * -to [get_ports {LEDR* HEX* DRAM* altera*}]
