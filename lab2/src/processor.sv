module Processor (
	input  logic LoadA, LoadB, Execute, Reset, Clk,
	input  logic [7:0] D,
	output logic [3:0] LED,
	output logic [7:0] Aval, Bval,
	output logic [6:0] AhexL, AhexU, BhexL, BhexU);

	logic [7:0] sD, A, B;
	logic [2:0] sF;
	logic [1:0] sR;
	logic A_enload, B_enload, enshift;
	logic sLoadA, sLoadB, sExecute, sReset;
	logic A_raw, B_raw, A_comped, B_comped, F_AB, A_routed, B_routed;

	logic [2:0] F = 3'b010;
	logic [1:0] R = 2'b10;

	assign Aval = A;
	assign Bval = B;
	assign LED = {sLoadA, sLoadB, sExecute, sReset};

	UReg   register_unit (
		.A_in (A_routed), .B_in (B_routed),
		.A_out(A_raw),    .B_out(B_raw),
		.A_val(A),        .B_val(B),
		.load_in(sD),     .Reset(sReset),
		.A_enload, .B_enload, .enshift, .Clk);

	UComp  computation_unit (
		.A_in (A_raw),    .B_in (B_raw),    .F(sF),
		.A_out(A_comped), .B_out(B_comped), .F_AB);

	URoute routing_unit (
		.A_in (A_comped), .B_in (B_comped), .R(sR),
		.A_out(A_routed), .B_out(B_routed), .F_AB);

	UCtrl  control_unit (
		.LoadA(sLoadA),     .LoadB(sLoadB),
		.Execute(sExecute), .Reset(sReset),
		.A_enload, .B_enload, .enshift, .Clk);

	HexDriver HDAL (.in(A[3:0]), .out(AhexL));
	HexDriver HDBL (.in(B[3:0]), .out(BhexL));
	HexDriver HDAU (.in(A[7:4]), .out(AhexU));
	HexDriver HDBU (.in(B[7:4]), .out(BhexU));

	Syncer D_Syncer[7:0] (Clk, D, sD);
	Syncer F_Syncer[2:0] (Clk, F, sF);
	Syncer R_Syncer[1:0] (Clk, R, sR);
	Syncer button_Syncer[3:0] (Clk,
		{LoadA, LoadB, ~Execute, ~Reset},
		{sLoadA, sLoadB, sExecute, sReset});

endmodule
