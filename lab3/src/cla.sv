module CLA1 (
	input  logic A, B, Ci,
	output logic S, P, G);

	assign S = A ^ B ^ Ci;
	assign P = A ^ B;
	assign G = A & B;

endmodule


module CLA4 (
	input  logic [3:0] A, B,
	input  logic Ci,
	output logic [3:0] S,
	output logic Pg, Gg);

	logic C1, C2, C3;
	logic [3:0] P, G;

	CLA1 cla1_0 (.A(A[0]), .B(B[0]), .Ci(Ci), .S(S[0]), .P(P[0]), .G(G[0]));
	CLA1 cla1_1 (.A(A[1]), .B(B[1]), .Ci(C1), .S(S[1]), .P(P[1]), .G(G[1]));
	CLA1 cla1_2 (.A(A[2]), .B(B[2]), .Ci(C2), .S(S[2]), .P(P[2]), .G(G[2]));
	CLA1 cla1_3 (.A(A[3]), .B(B[3]), .Ci(C3), .S(S[3]), .P(P[3]), .G(G[3]));

	CLU4 clu4_s (.Ci, .C1, .C2, .C3, .P, .G, .Pg, .Gg);

endmodule


module CLA16 (
	input  logic [15:0] A, B,
	input  logic Ci,
	output logic [15:0] S,
	output logic Co);

	logic C4, C8, C12;
	logic [3:0] Pg, Gg;

	CLA4 cla4_0 (.A(A[ 3: 0]), .B(B[ 3: 0]), .Ci(Ci),  .S(S[ 3: 0]), .Pg(Pg[0]), .Gg(Gg[0]));
	CLA4 cla4_1 (.A(A[ 7: 4]), .B(B[ 7: 4]), .Ci(C4),  .S(S[ 7: 4]), .Pg(Pg[1]), .Gg(Gg[1]));
	CLA4 cla4_2 (.A(A[11: 8]), .B(B[11: 8]), .Ci(C8),  .S(S[11: 8]), .Pg(Pg[2]), .Gg(Gg[2]));
	CLA4 cla4_3 (.A(A[15:12]), .B(B[15:12]), .Ci(C12), .S(S[15:12]), .Pg(Pg[3]), .Gg(Gg[3]));

	CLU4 clu4_l (.Ci, .C1(C4), .C2(C8), .C3(C12), .Co, .P(Pg), .G(Gg));

endmodule


module CLU4 (
	input  logic Ci,
	input  logic [3:0] P, G,
	output logic C1, C2, C3, Co, Pg, Gg);

	assign C1 = (Ci   & P[0]) |
				(G[0]);
	assign C2 = (Ci   & P[0] & P[1]) |
				(G[0] & P[1]) |
				(G[1]);
	assign C3 = (Ci   & P[0] & P[1] & P[2]) |
				(G[0] & P[1] & P[2]) |
				(G[1] & P[2]) |
				(G[2]);
	assign Co = (Ci   & P[0] & P[1] & P[2] & P[3]) |
				(G[0] & P[1] & P[2] & P[3]) |
				(G[1] & P[2] & P[3]) |
				(G[2] & P[3]) |
				(G[3]);

	assign Pg = &P;
	assign Gg = (G[0] & P[1] & P[2] & P[3]) |
				(G[1] & P[2] & P[3]) |
				(G[2] & P[3]) |
				(G[3]);

endmodule
