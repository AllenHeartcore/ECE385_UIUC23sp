`include "top.sv"
`include "utils.sv"
`define SEXT(x, digit) {{(16-digit){x[digit-1]}}, x[digit-1:0]}


module SLC3 (`TOP_INTERFACE,
	input  logic Reset,
	input  logic [15:0] data_from_SRAM,
	output logic rden, wren,
	output logic [15:0] addr, data_to_SRAM);

	logic BEN, MIO_EN;
	logic [3:0]  hexvals[3:0];
	logic [15:0] data_to_CPU;
`ifdef SIMULATION
	`ifndef INSPECT_CTRL
		`INTERNAL_CTRL
	`endif
	assign hexval = {hexvals[3], hexvals[2], hexvals[1], hexvals[0]};
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
`else
	`INTERNAL_REG
	`INTERNAL_CTRL
`endif

	assign addr = MAR;
	assign MIO_EN = rden;

	Datapath datapath (.*);
	ISDU state_controller (.*,
		.Opcode(IR[15:12]), .IR_5(IR[5]), .IR_11(IR[11]));
	Mem2IO memory_subsystem (.*, .data_from_CPU(MDR));

`ifdef FETCH_DEMO
	HexDriver hdarr_h[3:0] ({IR[15:12], IR[11:8], IR[7:4], IR[3:0]},
		{HEX5, HEX4, HEX3, HEX2});
`else
	HexDriver hdarr_h[3:0] (hexvals, {HEX5, HEX4, HEX3, HEX2});
`endif
	HexDriver hdarr_l[1:0] ({SW[7:4], SW[3:0]}, {HEX1, HEX0});

endmodule


module Datapath (
	input  logic Reset, Clk, MIO_EN,
	input  logic [15:0] data_to_CPU,
	`INPUT_CTRL
`ifdef SIMULATION
	`ifdef INSPECT_NET
		`OUTPUT_NET
	`endif
`endif
	`OUTPUT_REG
	output logic BEN,
	output logic [9:0]  LED);

	/* Notes on the naming rules
	 * For MUXes:
	 * - "MUX4 #(16) ", etc. are modules
	 * - "PCMUX", etc. (ALLCAPS) are ctrl signals
	 * - "pcmux", etc. (lowercase) are instances
	 * - "pcmux_out", etc. (*_out) are wires
	 * For registers:
	 * - "PC", etc. (ALLCAPS) are wires
	 * - "pc", etc. (lowercase) are instances */

`ifdef SIMULATION
	`ifndef INSPECT_NET
		`INTERNAL_NET
	`endif
`else
	`INTERNAL_NET
`endif

	assign cc_in_n = bus_out[15];
	assign cc_in_z = bus_out === 16'b0;
	assign cc_in_p = bus_out[15] === 0 & bus_out !== 16'b0;
	assign ben_in  = (CC_N & IR[11]) | (CC_Z & IR[10]) | (CC_P & IR[9]);
	assign adder_out = addr1mux_out + addr2mux_out;

	Bus 	   bus      (.out(bus_out), .in1(PC), .in2(marmux_out), .in3(MDR), .in4(alu_out),
		.gates({GatePC, GateMARMUX, GateMDR, GateALU}));
	RegFile    regfile  (.*, .regs(REG), .out1(sr1_out), .out2(sr2_out), .in(bus_out),
		.DR(drmux_out), .SR1(sr1mux_out), .SR2(IR[2:0]));
	ALU        alu      (.*, .S(alu_out), .A(sr1_out), .B(sr2mux_out));

	Reg #(16)  ir       (Reset, Clk, LD_IR,  bus_out,      IR);
	Reg #(16)  pc       (Reset, Clk, LD_PC,  pcmux_out,    PC);
	Reg #(16)  mar      (Reset, Clk, LD_MAR, bus_out,      MAR);
	Reg #(16)  mdr      (Reset, Clk, LD_MDR, mdrmux_out,   MDR);
	Reg        ben      (Reset, Clk, LD_BEN, ben_in,       BEN);
	Reg        led[9:0] (Reset, Clk, LD_LED, bus_out[9:0], LED);
	Reg        cc[2:0]  (Reset, Clk, LD_CC,  {cc_in_n, cc_in_z, cc_in_p}, {CC_N, CC_Z, CC_P});

	MUX4 #(16) pcmux    (.S(PCMUX),    .out(pcmux_out),    .in0(PC + 16'b1), .in1(bus_out),
		.in2(adder_out), .in3(16'b0));
	MUX2 #(16) marmux   (.S(MARMUX),   .out(marmux_out),   .in0(adder_out),  .in1({4'b0, IR[11:0]}));
	MUX2 #(16) mdrmux   (.S(MIO_EN),   .out(mdrmux_out),   .in0(bus_out),    .in1(data_to_CPU));
	MUX2 #(3)  drmux    (.S(DRMUX),    .out(drmux_out),    .in0(IR[11:9]),   .in1(3'b111));
	MUX2 #(3)  sr1mux   (.S(SR1MUX),   .out(sr1mux_out),   .in0(IR[11:9]),   .in1(IR[8:6]));
	MUX2 #(16) sr2mux   (.S(SR2MUX),   .out(sr2mux_out),   .in0(sr2_out),    .in1(`SEXT(IR, 5)));
	MUX2 #(16) addr1mux (.S(ADDR1MUX), .out(addr1mux_out), .in0(PC),         .in1(sr1_out));
	MUX4 #(16) addr2mux (.S(ADDR2MUX), .out(addr2mux_out), .in0(16'b0),      .in1(`SEXT(IR, 6)),
		.in2(`SEXT(IR, 9)), .in3(`SEXT(IR, 11)));

endmodule
