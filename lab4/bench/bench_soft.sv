module bench();

	timeunit 10ns;
	timeprecision 1ns;

	logic Run = 1, Reset = 1, Clk = 0;
	logic [7:0] SW, A, B;
	logic [9:0] LED;
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	integer ErrorCnt = 0;

	Multer subject(.*);

	initial begin: CLOCK_INITIALIZATION
		Clk = 0;
	end

	always begin: CLOCK_GENERATION
		#1 Clk = ~Clk;
	end

	initial begin: TEST_VECTORS

		SW = 8'h07;
		Reset = 0;
		#2 Reset = 1;
		SW = 8'h3B;
		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h00) ErrorCnt++;
		if (A !== 8'h01) ErrorCnt++;
		if (B !== 8'h9D) ErrorCnt++;

		SW = 8'hF9;
		Reset = 0;
		#2 Reset = 1;
		SW = 8'h3B;
		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h01) ErrorCnt++;
		if (A !== 8'hFE) ErrorCnt++;
		if (B !== 8'h63) ErrorCnt++;

		SW = 8'h07;
		Reset = 0;
		#2 Reset = 1;
		SW = 8'hC5;
		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h01) ErrorCnt++;
		if (A !== 8'hFE) ErrorCnt++;
		if (B !== 8'h63) ErrorCnt++;

		SW = 8'hF9;
		Reset = 0;
		#2 Reset = 1;
		SW = 8'hC5;
		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h00) ErrorCnt++;
		if (A !== 8'h01) ErrorCnt++;
		if (B !== 8'h9D) ErrorCnt++;

		SW = 8'hFF;
		Reset = 0;
		#2 Reset = 1;
		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h00) ErrorCnt++;
		if (A !== 8'h00) ErrorCnt++;
		if (B !== 8'h01) ErrorCnt++;

		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h01) ErrorCnt++;
		if (A !== 8'hFF) ErrorCnt++;
		if (B !== 8'hFF) ErrorCnt++;

		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h00) ErrorCnt++;
		if (A !== 8'h00) ErrorCnt++;
		if (B !== 8'h01) ErrorCnt++;

		#2 Run = 0;
		#50 Run = 1;
		if (LED[0] !== 1'h01) ErrorCnt++;
		if (A !== 8'hFF) ErrorCnt++;
		if (B !== 8'hFF) ErrorCnt++;

		if (ErrorCnt == 0) $display("Success");
		else $display("%d error(s) detected", ErrorCnt);

	end

endmodule
