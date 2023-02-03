module URoute (
	input  logic [1:0] R,
	input  logic A_in, B_in, F_AB,
	output logic A_out, B_out);

	always_comb begin
		unique case (R)
			2'b00: A_out = A_in;
			2'b01: A_out = A_in;
			2'b10: A_out = F_AB;
			2'b11: A_out = B_in;
		endcase
		unique case (R)
			2'b00: B_out = B_in;
			2'b01: B_out = F_AB;
			2'b10: B_out = B_in;
			2'b11: B_out = A_in;
		endcase
	end

endmodule
