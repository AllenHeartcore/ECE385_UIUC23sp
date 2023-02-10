module CRA1 (
	input  logic A, B, Ci,
	output logic S, Co);

	assign S = A ^ B ^ Ci;
	assign Co = (A & B) | (B & Ci) | (A & Ci);

endmodule


module CRA4 (
	input  logic [3:0] A, B,
	input  logic Ci,
	output logic [3:0] S,
	output logic Co);

	logic C1, C2, C3;

	CRA1 cra1_0 (.A(A[0]), .B(B[0]), .Ci(Ci), .S(S[0]), .Co(C1));
	CRA1 cra1_1 (.A(A[1]), .B(B[1]), .Ci(C1), .S(S[1]), .Co(C2));
	CRA1 cra1_2 (.A(A[2]), .B(B[2]), .Ci(C2), .S(S[2]), .Co(C3));
	CRA1 cra1_3 (.A(A[3]), .B(B[3]), .Ci(C3), .S(S[3]), .Co(Co));

endmodule


module CRA16 (
	input  logic [15:0] A, B,
	input  logic Ci,
	output logic [15:0] S,
	output logic Co);

	logic C4, C8, C12;

	CRA4 cra4_0 (.A(A[ 3: 0]), .B(B[ 3: 0]), .Ci(Ci),  .S(S[ 3: 0]), .Co(C4));
	CRA4 cra4_1 (.A(A[ 7: 4]), .B(B[ 7: 4]), .Ci(C4),  .S(S[ 7: 4]), .Co(C8));
	CRA4 cra4_2 (.A(A[11: 8]), .B(B[11: 8]), .Ci(C8),  .S(S[11: 8]), .Co(C12));
	CRA4 cra4_3 (.A(A[15:12]), .B(B[15:12]), .Ci(C12), .S(S[15:12]), .Co(Co));

endmodule
