module UCtrl (
	input  logic LoadA, LoadB, Execute, Reset, Clk,
	output logic A_enload, B_enload, enshift);

	enum logic [3:0] {
		STOP, RUN1, RUN2, RUN3, RUN4,
		RUN5, RUN6, RUN7, RUN8, DONE
	} cur, next;

	always_ff @ (posedge Clk) begin
		if (Reset)
			cur <= STOP;
		else
			cur <= next;
	end

	always_comb
	begin

		next = cur;

		unique case (cur)
			STOP: if (Execute) next = RUN1;
			RUN1: next = RUN2;
			RUN2: next = RUN3;
			RUN3: next = RUN4;
			RUN4: next = RUN5;
			RUN5: next = RUN6;
			RUN6: next = RUN7;
			RUN7: next = RUN8;
			RUN8: next = DONE;
			DONE: if (~Execute) next = STOP;
		endcase

		case (cur)
			STOP: begin
				A_enload  = LoadA;
				B_enload  = LoadB;
				enshift   = 1'b0;
			end
			DONE: begin
				A_enload  = 1'b0;
				B_enload  = 1'b0;
				enshift   = 1'b0;
			end
			default: begin
				A_enload  = 1'b0;
				B_enload  = 1'b0;
				enshift   = 1'b1;
			end
		endcase

	end

endmodule
