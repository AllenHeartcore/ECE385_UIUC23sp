module testbench();

	timeunit 10ns;
	timeprecision 1ns;

	logic Clk = 0;
	logic LoadA, LoadB, Execute, Reset;
	logic [7:0] D;
	logic [3:0] LED;
	logic [7:0] Aval, Bval, Agold;
	logic [6:0] AhexL, AhexU, BhexL, BhexU;
	integer ErrorCnt = 0;

	Processor processor0(.*);

	always begin: CLOCK_GENERATION
		#1 Clk = ~Clk;
	end

	initial begin: CLOCK_INITIALIZATION
		Clk = 0;
	end

	initial begin: TEST_VECTORS

		LoadA = 0;
		LoadB = 0;
		Execute = 1;
		Reset = 0;
		#2 Reset = 1;

		D = 8'h33;
		#2 LoadA = 1;
		#2 LoadA = 0;
		D = 8'h55;
		#2 LoadB = 1;
		#2 LoadB = 0;
		D = 8'h00;

		#2 Execute = 0;
		#22 Execute = 1;

		Agold = (8'h33 ^ 8'h55);
		if (Aval != Agold)
			ErrorCnt++;
		if (Bval != 8'h55)
			ErrorCnt++;

		if (ErrorCnt == 0)
			$display("Success!");
		else
			$display("%d error(s) detected. Try again!", ErrorCnt);

	end

endmodule
