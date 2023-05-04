module I2S (
	input  logic sclk, lrclk, dout, play,
	input  logic [ 7:0] sample,
	output logic [23:0] addr,
	output logic din);


	logic [31:0] shiftreg;
	logic loadflag, loadflag_curr, loadflag_prev;

	always_ff @ (negedge lrclk) begin
		loadflag <= ~loadflag;
		if (!play) begin
			addr <= 24'h0;
		end else
			addr <= addr + 24'h1;
	end


	always_ff @ (posedge sclk) begin
		loadflag_curr <= loadflag;
		loadflag_prev <= loadflag_curr;
		if (!loadflag_curr & loadflag_prev)
			shiftreg <= {1'b0, ~sample[7], sample[6:0], 23'b0};
		else
			shiftreg <= {shiftreg[30:0], shiftreg[31]};
	end

	assign din = shiftreg[31];

endmodule
