module Reg4 (
	input  logic shift_in, enload, enshift, Reset, Clk,
	input  logic [7:0] load_in,
	output logic shift_out,
	output logic [7:0] val);

	always_ff @ (posedge Clk) begin
		if (Reset)
			val <= 4'h0;
		else if (enload)
			val <= load_in;
		else if (enshift)
			val <= { shift_in, val[7:1] };
	end

	assign shift_out = val[0];

endmodule


module UReg (
	input  logic A_in, B_in, A_enload, B_enload, enshift, Reset, Clk,
	input  logic [7:0] load_in,
	output logic A_out, B_out,
	output logic [7:0] A_val, B_val);

	Reg4 regA (.*, .shift_in(A_in), .enload(A_enload), .shift_out(A_out), .val(A_val));
	Reg4 regB (.*, .shift_in(B_in), .enload(B_enload), .shift_out(B_out), .val(B_val));

endmodule
