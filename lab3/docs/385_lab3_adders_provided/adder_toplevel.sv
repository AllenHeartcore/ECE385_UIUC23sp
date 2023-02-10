//Top level for ECE 385 adders lab
//modified for Spring 2023

//Note: lowest 2 HEX digits will reflect lower 8 bits of switch input
//Upper 4 HEX digits will reflect value in the accumulator


module adder_toplevel  (input Clk, Reset_Clear, Run_Accumulate, 
						input [9:0]			SW,
						output logic [9:0]	LED,
						output logic [6:0]	HEX0, 
											HEX1, 
											HEX2, 
											HEX3, 
											HEX4,
											HEX5
										);

		// Declare temporary values used by other modules
		logic Reset_h, Run_h;
		logic Load;
		logic [16:0] In, Out;
		logic [16:0] S;
		logic [16:0] extended_SW;
		
		assign extended_SW = {6'b000000, SW};
		
		// Misc logic that inverts button presses and ORs the Load and Run signal
		always_comb	
		begin
				Reset_h = ~Reset_Clear;
				Run_h = ~Run_Accumulate;

		end
		
		// Control unit allows the register to load once, and not during full duration of button press
		control run_once ( .*, .Reset(Reset_h), .Run(Run_h), .Run_O(Load));
		
		// mux that puts either sum of A and B or B into register, selects based on control unit
		mux2_1_17 m_mux ( .S(Load), .A_In(extended_SW[15:0]), .B_In(S[16:0]), .Q_Out(In[16:0]) );
		
		// Register unit that holds the accumulated sum
		reg_17 reg_unit	( .*, .Reset(Reset_h), .Load(Load), .D(In[16:0]), .Data_Out(Out[16:0]));

		// Addition unit

		ripple_adder adder		(.A(extended_SW[15:0]), .B(Out[15:0]), .cin(1'b0), .cout(S[16]), .S(S[15:0]) );
		
		//lookahead_adder adderla	(.A(extended_SW[15:0]), .B(Out[15:0]), .cin(1'b0), .cout(S[16]), .S(S[15:0]) );
		
		//select_adder adders	(.A(extended_SW[15:0]), .B(Out[15:0]), .cin(1'b0), .cout(S[16]), .S(S[15:0]) );


		// Hex units that display contents of SW and register R in hex
		HexDriver		AHex0 (
								.In0(SW[3:0]),
								.Out0(HEX0) );
								
		HexDriver		AHex1 (
								.In0(SW[7:4]),
								.Out0(HEX1) );
								
		HexDriver		BHex0 (
								.In0(Out[3:0]),
								.Out0(HEX2) );
								
		HexDriver		BHex1 (
								.In0(Out[7:4]),
								.Out0(HEX3) );
		
		HexDriver		BHex2 (
								.In0(Out[11:8]),
								.Out0(HEX4) );
								
		HexDriver		BHex3 (
								.In0(Out[15:12]),
								.Out0(HEX5) );
								
		
		assign LED[1:0] = SW[9:8];
		assign LED[9] = Out[16];
		assign LED[8:2] = 7'h00;
		
endmodule