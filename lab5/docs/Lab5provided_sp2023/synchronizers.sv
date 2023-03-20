// This debouncer is based on the class discussion and the circuit diagram at
// http://eewiki.net/pages/viewpage.action?pageId=4980758
//
// The VHDL code provided on that page was not considered or converted.

//synchronizer with no reset (for switches/buttons)
module sync (
	input Clk, d, 
	output logic q
);

always_ff @ (posedge Clk)
begin
	q <= d;
end

endmodule


//synchronizer with reset to 0 (d_ff)
module sync_r0 (
	input Clk, Reset, d, 
	output logic q
);

initial
begin	
	q <= 1'b0;
end

always @ (posedge Clk or posedge Reset)
begin
	if (Reset)
		q <= 1'b0;
	else
		q <= d;
end

endmodule

//synchronizer with reset to 1 (d_ff)
module sync_r1 (
	input Clk, Reset, d, 
	output logic q
);
initial
begin	
	q <= 1'b1;
end

always@ (posedge Clk or posedge Reset)
begin
	if (Reset)
		q <= 1'b1;
	else
		q <= d;
end

endmodule
