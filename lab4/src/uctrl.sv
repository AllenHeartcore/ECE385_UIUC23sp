module UCtrl (
	input  logic Reset, Run, Clk,
	input  logic Mp, Mt,
	output logic [3:0] phase);

	enum logic [4:0] {
		SHIFT1, SHIFT2, SHIFT3, SHIFT4,
		SHIFT5, SHIFT6, SHIFT7, SHIFT8,
		ADD1,   ADD2,   ADD3,   ADD4,
		ADD5,   ADD6,   ADD7,   SUB,
		STOP,   MASK,   DONE
	} cur, next;

	always_ff @ (posedge Clk) begin
		if (Reset)
			cur <= STOP;
		else
			cur <= next;
	end

	always_comb begin

		next = cur;

		/* Note on the two M's: Prev M (Mp) = B[1], This M (Mt) = B[0]
		 * At THIS tick, when the FSM determines its NEXT state,
		 * it is looking at B from the PREVIOUS tick.
		 * So Mt in THIS tick is Mp in the PREVIOUS tick.
		 * (Except for the first tick when B hasn't started shifting)
		 */
		unique case (cur)
			STOP:   if (Run) next = MASK;
			MASK:   if (Mt) next = ADD1; else next = SHIFT1;
			SHIFT1: if (Mp) next = ADD2; else next = SHIFT2;
			SHIFT2: if (Mp) next = ADD3; else next = SHIFT3;
			SHIFT3: if (Mp) next = ADD4; else next = SHIFT4;
			SHIFT4: if (Mp) next = ADD5; else next = SHIFT5;
			SHIFT5: if (Mp) next = ADD6; else next = SHIFT6;
			SHIFT6: if (Mp) next = ADD7; else next = SHIFT7;
			SHIFT7: if (Mp) next = SUB;  else next = SHIFT8;
			SHIFT8: next = DONE;
			ADD1:   next = SHIFT1;    ADD2:   next = SHIFT2;
			ADD3:   next = SHIFT3;    ADD4:   next = SHIFT4;
			ADD5:   next = SHIFT5;    ADD6:   next = SHIFT6;
			ADD7:   next = SHIFT7;    SUB:    next = SHIFT8;
			DONE:   if (~Run) next = STOP;
		endcase

		case (cur)
			MASK:	phase = 4'b1000;
			SHIFT1, SHIFT2, SHIFT3, SHIFT4, SHIFT5, SHIFT6, SHIFT7, SHIFT8:
					phase = 4'b0100;
			ADD1, ADD2, ADD3, ADD4, ADD5, ADD6, ADD7:
					phase = 4'b0010;
			SUB:	phase = 4'b0001;
			default: phase = 4'b0000;
		endcase

	end

endmodule
