`ifndef _UTILS_SV
`define _UTILS_SV


`define NET_CC    logic CC_N, CC_Z, CC_P, ben_in, cc_in_n, cc_in_z, cc_in_p
`define NET_MUX3  logic [2:0]  drmux_out, sr1mux_out
`define NET_MUX16 logic [15:0] pcmux_out, marmux_out, mdrmux_out, sr2mux_out, addr1mux_out, addr2mux_out
`define NET_MISC  logic [15:0] sr1_out, sr2_out, alu_out, bus_out, adder_out

`define CTRL_LD   logic LD_IR, LD_PC, LD_MAR, LD_MDR, LD_REG, LD_CC, LD_BEN, LD_LED
`define CTRL_GATE logic GatePC, GateMARMUX, GateMDR, GateALU
`define CTRL_MUX  logic MARMUX, DRMUX, SR1MUX, SR2MUX, ADDR1MUX
`define CTRL_MUX2 logic [1:0]  PCMUX, ADDR2MUX, ALUK

`define OUTPUT_REG  output [15:0] IR, PC, MAR, MDR, REG[7:0],
`define INTERNAL_REG logic [15:0] IR, PC, MAR, MDR, REG[7:0];

`define OUTPUT_NET \
	output `NET_CC, \
	output `NET_MUX3, \
	output `NET_MUX16, \
	output `NET_MISC,

`define INTERNAL_NET \
	`NET_CC; \
	`NET_MUX3; \
	`NET_MUX16; \
	`NET_MISC;

`define INPUT_CTRL \
	input  `CTRL_LD, \
	input  `CTRL_GATE, \
	input  `CTRL_MUX, \
	input  `CTRL_MUX2,

`define OUTPUT_CTRL \
	output `CTRL_LD, \
	output `CTRL_GATE, \
	output `CTRL_MUX, \
	output `CTRL_MUX2,

