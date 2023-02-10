module CSA4 (
	input  logic [3:0] A, B,
	input  logic Ci,
	output logic [3:0] S,
	output logic Co);

	logic Ca, Cb;
	logic [3:0] Sa, Sb;

	CRA4 cra4_a (.A, .B, .Ci(1'b0), .S(Sa), .Co(Ca));
	CRA4 cra4_b (.A, .B, .Ci(1'b1), .S(Sb), .Co(Cb));

	always_comb begin
		if (Ci == 1'b0)
			S = Sa;
		else
			S = Sb;
		Co = Ca | (Cb & Ci);
	end

endmodule


module CSA16 (
	input  logic [15:0] A, B,
	input  logic Ci,
	output logic [15:0] S,
	output logic Co);

	logic C4, C8, C12;

	CRA4 csa4_0 (.A(A[ 3: 0]), .B(B[ 3: 0]), .Ci(Ci),  .S(S[ 3: 0]), .Co(C4));
	CSA4 csa4_1 (.A(A[ 7: 4]), .B(B[ 7: 4]), .Ci(C4),  .S(S[ 7: 4]), .Co(C8));
	CSA4 csa4_2 (.A(A[11: 8]), .B(B[11: 8]), .Ci(C8),  .S(S[11: 8]), .Co(C12));
	CSA4 csa4_3 (.A(A[15:12]), .B(B[15:12]), .Ci(C12), .S(S[15:12]), .Co(Co));

endmodule
