`include "src/top.sv"
`include "src/utils.sv"

module bench();

	timeunit 10ns;
	timeprecision 1ns;

	logic Run = 1, Continue = 1, Clk = 0;
	logic [9:0] SW, LED;
	`TOGGLE_INTERNAL
	logic [15:0] hexval, R0, R1, R2, R3, R4, R5, R6, R7;

	assign R0 = REG[0];
	assign R1 = REG[1];
	assign R2 = REG[2];
	assign R3 = REG[3];
	assign R4 = REG[4];
	assign R5 = REG[5];
	assign R6 = REG[6];
	assign R7 = REG[7];

	SLC3TopSim subject(.*);

`define NUM1  10'h3EC
`define NUM2  10'h0EB
`define NUM3  10'h2CA
`define NUM4  10'h1FE
`define TICK  #120
`define LTICK #1200
`define RUN   `TICK Run = 0; `TICK Run = 1;
`define CONT  `TICK Continue = 0; `TICK Continue = 1;
`define RESET `TICK Run = 0; Continue = 0; `TICK Run = 1; Continue = 1;
`define SETSW(val) `TICK SW = val;

	initial begin: CLOCK_INIT
		Clk = 0;
	end

	always begin: CLOCK_GEN
		#1 Clk = ~Clk;
	end

	initial begin: TEST_VECT

`ifdef FETCH_DEMO

		`RESET
		`RUN
		for (int i = 0; i < 80; i++) begin
			`CONT
		end

`else

		// I/O 1
		`RESET
		`SETSW(10'h03)
		`RUN
		`SETSW(`NUM1)
		`SETSW(`NUM2)
		`SETSW(`NUM3)
		`SETSW(`NUM4)

		// I/O 2
		`RESET
		`SETSW(10'h06)
		`RUN
		`SETSW(`NUM1) `CONT
		`SETSW(`NUM2) `CONT
		`SETSW(`NUM3) `CONT
		`SETSW(`NUM4) `CONT

		// Self-mod
		`RESET
		`SETSW(10'h0B)
		`RUN
		for (int i = 0; i < 16; i++) begin
			`CONT
		end

		// XOR
		`RESET
		`SETSW(10'h14)
		`RUN
		`SETSW(`NUM1) `CONT
		`SETSW(`NUM2) `CONT
		`CONT
		`SETSW(`NUM3) `CONT
		`SETSW(`NUM4) `CONT
		`CONT

		// Mult
		`RESET
		`SETSW(10'h31)
		`RUN
		`SETSW(`NUM1 & 10'hFF) `CONT
		`SETSW(`NUM2 & 10'hFF) `CONT
		`LTICK `CONT
		`SETSW(`NUM3 & 10'hFF) `CONT
		`SETSW(`NUM4 & 10'hFF) `CONT
		`LTICK `CONT

		// Sort
		`RESET
		`SETSW(10'h5A)
		`RUN
		`SETSW(10'h3) `CONT
		for (int i = 0; i < 16; i++) begin
			`CONT
		end `CONT
		`SETSW(10'h2) `CONT
		#24000
		`SETSW(10'h3) `CONT
		for (int i = 0; i < 16; i++) begin
			`CONT
		end `CONT

		`RESET

`endif

	end

endmodule
