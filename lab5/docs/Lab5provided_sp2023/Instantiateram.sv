//------------------------------------------------------------------------------
// Company: 		 UIUC ECE Dept.
// Engineer:		 Xinying Wang
//
// Create Date:    
// Design Name:    ECE 385 instantiate on-chip memory
// Module Name:    SLC3
//
// Comments:
//    Created 06-07-2020 
//    Revised 07-15-2022 by Nicholas Satchanov (Added auto counter program)

//------------------------------------------------------------------------------

`include "SLC3_2.sv"
import SLC3_2::*;

module Instantiateram( input Reset,
							  input Clk,
							  output logic [15:0] ADDR,
							  output logic wren,
							  output logic [15:0] data);
							
	 

    logic [15:0] mem_out;
	 logic [15:0] address;
	 logic [15:0] q;
	 logic accumulate;
	 
	 enum logic [1:0] {idle, mem_write, done} state, next_state;



		  
	 always_ff@(posedge Clk or posedge Reset) 
		begin
			if (Reset)
				state <= mem_write;
			else
				state <= next_state;
		end
	 
	 
	 always_ff@(posedge Clk or posedge Reset)
		begin
			if (Reset)
				address <= 16'h0;
			else if (accumulate)

					address <= address + 1;
				
			else
				address <= address;
			
		end
	 
	 always_comb begin
	 
		  next_state = state;
		  
		  unique case(state)
		  idle: ;
		  mem_write: begin
			  if(address == 16'hff)
					next_state = done;
				else
					next_state = mem_write;
				end
		  done:
				next_state = idle;

		 endcase
		 
	 end
	 
	 always_comb begin
				wren = 1'b0;
				accumulate = 1'b0;
	 
			unique case(state)
				idle: ;

				mem_write:begin
					wren = 1'b1;
					accumulate = 1'b1;
				end
				done:;
			endcase
		end
		
	always_comb begin
		case(address)

			16'd0: data =   opCLR(R0)                ;       // Clear the register so it can be used as a base
			16'd1: data =    opLDR(R1, R0, inSW)      ;       // Load switches
			16'd2: data =    opJMP(R1)                ;       // Jump to the start of a program
			
			
																					// Basic I/O test 1
			16'd3: data =     opLDR(R1, R0, inSW)      ;       // Load switches
			16'd4: data =     opSTR(R1, R0, outHEX)    ;       // Output
			16'd5: data =    opBR(nzp, -3)            ;       // Repeat
                                                // Basic I/O test 2
			16'd6: data =    opPSE(12'h801)           ;       // Checkpoint 1 - prepare to input
			16'd7: data =    opLDR(R1, R0, inSW)      ;       // Load switches
			16'd8: data =    opSTR(R1, R0, outHEX)    ;       // Output
			16'd9: data =    opPSE(12'hC02)           ;       // Checkpoint 2 - read output, prepare to input
			16'd10: data =    opBR(nzp, -4)            ;       // Repeat
                                        
                                                        // Basic I/O test 3 (Self-modifying code)
			16'd11: data =    opPSE(12'h801)           ;       // Checkpoint 1 - prepare to input
			16'd12: data =    opJSR(0)                 ;       // Get PC address
			16'd13: data =    opLDR(R2,R7,3)           ;       // Load pause instruction as data
			16'd14: data =    opLDR(R1, R0, inSW)      ;       // Load switches
			16'd15: data =    opSTR(R1, R0, outHEX)    ;       // Output
			16'd16: data =    opPSE(12'hC02)           ;       // Checkpoint 2 - read output, prepare to input
			16'd17: data =    opINC(R2)                ;       // Increment checkpoint number
			16'd18: data =    opSTR(R2,R7,3)           ;       // Store new checkpoint instruction (self-modifying code)
			16'd19: data =    opBR(nzp, -6)            ;       // Repeat
                                  
			16'd20: data =    opCLR(R0)                ;       // XOR test
			16'd21: data =    opPSE(12'h801)           ;       // Checkpoint 1 - prepare to input (upper)
			16'd22: data =    opLDR(R1, R0, inSW)      ;       // Load switches
			16'd23: data =    opPSE(12'h802)           ;       // Checkpoint 2 - prepare to input (lower)
			16'd24: data =    opLDR(R2, R0, inSW)      ;       // Load switches again
			16'd25: data =    opNOT(R3, R1)            ;       // R3: A'
			16'd26: data =    opAND(R3, R3, R2)        ;       // R3: A'B
			16'd27: data =    opNOT(R3, R3)            ;       // R3: (A'B)'
			16'd28: data =    opNOT(R4, R2)            ;       // R4: B'
			16'd29: data =    opAND(R4, R4, R1)        ;       // R4: B'A
			16'd30: data =    opNOT(R4, R4)            ;       // R4: (B'A)'
			16'd31: data =    opAND(R3, R3, R4)        ;       // R3: (A'B)'(B'A)'
			16'd32: data =    opNOT(R3, R3)            ;       // R3: ((A'B)'(B'A)')' XOR using only and-not 
			16'd33: data =    opSTR(R3, R0, outHEX)    ;       // Output
			16'd34: data =    opPSE(12'h405)           ;       // Checkpoint 5 - read output
			16'd35: data =    opBR(nzp, -15)           ;       // Repeat
			16'd36: data =    NO_OP		               ;       // Place Holder  
			16'd37: data =    NO_OP		               ;       // Place Holder  
			16'd38: data =    NO_OP		               ;       // Place Holder  
			16'd39: data =    NO_OP		               ;       // Place Holder  
			16'd40: data =    NO_OP		               ;       // Place Holder  
			16'd41: data =    NO_OP		               ;       // Place Holder  
                               
			16'd42: data =    opCLR(R0)                ;       // Run once test (also for JMP)
			16'd43: data =    opCLR(R1)                ;       // clear R1
			16'd44: data =    opJSR(0)                 ;       // get jumpback address
			16'd45: data =    opSTR(R1, R0, outHEX)    ;       // output R1; LOOP DEST
			16'd46: data =    opPSE(12'h401)           ;       // Checkpoint 1 - read output
			16'd47: data =    opINC(R1)                ;       // increment R1
			16'd48: data =    opRET                    ;       // repeat
                               
			16'd49: data =    opCLR(R0)                ;       // Multiplier Program
			16'd50: data =    opJSR(0)                 ;       // R7 <- PC (for loading bit test mask)
			16'd51: data =    opLDR(R3, R7, 22)        ;       // load mask;
			16'd52: data =    opCLR(R4)                ;       // clear R4 (iteration tracker),  ; START
			16'd53: data =    opCLR(R5)                ;       // R5 (running total)
			16'd54: data =    opPSE(12'h801)           ;       // Checkpoint 1 - prepare to input
			16'd55: data =    opLDR(R1, R0, inSW)      ;       // Input operand 1
			16'd56: data =    opPSE(12'h802)           ;       // Checkpoint 2 - prepare to input
			16'd57: data =    opLDR(R2, R0, inSW)      ;       // Input operand 2
			16'd58: data =    opADD(R5, R5, R5)        ;       // shift running total; LOOP DEST
			16'd59: data =    opAND(R7, R3, R1)        ;       // apply mask
			16'd60: data =    opBR(z, 1)               ;       // test bit and jump over...
			16'd61: data =    opADD(R5, R5, R2)        ;       // ... the addition
			16'd62: data =    opADDi(R4, R4, 0)        ;       // test iteration == 0 (first iteration)
			16'd63: data =    opBR(p,2)                ;       // if not first iteration, jump over negation
			16'd64: data =    opNOT(R5, R5)            ;       // 2's compliment negate R5
			16'd65: data =    opINC(R5)                ;       //   (part of above)
			16'd66: data =    opINC(R4)                ;       // increment iteration
			16'd67: data =    opADD(R1, R1, R1)        ;       // shift operand 1 for mask comparisons
			16'd68: data =    opADDi(R7, R4, -8)       ;       // test for last iteration
			16'd69: data =    opBR(n, -12)             ;       // branch back to LOOP DEST if iteration < 7
			16'd70: data =    opSTR(R5, R0, outHEX)    ;       // Output result
			16'd71: data =    opPSE(12'h403)           ;       // Checkpoint 3 - read output
			16'd72: data =    opBR(nzp, -21)           ;       // loop back to start
			16'd73: data =    16'h0080                 ;       // bit test mask
                               
			16'd74: data =    16'h00ef                  ;       // Data for Bubble Sort
			16'd75: data =    16'h001b                  ;       
			16'd76: data =    16'h0001                  ;       
			16'd77: data =    16'h008c                  ;       
			16'd78: data =    16'h00db                  ;       
			16'd79: data =    16'h00fa                  ;       
			16'd80: data =    16'h0047                  ;       
			16'd81: data =    16'h0046                  ;       
			16'd82: data =    16'h001f                  ;       
			16'd83: data =    16'h000d                  ;       
			16'd84: data =    16'h00b8                  ;       
			16'd85: data =    16'h0003                  ;       
			16'd86: data =    16'h006b                  ;       
			16'd87: data =    16'h004e                  ;       
			16'd88: data =    16'h00f8                  ;       
			16'd89: data =    16'h0007                  ;       
			16'd90: data =    opCLR(R0)                ;       // Bubblesort Program start
			16'd91: data =    opJSR(0)                 ;       
			16'd92: data =    opADDi(R6, R7, -16)      ;       // Store data location in R6
			16'd93: data =    opADDi(R6, R6, -2)       ;       //   (data location is 18 above the address from JSR)
			16'd94: data =    opPSE(12'h3FF)           ;       // Checkpoint -1 - select function; LOOP DEST
			16'd95: data =    opLDR(R1, R0, inSW)      ;       
			16'd96: data =    opBR(z, -3)              ;       // If 0, retry
			16'd97: data =    opDEC(R1)                ;       
			16'd98: data =    opBR(np, 2)              ;       // if selection wasn't 1, jump over�
			16'd99: data =    opJSR(9)                 ;       //   ...call to entry function
			16'd100: data =    opBR(nzp, -7)            ;       
			16'd101: data =    opDEC(R1)                ;       
			16'd102: data =    opBR(np, 2)              ;       // if selection wasn't 2, jump over�
			16'd103: data =    opJSR(15)                ;       //   ...call to sort function
			16'd104: data =    opBR(nzp, -11)           ;       
			16'd105: data =    opDEC(R1)                ;       
			16'd106: data =    opBR(np, -13)            ;       // if selection wasn't 3, retry
			16'd107: data =    opJSR(29)                ;       //   call to display function
			16'd108: data =   opBR(nzp, -15)           ;       // repeat menu
			16'd109: data =    opCLR(R1)                ;       // ENTRY FUNCTION
			16'd110: data =    opSTR(R1, R0, outHEX)    ;       // R5 is temporary index into data; R1 is counter; LOOP DEST
			16'd111: data =    opPSE(12'hC01)           ;       // Checkpoint 1 - read data (index) and write new value
			16'd112: data =    opLDR(R2, R0, inSW)      ;       
			16'd113: data =    opADD(R5, R6, R1)        ;       // generate pointer to data
			16'd114: data =    opSTR(R2, R5, 0)         ;       // store data
			16'd115: data =    opINC(R1)                ;       // increment counter
			16'd116: data =    opADDi(R3, R1, -16)      ;       // test for counter == 16
			16'd117: data =    opBR(n, -8)              ;       // less than 16, repeat
			16'd118: data =    opRET                    ;       // ENTRY FUNCTION RETURN
			16'd119: data =    opADDi(R1, R0, -16)      ;       // i = -16; SORT FUNCTION
			16'd120: data =    opADDi(R2, R0, 1)        ;       // j = 1; OUTER LOOP DEST
			16'd121: data =    opADD(R3, R6, R2)        ;       // generate pointer to data; INNER LOOP DEST
			16'd122: data =    opLDR(R4, R3, -1)        ;       // R4 = data[j-1]
			16'd123: data =    opLDR(R5, R3, 0)         ;       // R5 = data[j]
			16'd124: data =    opNOT(R5, R5)            ;       
			16'd125: data =    opADDi(R5, R5, 1)        ;       // R5 = -data[j]
			16'd126: data =    opADD(R5, R4, R5)        ;       // R5 = data[j-1]-data[j]
			16'd127: data =    opBR(nz, 3)              ;       // if data[j-1] > data[j]
			16'd128: data =    opLDR(R5, R3, 0)         ;       // { R5 = data[j]
			16'd129: data =    opSTR(R5, R3, -1)        ;       //   data[j-1] = data[j]
			16'd130: data =    opSTR(R4, R3, 0)         ;       //   data[j] = R4 } // old data[j-1]
			16'd131: data =    opINC(R2)                ;
			16'd132: data =    opADD(R3, R1, R2)        ;       // Compare i and j
			16'd133: data =    opBR(n, -13)             ;       // INNER LOOP BACK
			16'd134: data =    opINC(R1)                ;       
			16'd135: data =    opBR(n, -16)             ;       // OUTER LOOP BACK
			16'd136: data =    opRET                    ;       // SORT FUNCTION RETURN
			16'd137: data =    opCLR(R1)                ;       // DISPLAY FUNCTION
			16'd138: data =    opADD(R4, R7, R0)        ;       // JSR shuffle to get PC value in R5
			16'd139: data =    opJSR(0)                 ;       
			16'd140: data =    opADD(R5, R7, R0)        ;       
			16'd141: data =    opADD(R7, R4, R0)        ;       // shuffle done
			16'd142: data =    opLDR(R3, R5, 15)        ;       // R3 = opPSE(12'b802)
			16'd143: data =    opADDi(R2, R0, 8)        ;       
			16'd144: data =    opADD(R2, R2, R2)        ;       // R2 = 16
			16'd145: data =    opADD(R4, R6, R1)        ;       // generate pointer to data; LOOP DEST
			16'd146: data =    opLDR(R4, R4, 0)         ;       // load data
			16'd147: data =    opSTR(R4, R0, outHEX)    ;       // display data
			16'd148: data =    opPSE(12'h802)           ;       // Checkpoint 2 - read data (self-modified instruction)
			16'd149: data =    opADD(R3, R3, R2)        ;       // modify register with code
			16'd150: data =    opSTR(R3, R5, 8)         ;       // store modified code
			16'd151: data =    opINC(R1)                ;       // increment counter
			16'd152: data =    opADDi(R4, R1, -16)      ;       // test for counter == 16
			16'd153: data =    opBR(n, -9)              ;       // less than 16, repeat
			16'd154: data =    opRET                    ;       // DISPLAY FUNCTION RETURN
			16'd155: data =    opPSE(12'h802)           ;       //    instruction as data
		
																	          // Auto counter program
			16'd156: data =    opCLR(R0)                ;       // R0 = 0
			16'd157: data =    opCLR(R1)                ;       // R1 = 0  (R1 will be used as loop counter 1)
			16'd158: data =    opCLR(R2)                ;       // R2 = 0  (R2 will be used as loop counter 2)
			16'd159: data =    opCLR(R3)                ;       // R3 = 0  (R3 will be displayed to hex displays)
			16'd160: data =    opJSR(0)					;       // R7 <- PC = 161 (161 because PC <- PC+1 after fetch)
			// INIT:      (PC = 161)
			16'd161: data =    opLDR(R1, R7, 12)        ;       // R1 <- xFFFF
			16'd162: data =    opLDR(R2, R7, 13)        ;       // R2 <- d5
			// 1ST LOOP:  (PC = 163)
			16'd163: data =    opDEC(R1)                ;       // Decrement first loop counter
			16'd164: data =    opBR(z, 1)               ;       // (Go to 2ND LOOP) - R1 =  0, go to second loop
			16'd165: data =    opBR(nzp, -3)            ;       // (Go to 1ST LOOP) - R1 != 0, repeat first loop
			// 2ND LOOP:  (PC = 166)
			16'd166: data =    opDEC(R2)                ;       // Decrement second loop counter
			16'd167: data =    opBR(z, 2)               ;       // (Go to DISPLAY) -  R2 = 0, show new number on hex displays
			16'd168: data =    opLDR(R1, R7, 12)        ;       // R1 <- xFFFF (reset loop 1 counter)
			16'd169: data =    opBR(nzp, -7)            ;	    // (Go to 1ST LOOP) - R2 != 0, repeat first loop
			// DISPLAY:   (PC = 170)
			16'd170: data =    opSTR(R3, R0, outHEX)    ;       // Display counter to hex display
			16'd171: data =    opINC(R3)                ;
			16'd172: data =    opBR(nzp, -12)           ;       // (Go to INIT) - Repeat double for loop counting
			// CONSTANTS: (PC = 173)
			16'd173: data =     16'hFFFF                ;       // Constant for loading into R1 for counting/delay purposes xFFFF
			16'd174: data =     16'd5                   ;       // Constant for loading into R2 for counting/delay purposes d750
		
			
			default: data =    16'h0000                 ;       //initialize with zero
	endcase
end
	
	
assign ADDR = address;		

endmodule