module UComp (
	input  logic [2:0] F,
	input  logic A_in, B_in,
	output logic A_out, B_out, F_AB);

	always_comb begin
		unique case (F)
			3'b000: F_AB = A_in & B_in;
			3'b001: F_AB = A_in | B_in;
			3'b010: F_AB = A_in ^ B_in;
			3'b011: F_AB = 1'b1;
			3'b100: F_AB = ~(A_in & B_in);
			3'b101: F_AB = ~(A_in | B_in);
			3'b110: F_AB = ~(A_in ^ B_in);
			3'b111: F_AB = 1'b0;
		endcase
	end

	assign A_out = A_in;
	assign B_out = B_in;

endmodule
