`include "top.sv"


module ISDU (
	input  logic Run, Continue, Reset, Clk,
	input  logic IR_5, IR_11, BEN,
	input  logic [3:0] Opcode,
	`OUTPUT_CTRL
	output logic rden, wren);

	enum logic [5:0] {
		FCH1 = 6'd18, FCH2w = 6'd37, FCH2x = 6'd39, FCH2 = 6'd33, FCH3 = 6'd35,
		LDR1 = 6'd6 , LDR2w = 6'd29, LDR2x = 6'd31, LDR2 = 6'd25, LDR3 = 6'd27,
		STR1 = 6'd7 , STR2 = 6'd23, STR3 = 6'd16,
		ADD  = 6'd1 , AND  = 6'd5 , NOT  = 6'd9 ,
		JSR1 = 6'd4 , JSR2 = 6'd21, JMP  = 6'd12,
		BR1  = 6'd0 , BR2  = 6'd22, DEC  = 6'd32,
		PSE1 = 6'd61, PSE2 = 6'd62, HALT = 6'd63
	} curr, next;

	always_ff @ (posedge Clk) begin
		if (Reset)
			curr <= HALT;
		else
			curr <= next;
	end

	always_comb begin

		next = curr;

		LD_IR  = 1'b0;
		LD_PC  = 1'b0;
		LD_MAR = 1'b0;
		LD_MDR = 1'b0;
		LD_REG = 1'b0;
		LD_CC  = 1'b0;
		LD_BEN = 1'b0;
		LD_LED = 1'b0;

		GatePC  = 1'b0;
		GateMARMUX = 1'b0;
		GateMDR = 1'b0;
		GateALU = 1'b0;

		PCMUX  = 2'b00;
		MARMUX = 1'b0;
		DRMUX  = 1'b0;
		SR1MUX = 1'b0;
		SR2MUX = 1'b0;
		ADDR1MUX = 1'b0;
		ADDR2MUX = 2'b00;
		ALUK   = 2'b00;

		rden = 1'b0;
		wren = 1'b0;

		unique case (curr)
			FCH1:  next = FCH2w;
			FCH2w: next = FCH2x;
			FCH2x: next = FCH2;
			FCH2:  next = FCH3;
`ifdef FETCH_DEMO
			FCH3:  next = PSE1;
`else
			FCH3:  next = DEC;
`endif
			LDR1:  next = LDR2w;
			LDR2w: next = LDR2x;
			LDR2x: next = LDR2;
			LDR2:  next = LDR3;
			STR1:  next = STR2;
			STR2:  next = STR3;
			JSR1:  next = JSR2;
			ADD, AND, NOT, LDR3, STR3,
			JSR2, JMP, BR2: next = FCH1;
			DEC:
				case (Opcode)
					4'b0001: next = ADD;
					4'b0101: next = AND;
					4'b1001: next = NOT;
					4'b0110: next = LDR1;
					4'b0111: next = STR1;
					4'b0100: next = JSR1;
					4'b1100: next = JMP;
					4'b0000: next = BR1;
					4'b1101: next = PSE1;
					4'b1111: next = HALT;
					default: next = FCH1;
				endcase
			BR1:
				if (BEN) next = BR2;
				else next = FCH1;
			PSE1:
				if (~Continue) next = PSE1;
				else next = PSE2;
			PSE2:
				if (Continue) next = PSE2;
				else next = FCH1;
			HALT:
				if (Run) next = FCH1;
			default: ;
		endcase

		case (curr)
			ADD:   begin  LD_REG = 1'b1; LD_CC  = 1'b1;  GateALU = 1'b1;  DRMUX = 1'b0; SR1MUX = 1'b1; SR2MUX = IR_5; ALUK = 2'b00; end
			AND:   begin  LD_REG = 1'b1; LD_CC  = 1'b1;  GateALU = 1'b1;  DRMUX = 1'b0; SR1MUX = 1'b1; SR2MUX = IR_5; ALUK = 2'b01; end
			NOT:   begin  LD_REG = 1'b1; LD_CC  = 1'b1;  GateALU = 1'b1;  DRMUX = 1'b0; SR1MUX = 1'b1; ALUK = 2'b10; end

			LDR3:  begin  LD_REG = 1'b1; LD_CC  = 1'b1;  GateMDR = 1'b1;  DRMUX = 1'b0; end
			LDR1:  begin  LD_MAR = 1'b1; GateMARMUX = 1'b1; ADDR1MUX = 1'b1; ADDR2MUX = 2'b01; SR1MUX = 1'b1; end
			STR1:  begin  LD_MAR = 1'b1; GateMARMUX = 1'b1; ADDR1MUX = 1'b1; ADDR2MUX = 2'b01; SR1MUX = 1'b1; end
			STR2:  begin  LD_MDR = 1'b1; GateALU = 1'b1; SR1MUX = 1'b0; ALUK = 2'b11; end

			JMP:   begin  LD_PC  = 1'b1; PCMUX  = 2'b10; ADDR1MUX = 1'b1; ADDR2MUX = 2'b00; SR1MUX = 1'b1; end
			JSR2:  begin  LD_PC  = 1'b1; PCMUX  = 2'b10; ADDR1MUX = 1'b0; ADDR2MUX = 2'b11; end
			BR2:   begin  LD_PC  = 1'b1; PCMUX  = 2'b10; ADDR1MUX = 1'b0; ADDR2MUX = 2'b10; end
			PSE1:  begin  LD_LED = 1'b1; GateMARMUX = 1'b1; MARMUX = 1'b1; end
			JSR1:  begin  LD_REG = 1'b1; GatePC  = 1'b1; DRMUX = 1'b1; end

			FCH1:  begin  LD_PC  = 1'b1; LD_MAR = 1'b1;  GatePC = 1'b1;   PCMUX = 2'b00; end
			FCH3:  begin  LD_IR  = 1'b1; GateMDR = 1'b1; end
			DEC:   begin  LD_BEN = 1'b1; end

			FCH2w, FCH2x,
			LDR2w, LDR2x: begin rden = 1'b1; end
			FCH2,  LDR2:  begin rden = 1'b1; LD_MDR = 1'b1; end
			STR3:         begin wren = 1'b1; end
			BR1, PSE2, HALT: ;
			default: ;
		endcase
	end

endmodule
