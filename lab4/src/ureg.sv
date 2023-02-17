module UReg (
	input  logic Xnew, Reset, Clk,
	input  logic [3:0] phase,
	input  logic [7:0] Anew, Bnew,
	output logic Xval,
	output logic [7:0] Aval, Bval);

	logic X;
	logic [7:0] A, B;

	assign Xval = X;
	assign Aval = A;
	assign Bval = B;

	always_ff @ (posedge Clk) begin
		if (Reset) begin
			X <= 1'b0;
			A <= 8'h0;
			B <= Bnew;
		end
		else case (phase)
			4'b1000: begin // Mask
				X <= 1'b0;
				A <= 8'h0;
			end
			4'b0100: begin // Shift
				A <= {X,    A[7:1]};
				B <= {A[0], B[7:1]};
			end
			4'b0010, 4'b0001: begin // Add, Sub
				X <= Xnew;
				A <= Anew;
			end
		endcase
	end

endmodule
