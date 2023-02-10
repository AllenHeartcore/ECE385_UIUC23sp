/* state machine to convert a switch input to a ONE-clock-cycle-long event
 * so that registers are loaded once instead of during full button press
 * similar to the hold->reset portion of the serial logic processor */

module FSM (
	input  logic Run, Reset, Clk,
	output logic Load);

	enum logic [2:0] {STOP, EXEC, DONE} curr, next;

	always_ff @ (posedge Clk or posedge Reset) begin
		if (Reset)
			curr <= STOP;
		else
			curr <= next;
	end

	always_comb begin // self-looping
		next = curr;
		unique case (curr)
			STOP: if (Run)  next = EXEC;
			EXEC: next = DONE;
			DONE: if (~Run) next = STOP;
		endcase
	end

	always_comb begin // output
		case (curr)
			STOP: Load = 1'b0;
			EXEC: Load = 1'b1;
			DONE: Load = 1'b0;
		endcase
	end

endmodule
