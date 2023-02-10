module bench();

	timeunit 10ns;
	timeprecision 1ns;

	logic Run_key, Reset_key, Clk = 0;
	logic [ 9:0] Din;
	logic [16:0] rout, gold = 0;
	logic [ 9:0] LED;
	logic [ 6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	integer ErrorCnt = 0;

	Adder subject(.*);

	initial begin: CLOCK_INITIALIZATION
		Clk = 0;
	end

	always begin: CLOCK_GENERATION
		#1 Clk = ~Clk;
	end

	initial begin: TEST_VECTORS

		Run_key = 1;
		Reset_key = 0;
		#2 Reset_key = 1;

		Din = 10'h3EC;
		gold = 17'h3EC;
		#2 Run_key = 0;
		#10 Run_key = 1;
		if (rout !== gold) ErrorCnt++;

		Din = 10'h0EB;
		gold = 17'h4D7;
		#2 Run_key = 0;
		#10 Run_key = 1;
		if (rout !== gold) ErrorCnt++;

		Din = 10'h2CA;
		gold = 17'h7A1;
		#2 Run_key = 0;
		#10 Run_key = 1;
		if (rout !== gold) ErrorCnt++;

		Din = 10'h1FE;
		gold = 17'h99F;
		#2 Run_key = 0;
		#10 Run_key = 1;
		if (rout != gold) ErrorCnt++;

		if (ErrorCnt == 0) $display("Success");
		else $display("%d error(s) detected", ErrorCnt);

	end

endmodule
