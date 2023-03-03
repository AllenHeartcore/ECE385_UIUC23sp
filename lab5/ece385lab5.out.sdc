set_time_format -unit ns -decimal_places 3
create_clock -name {Clk} -period 10.000 -waveform { 0.000 10.000 } [get_ports {Clk}]
set_input_delay -add_delay -rise -clock [get_clocks {Clk}] 0.500 [get_ports {Run}]
set_input_delay -add_delay -rise -clock [get_clocks {Clk}] 0.500 [get_ports {Continue}]
set_input_delay -add_delay -rise -clock [get_clocks {Clk}] 0.000 [get_ports {SW*}]
set_output_delay -add_delay -rise -clock [get_clocks {Clk}] 0.000 [get_ports {LED*}]
set_output_delay -add_delay -rise -clock [get_clocks {Clk}] 0.000 [get_ports {HEX*}]
