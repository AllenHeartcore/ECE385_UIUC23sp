module I2S (
	input  logic sclk, lrclk, dout, play, ack, valid,
	input  logic [ 7:0] sample,
	output logic [23:0] addr,
	output logic din, req);


	logic [31:0] signal;
	logic [23:0] addr_ctr;

	enum logic [3:0] {IDLE, REQED, ACKED} cur, next;

	/* [FSM]
	 * IDLE : @ (negedge lrclk) -> REQED, write addr, inc ctr, assert req
	 * REQED: @ (ack) -> ACKED, deassert req
	 * ACKED: @ (valid) -> IDLE
	 */

	always_comb begin
		case (cur)
			IDLE:  next = IDLE;
			REQED: next = ack   ? ACKED : REQED;
			ACKED: next = valid ? IDLE  : ACKED;
		endcase
	end


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

	always_ff @ (negedge lrclk) begin

		if (sample == 8'h80)
			signal <= 32'h40000000;
		else if (sample[7])
			signal <= {1'b0, sample - 1, sample - 1, sample, 7'b0};
		else
			signal <= {1'b0, sample, sample, sample, 7'b0};

		addr <= addr_ctr;
		addr_ctr <= addr_ctr + 1;
		req <= 1'b1;
		cur <= REQED;

	end


	always_ff @ (posedge sclk) begin

		if (!play) begin
			cur <= IDLE;
			addr_ctr <= 24'h0;
		end else
			cur <= next;

		if (cur == ACKED && req == 1'b1)
			req <= 1'b0;

		signal <= {signal[30:0], signal[31]};

	end

	assign din = signal[31];

endmodule
