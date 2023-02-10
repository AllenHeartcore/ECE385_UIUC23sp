module mux2_1_17	(	input				S,
						input					[15:0] A_In,
						input 				[16:0] B_In,
						output logic		[16:0] Q_Out);
						
		// 17 bit parallel multiplexer implemented using case statement
		always_comb
		begin
				unique case(S)
						1'b0	:	Q_Out <= {1'b0, A_In};
						1'b1	:	Q_Out <= B_In;
				endcase
		end
		
		
endmodule