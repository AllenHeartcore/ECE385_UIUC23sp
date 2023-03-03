`ifndef _TOP_SV
`define _TOP_SV


`include "utils.sv"
// `define FETCH_DEMO
// `define SIMULATION
// `define INSPECT_NET
// `define INSPECT_CTRL

`define TOP_INTERFACE \
	input  logic Run, Continue, Clk, \
	input  logic [9:0]  SW, \
`ifdef SIMULATION \
	`TOGGLE_OUTPUT \
	output logic [15:0] hexval, \
`else \
	output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, \
`endif \
	output logic [9:0]  LED

module SLC3Top (`TOP_INTERFACE);

`ifdef SIMULATION
	SLC3TopSim subject(.*);
`else
	SLC3TopSynth subject(.*);
`endif

endmodule


`endif
