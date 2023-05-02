module I2S (
	input  logic sclk, lrclk, dout, play,
	input  logic [ 7:0] sample,
	output logic [23:0] addr,
	output logic din);


	logic [31:0] shiftreg;
	logic [ 5:0] load_ctr;	// period = 64

	always_ff @ (negedge lrclk) begin
		if (!play) begin
			addr <= 24'h000000;
		end else
			addr <= addr + 1;
	end


	always_ff @ (posedge sclk) begin
		if (load_ctr == 6'b000000) begin
			shiftreg <= {1'b0, sample, 23'b0};
			load_ctr <= 6'b000001;
		end else begin
			shiftreg <= {shiftreg[30:0], shiftreg[31]};
			load_ctr <= load_ctr + 1;
		end
	end

	assign din = shiftreg[31];

endmodule
