module I2S (
	input  logic SCLK, LRCLK, DIN,
	output logic DOUT);

	logic [7:0] sample;
	logic [31:0] signal;

	/*  sample  ( amp ) -> signal (of bit depth 24)
	 * 01111111 (+ 127) -> 0 01111111 01111111 01111111 0000000 (+8,355,711)
	 * 01111110 (+ 126) -> 0 01111110 01111110 01111110 0000000 (+8,289,918)
	 * ...
	 * 00000001 (+   1) -> 0 00000001 00000001 00000001 0000000 (+   65,793)
	 * 00000000 (    0) -> 0 00000000 00000000 00000000 0000000 (         0)
	 * 11111111 (-   1) -> 0 11111110 11111110 11111111 0000000 (-   65,793)
	 * ...
	 * 10000010 (- 126) -> 0 10000001 10000001 10000010 0000000 (-8,289,918)
	 * 10000001 (- 127) -> 0 10000000 10000000 10000001 0000000 (-8,355,711)
	 * 10000000 (- 128) -> 0 10000000 00000000 00000000 0000000 (-8,388,608)
	 */

	always_ff @ (negedge LRCLK) begin
		if (sample == 8'h80)
			signal <= 32'h40000000;
		else if (sample[7])
			signal <= {1'b0, sample - 1, sample - 1, sample, 7'b0};
		else
			signal <= {1'b0, sample, sample, sample, 7'b0};
	end

	always_ff @ (posedge SCLK) begin
		signal <= {signal[30:0], signal[31]};
	end

	assign DOUT = signal[31];

endmodule
