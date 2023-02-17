module Multer (
	input  logic Reset, Run, Clk,
	input  logic [7:0] SW,
	output logic [7:0] A, B,
	output logic [9:0] LED,
	output logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

	logic [7:0] S, Anew;
	logic X, Xnew, sReset, sRun;
	logic [3:0] phase;

	Syncer SW_syncer [7:0] (Clk, SW, S);
	Syncer btn_syncer[1:0] (Clk,
		{~Reset, ~Run}, {sReset, sRun});

	UReg  register_unit (
		.Xnew,    .Anew,    .Bnew(S),
		.Xval(X), .Aval(A), .Bval(B),
		.Reset(sReset), .phase, .Clk);

	UComp computation_unit (
		.A({A[7], A}), .B({S[7], S}),
		.S({Xnew, Anew}), .phase);

	UCtrl control_unit (
		.Mp(B[1]), .Mt(B[0]), .phase,
		.Reset(sReset), .Run(sRun), .Clk);

	assign LED[9:1] = 9'h00;
	assign LED[0] = X;
	HexDriver HDAU (.in(A[7:4]), .out(HEX5));
	HexDriver HDAL (.in(A[3:0]), .out(HEX4));
	HexDriver HDBU (.in(B[7:4]), .out(HEX3));
	HexDriver HDBL (.in(B[3:0]), .out(HEX2));
	HexDriver HDSU (.in(S[7:4]), .out(HEX1));
	HexDriver HDSL (.in(S[3:0]), .out(HEX0));

endmodule
