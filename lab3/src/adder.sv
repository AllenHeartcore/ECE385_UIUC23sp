module Adder (
	input  logic Run_key, Reset_key, Clk,
	input  logic [9:0] Din,
	output logic [16:0] rout,
	output logic [9:0] LED,
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);

	logic Load, Run, Reset;
	logic [16:0] rin, sum;
	logic [15:0] Din_ext;

	// buttons are active low
	assign Run   = ~Run_key;
	assign Reset = ~Reset_key;
	assign Din_ext = {6'b000000, Din};

	FSM   uctrl (.*);
	Reg17 ureg  (.*, .in(rin), .out(rout));
	MUX17 mux   (.select(Load), .in0(Din_ext), .in1(sum), .out(rin));

	// CRA16 ripple_adder    (.A(Din_ext), .B(rout[15:0]), .Ci(1'b0), .Co(sum[16]), .S(sum[15:0]));
	CLA16 lookahead_adder (.A(Din_ext), .B(rout[15:0]), .Ci(1'b0), .Co(sum[16]), .S(sum[15:0]));
	// CSA16 select_adder    (.A(Din_ext), .B(rout[15:0]), .Ci(1'b0), .Co(sum[16]), .S(sum[15:0]));

	assign LED[9]   = rout[16];
	assign LED[8:2] = 7'h00;
	assign LED[1:0] = Din[9:8];
	HexDriver AHex0 (.in(Din [ 3: 0]), .out(HEX0));
	HexDriver AHex1 (.in(Din [ 7: 4]), .out(HEX1));
	HexDriver BHex0 (.in(rout[ 3: 0]), .out(HEX2));
	HexDriver BHex1 (.in(rout[ 7: 4]), .out(HEX3));
	HexDriver BHex2 (.in(rout[11: 8]), .out(HEX4));
	HexDriver BHex3 (.in(rout[15:12]), .out(HEX5));

endmodule
