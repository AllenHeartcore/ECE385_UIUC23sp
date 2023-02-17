module FullAdder (
	input  logic A, B, Ci,
	output logic S, Co);

	assign S  = A ^ B ^ Ci;
	assign Co = A & B | A & Ci | B & Ci;

endmodule


module UComp (
	input  logic [8:0] A, B,
	input  logic [3:0] phase,
	output logic [8:0] S);

	logic [8:0] C, BR; // "R"egularized
	logic sub;

	assign sub = phase[0];
	assign BR = B ^ {9{sub}};

	FullAdder fa0 (.A(A[0]), .B(BR[0]), .Ci(sub),  .S(S[0]), .Co(C[0]));
	FullAdder fa1 (.A(A[1]), .B(BR[1]), .Ci(C[0]), .S(S[1]), .Co(C[1]));
	FullAdder fa2 (.A(A[2]), .B(BR[2]), .Ci(C[1]), .S(S[2]), .Co(C[2]));
	FullAdder fa3 (.A(A[3]), .B(BR[3]), .Ci(C[2]), .S(S[3]), .Co(C[3]));
	FullAdder fa4 (.A(A[4]), .B(BR[4]), .Ci(C[3]), .S(S[4]), .Co(C[4]));
	FullAdder fa5 (.A(A[5]), .B(BR[5]), .Ci(C[4]), .S(S[5]), .Co(C[5]));
	FullAdder fa6 (.A(A[6]), .B(BR[6]), .Ci(C[5]), .S(S[6]), .Co(C[6]));
	FullAdder fa7 (.A(A[7]), .B(BR[7]), .Ci(C[6]), .S(S[7]), .Co(C[7]));
	FullAdder fa8 (.A(A[8]), .B(BR[8]), .Ci(C[7]), .S(S[8]), .Co(C[8]));

endmodule
