module Reg17 (
	input  logic Load, Reset, Clk,
	input  logic [16:0] in,
	output logic [16:0] out);

	always_ff @ (posedge Clk) begin
		if (Reset) // synchronous
			out <= 17'b00000000000000000;
		else if (Load)
			out <= in;
	end

endmodule


module MUX17 (
	input  logic select,
	input  logic [15:0] in0,
	input  logic [16:0] in1,
	output logic [16:0] out);

	always_comb begin
		unique case (select)
			1'b0: out = {1'b0, in0};
			1'b1: out = in1;
		endcase
	end

endmodule


module HexDriver (
	input  logic [3:0] in,
	output logic [6:0] out);

	always_comb begin
		unique case (in)
			4'b0000: out = 7'b1000000;
			4'b0001: out = 7'b1111001;
			4'b0010: out = 7'b0100100;
			4'b0011: out = 7'b0110000;
			4'b0100: out = 7'b0011001;
			4'b0101: out = 7'b0010010;
			4'b0110: out = 7'b0000010;
			4'b0111: out = 7'b1111000;
			4'b1000: out = 7'b0000000;
			4'b1001: out = 7'b0010000;
			4'b1010: out = 7'b0001000;
			4'b1011: out = 7'b0000011;
			4'b1100: out = 7'b1000110;
			4'b1101: out = 7'b0100001;
			4'b1110: out = 7'b0000110;
			4'b1111: out = 7'b0001110;
			default: out = 7'bX;
		endcase
	end

endmodule