`define INTERNAL_CTRL \
	`CTRL_LD; \
	`CTRL_GATE; \
	`CTRL_MUX; \
	`CTRL_MUX2;

`define TOGGLE_OUTPUT \
	`OUTPUT_REG \
	`ifdef INSPECT_NET \
		`OUTPUT_NET \
	`endif \
	`ifdef INSPECT_CTRL \
		`OUTPUT_CTRL \
	`endif

`define TOGGLE_INTERNAL \
	`INTERNAL_REG \
	`ifdef INSPECT_NET \
		`INTERNAL_NET \
	`endif \
	`ifdef INSPECT_CTRL \
		`INTERNAL_CTRL \
	`endif


module Reg #(parameter WIDTH = 1) (
	input  logic Reset, Clk, LD,
	input  logic [WIDTH-1:0] D,
	output logic [WIDTH-1:0] Q);

	always_ff @ (posedge Clk) begin
		if (Reset) Q <= 1'b0;
		else if (LD) Q <= D;
	end

endmodule


module RegFile (
	input  logic Reset, Clk, LD_REG,
	input  logic [2:0]  SR1, SR2, DR,
	input  logic [15:0] in,
	output logic [15:0] out1, out2,
	output logic [15:0] regs[7:0]);

	always_ff @ (posedge Clk) begin
		if (Reset) begin
			regs[0] <= 16'b0;
			regs[1] <= 16'b0;
			regs[2] <= 16'b0;
			regs[3] <= 16'b0;
			regs[4] <= 16'b0;
			regs[5] <= 16'b0;
			regs[6] <= 16'b0;
			regs[7] <= 16'b0;
		end
		if (LD_REG) regs[DR] <= in;
	end

	assign out1 = regs[SR1];
	assign out2 = regs[SR2];

endmodule


module MUX2 #(parameter WIDTH) (
	input  logic S,
	input  logic [WIDTH-1:0] in0, in1,
	output logic [WIDTH-1:0] out);

	always_comb begin
		case (S)
			1'b0: out = in0;
			1'b1: out = in1;
			default: out = {WIDTH{1'bX}};
		endcase
	end

endmodule


module MUX4 #(parameter WIDTH) (
	input  logic [1:0] S,
	input  logic [WIDTH-1:0] in0, in1, in2, in3,
	output logic [WIDTH-1:0] out);

	always_comb begin
		case (S)
			2'b00: out = in0;
			2'b01: out = in1;
			2'b10: out = in2;
			2'b11: out = in3;
			default: out = {WIDTH{1'bX}};
		endcase
	end

endmodule


module ALU (
	input  logic [1:0]  ALUK,
	input  logic [15:0] A, B,
	output logic [15:0] S);

	always_comb begin
		case (ALUK)
			2'b00: S = A + B;
			2'b01: S = A & B;
			2'b10: S = ~A;
			2'b11: S = A;
			default: S = 16'bX;
		endcase
	end

endmodule


module Bus (
	input  logic [3:0]  gates,
	input  logic [15:0] in1, in2, in3, in4,
	output logic [15:0] out);

	always_comb begin
		case (gates)
			4'b1000: out = in1;
			4'b0100: out = in2;
			4'b0010: out = in3;
			4'b0001: out = in4;
			default: out = 16'bX;
		endcase
	end

endmodule


module HexDriver (
	input  logic [3:0] in,
	output logic [6:0] out);

	always_comb begin
		unique case (in)
			4'b0000: out = 7'b1000000;
			4'b0001: out = 7'b1111001;
			4'b0010: out = 7'b0100100;
			4'b0011: out = 7'b0110000;
			4'b0100: out = 7'b0011001;
			4'b0101: out = 7'b0010010;
			4'b0110: out = 7'b0000010;
			4'b0111: out = 7'b1111000;
			4'b1000: out = 7'b0000000;
			4'b1001: out = 7'b0010000;
			4'b1010: out = 7'b0001000;
			4'b1011: out = 7'b0000011;
			4'b1100: out = 7'b1000110;
			4'b1101: out = 7'b0100001;
			4'b1110: out = 7'b0000110;
			4'b1111: out = 7'b0001110;
			default: out = 7'bX;
		endcase
	end

endmodule


module SyncerFSM (
	input  logic Clk, Run, Continue,
	output logic sRun, sContinue, sReset);

	enum logic [2:0] {
		IDLE, RUN, CONT, RESET,
		RUN_DONE, CONT_DONE, RESET_DONE
	} curr, next;

	always_ff @ (posedge Clk) begin
		curr <= next;
	end

	always_comb begin

`define TRANSITION(PIDLE, PRUN, PCONT, PRESET) \
	case ({~Continue, ~Run}) \
		2'b00: next = PIDLE; \
		2'b01: next = PRUN; \
		2'b10: next = PCONT; \
		2'b11: next = PRESET; \
		default: next = curr; \
	endcase

		unique case (curr) 
			IDLE:  `TRANSITION(IDLE, RUN, CONT, RESET)
			RUN:   next = RUN_DONE;
			CONT:  next = CONT_DONE;
			RESET: next = RESET_DONE;
			RUN_DONE:   `TRANSITION(IDLE, RUN_DONE, CONT, RESET)
			CONT_DONE:  `TRANSITION(IDLE, RUN, CONT_DONE, RESET)
			RESET_DONE: `TRANSITION(IDLE, RESET_DONE, RESET_DONE, RESET_DONE)
			default: next = IDLE;
		endcase

		case (curr)
			RUN:     {sRun, sContinue, sReset} = 3'b100;
			CONT:    {sRun, sContinue, sReset} = 3'b010;
			RESET:   {sRun, sContinue, sReset} = 3'b001;
			RUN_DONE, CONT_DONE, RESET_DONE:
					 {sRun, sContinue, sReset} = 3'b000;
			default: {sRun, sContinue, sReset} = 3'b000;
		endcase

	end

endmodule


`endif
