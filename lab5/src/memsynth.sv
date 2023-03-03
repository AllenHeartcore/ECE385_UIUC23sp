`include "slc3pkg.sv"
import SLC3_2::*;


module MemSynth (
	input  logic Reset, Clk,
	output logic wren,
	output logic [15:0] addr_init, data_init);

	logic [15:0] addr;
	logic accum;

	enum logic [1:0] {idle, mem_write, done} state, next_state;

	always_ff @ (posedge Clk or posedge Reset) begin
		if (Reset) begin
			state <= mem_write;
			addr <= 16'h0;
		end else begin
			state <= next_state;
			if (accum)
				addr <= addr + 16'h1;
			else
				addr <= addr;
		end
	end

	always_comb begin

		next_state = state;
		wren = 1'b0;
		accum = 1'b0;

		unique case (state)
			idle: ;
			mem_write: begin
				if (addr == 16'hFF)
					next_state = done;
				else
					next_state = mem_write;
				wren = 1'b1;
				accum = 1'b1;
			end
			done: next_state = idle;
		endcase

		case (addr)

			16'd0:   data_init = opCLR(R0)            ;	// Clear the register so it can be used as a base
			16'd1:   data_init = opLDR(R1, R0, inSW)  ;	// Load switches
			16'd2:   data_init = opJMP(R1)            ;	// Jump to the start of a program

			/* Basic I/O test 1 */
			16'd3:   data_init = opLDR(R1, R0, inSW)  ;	// Load switches
			16'd4:   data_init = opSTR(R1, R0, outHEX);	// Output
			16'd5:   data_init = opBR(nzp, -3)        ;	// Repeat

			/* Basic I/O test 2 */
			16'd6:   data_init = opPSE(12'h801)       ;	// Checkpoint 1 - prepare to input
			16'd7:   data_init = opLDR(R1, R0, inSW)  ;	// Load switches
			16'd8:   data_init = opSTR(R1, R0, outHEX);	// Output
			16'd9:   data_init = opPSE(12'hC02)       ;	// Checkpoint 2 - read output, prepare to input
			16'd10:  data_init = opBR(nzp, -4)        ;	// Repeat

			/* Basic I/O test 3 (Self-modifying code) */
			16'd11:  data_init = opPSE(12'h801)       ;	// Checkpoint 1 - prepare to input
			16'd12:  data_init = opJSR(0)             ;	// Get PC addr
			16'd13:  data_init = opLDR(R2, R7, 3)     ;	// Load pause instruction as data
			16'd14:  data_init = opLDR(R1, R0, inSW)  ;	// Load switches
			16'd15:  data_init = opSTR(R1, R0, outHEX);	// Output
			16'd16:  data_init = opPSE(12'hC02)       ;	// Checkpoint 2 - read output, prepare to input
			16'd17:  data_init = opINC(R2)            ;	// Increment checkpoint number
			16'd18:  data_init = opSTR(R2, R7, 3)     ;	// Store new checkpoint instruction (self-modifying code)
			16'd19:  data_init = opBR(nzp, -6)        ;	// Repeat

			/* XOR test */
			16'd20:  data_init = opCLR(R0)            ;
			16'd21:  data_init = opPSE(12'h801)       ;	// Checkpoint 1 - prepare to input (upper)
			16'd22:  data_init = opLDR(R1, R0, inSW)  ;	// Load switches
			16'd23:  data_init = opPSE(12'h802)       ;	// Checkpoint 2 - prepare to input (lower)
			16'd24:  data_init = opLDR(R2, R0, inSW)  ;	// Load switches again
			16'd25:  data_init = opNOT(R3, R1)        ;	// R3: A'
			16'd26:  data_init = opAND(R3, R3, R2)    ;	// R3: A'B
			16'd27:  data_init = opNOT(R3, R3)        ;	// R3: (A'B)'
			16'd28:  data_init = opNOT(R4, R2)        ;	// R4: B'
			16'd29:  data_init = opAND(R4, R4, R1)    ;	// R4: B'A
			16'd30:  data_init = opNOT(R4, R4)        ;	// R4: (B'A)'
			16'd31:  data_init = opAND(R3, R3, R4)    ;	// R3: (A'B)'(B'A)'
			16'd32:  data_init = opNOT(R3, R3)        ;	// R3: ((A'B)'(B'A)')' XOR using only and-not
			16'd33:  data_init = opSTR(R3, R0, outHEX);	// Output
			16'd34:  data_init = opPSE(12'h405)       ;	// Checkpoint 5 - read output
			16'd35:  data_init = opBR(nzp, -15)       ;	// Repeat
			16'd36:  data_init = NO_OP                ;
			16'd37:  data_init = NO_OP                ;
			16'd38:  data_init = NO_OP                ;
			16'd39:  data_init = NO_OP                ;
			16'd40:  data_init = NO_OP                ;
			16'd41:  data_init = NO_OP                ;

			/* Run once test (also for JMP) */
			16'd42:  data_init = opCLR(R0)            ;
			16'd43:  data_init = opCLR(R1)            ;	// clear R1
			16'd44:  data_init = opJSR(0)             ;	// get jumpback addr
			16'd45:  data_init = opSTR(R1, R0, outHEX);	// output R1; LOOP DEST
			16'd46:  data_init = opPSE(12'h401)       ;	// Checkpoint 1 - read output
			16'd47:  data_init = opINC(R1)            ;	// increment R1
			16'd48:  data_init = opRET()              ;	// repeat

			/* Multiplier Program */
			16'd49:  data_init = opCLR(R0)            ;
			16'd50:  data_init = opJSR(0)             ;	// R7 <- PC (for loading bit test mask)
			16'd51:  data_init = opLDR(R3, R7, 22)    ;	// load mask;
			16'd52:  data_init = opCLR(R4)            ;	// clear R4 (iteration tracker),  ; START
			16'd53:  data_init = opCLR(R5)            ;	// R5 (running total)
			16'd54:  data_init = opPSE(12'h801)       ;	// Checkpoint 1 - prepare to input
			16'd55:  data_init = opLDR(R1, R0, inSW)  ;	// Input operand 1
			16'd56:  data_init = opPSE(12'h802)       ;	// Checkpoint 2 - prepare to input
			16'd57:  data_init = opLDR(R2, R0, inSW)  ;	// Input operand 2
			16'd58:  data_init = opADD(R5, R5, R5)    ;	// shift running total; LOOP DEST
			16'd59:  data_init = opAND(R7, R3, R1)    ;	// apply mask
			16'd60:  data_init = opBR(z, 1)           ;	// test bit and jump over...
			16'd61:  data_init = opADD(R5, R5, R2)    ;	// ... the addition
			16'd62:  data_init = opADDi(R4, R4, 0)    ;	// test iteration = = 0 (first iteration)
			16'd63:  data_init = opBR(p, 2)           ;	// if not first iteration, jump over negation
			16'd64:  data_init = opNOT(R5, R5)        ;	// 2's compliment negate R5
			16'd65:  data_init = opINC(R5)            ;	//   (part of above)
			16'd66:  data_init = opINC(R4)            ;	// increment iteration
			16'd67:  data_init = opADD(R1, R1, R1)    ;	// shift operand 1 for mask comparisons
			16'd68:  data_init = opADDi(R7, R4, -8)   ;	// test for last iteration
			16'd69:  data_init = opBR(n, -12)         ;	// branch back to LOOP DEST if iteration < 7
			16'd70:  data_init = opSTR(R5, R0, outHEX);	// Output result
			16'd71:  data_init = opPSE(12'h403)       ;	// Checkpoint 3 - read output
			16'd72:  data_init = opBR(nzp, -21)       ;	// loop back to start
			16'd73:  data_init = 16'h0080             ;	// bit test mask

			/* Data for Bubble Sort */
			16'd74:  data_init = 16'h00EF             ;
			16'd75:  data_init = 16'h001B             ;
			16'd76:  data_init = 16'h0001             ;
			16'd77:  data_init = 16'h008C             ;
			16'd78:  data_init = 16'h00DB             ;
			16'd79:  data_init = 16'h00FA             ;
			16'd80:  data_init = 16'h0047             ;
			16'd81:  data_init = 16'h0046             ;
			16'd82:  data_init = 16'h001F             ;
			16'd83:  data_init = 16'h000D             ;
			16'd84:  data_init = 16'h00B8             ;
			16'd85:  data_init = 16'h0003             ;
			16'd86:  data_init = 16'h006B             ;
			16'd87:  data_init = 16'h004E             ;
			16'd88:  data_init = 16'h00F8             ;
			16'd89:  data_init = 16'h0007             ;

			/* Bubblesort Program */
			16'd90:  data_init = opCLR(R0)            ;
			16'd91:  data_init = opJSR(0)             ;
			16'd92:  data_init = opADDi(R6, R7, -16)  ;	// Store data location in R6
			16'd93:  data_init = opADDi(R6, R6, -2)   ;	//   (data location is 18 above the addr from JSR)
			16'd94:  data_init = opPSE(12'hBFF)       ;	// Checkpoint -1 - select function; LOOP DEST
			16'd95:  data_init = opLDR(R1, R0, inSW)  ;
			16'd96:  data_init = opBR(z, -3)          ;	// If 0, retry
			16'd97:  data_init = opDEC(R1)            ;
			16'd98:  data_init = opBR(np, 2)          ;	// if selection wasn't 1, jump over
			16'd99:  data_init = opJSR(9)             ;	//   ...call to entry function
			16'd100: data_init = opBR(nzp, -7)        ;
			16'd101: data_init = opDEC(R1)            ;
			16'd102: data_init = opBR(np, 2)          ;	// if selection wasn't 2, jump over
			16'd103: data_init = opJSR(15)            ;	//   ...call to sort function
			16'd104: data_init = opBR(nzp, -11)       ;
			16'd105: data_init = opDEC(R1)            ;
			16'd106: data_init = opBR(np, -13)        ;	// if selection wasn't 3, retry
			16'd107: data_init = opJSR(29)            ;	//   call to display function
			16'd108: data_init = opBR(nzp, -15)       ;	// repeat menu
			16'd109: data_init = opCLR(R1)            ;	// ENTRY FUNCTION
			16'd110: data_init = opSTR(R1, R0, outHEX);	// R5 is temporary index into data; R1 is counter; LOOP DEST
			16'd111: data_init = opPSE(12'hC01)       ;	// Checkpoint 1 - read data (index) and write new value
			16'd112: data_init = opLDR(R2, R0, inSW)  ;
			16'd113: data_init = opADD(R5, R6, R1)    ;	// generate pointer to data
			16'd114: data_init = opSTR(R2, R5, 0)     ;	// store data
			16'd115: data_init = opINC(R1)            ;	// increment counter
			16'd116: data_init = opADDi(R3, R1, -16)  ;	// test for counter = = 16
			16'd117: data_init = opBR(n, -8)          ;	// less than 16, repeat
			16'd118: data_init = opRET()              ;	// ENTRY FUNCTION RETURN
			16'd119: data_init = opADDi(R1, R0, -16)  ;	// i = -16; SORT FUNCTION
			16'd120: data_init = opADDi(R2, R0, 1)    ;	// j = 1; OUTER LOOP DEST
			16'd121: data_init = opADD(R3, R6, R2)    ;	// generate pointer to data; INNER LOOP DEST
			16'd122: data_init = opLDR(R4, R3, -1)    ;	// R4 = data[j-1]
			16'd123: data_init = opLDR(R5, R3, 0)     ;	// R5 = data[j]
			16'd124: data_init = opNOT(R5, R5)        ;
			16'd125: data_init = opADDi(R5, R5, 1)    ;	// R5 = -data[j]
			16'd126: data_init = opADD(R5, R4, R5)    ;	// R5 = data[j-1]-data[j]
			16'd127: data_init = opBR(nz, 3)          ;	// if data[j-1] > data[j]
			16'd128: data_init = opLDR(R5, R3, 0)     ;	// { R5 = data[j]
			16'd129: data_init = opSTR(R5, R3, -1)    ;	//   data[j-1] = data[j]
			16'd130: data_init = opSTR(R4, R3, 0)     ;	//   data[j] = R4 } // old data[j-1]
			16'd131: data_init = opINC(R2)            ;
			16'd132: data_init = opADD(R3, R1, R2)    ;	// Compare i and j
			16'd133: data_init = opBR(n, -13)         ;	// INNER LOOP BACK
			16'd134: data_init = opINC(R1)            ;
			16'd135: data_init = opBR(n, -16)         ;	// OUTER LOOP BACK
			16'd136: data_init = opRET()              ;	// SORT FUNCTION RETURN
			16'd137: data_init = opCLR(R1)            ;	// DISPLAY FUNCTION
			16'd138: data_init = opADD(R4, R7, R0)    ;	// JSR shuffle to get PC value in R5
			16'd139: data_init = opJSR(0)             ;
			16'd140: data_init = opADD(R5, R7, R0)    ;
			16'd141: data_init = opADD(R7, R4, R0)    ;	// shuffle done
			16'd142: data_init = opLDR(R3, R5, 15)    ;	// R3 = opPSE(12'b802)
			16'd143: data_init = opADDi(R2, R0, 8)    ;
			16'd144: data_init = opADD(R2, R2, R2)    ;	// R2 = 16
			16'd145: data_init = opADD(R4, R6, R1)    ;	// generate pointer to data; LOOP DEST
			16'd146: data_init = opLDR(R4, R4, 0)     ;	// load data
			16'd147: data_init = opSTR(R4, R0, outHEX);	// display data
			16'd148: data_init = opPSE(12'h402)       ;	// Checkpoint 2 - read data (self-modified instruction)
			16'd149: data_init = opADD(R3, R3, R2)    ;	// modify register with code
			16'd150: data_init = opSTR(R3, R5, 8)     ;	// store modified code
			16'd151: data_init = opINC(R1)            ;	// increment counter
			16'd152: data_init = opADDi(R4, R1, -16)  ;	// test for counter = = 16
			16'd153: data_init = opBR(n, -9)          ;	// less than 16, repeat
			16'd154: data_init = opRET()              ;	// DISPLAY FUNCTION RETURN
			16'd155: data_init = opPSE(12'h802)       ;	//    instruction as data

			/* Auto counter program */
			16'd156: data_init = opCLR(R0)            ;	// R0 = 0
			16'd157: data_init = opCLR(R1)            ;	// R1 = 0  (R1 will be used as loop counter 1)
			16'd158: data_init = opCLR(R2)            ;	// R2 = 0  (R2 will be used as loop counter 2)
			16'd159: data_init = opCLR(R3)            ;	// R3 = 0  (R3 will be displayed to hex displays)
			16'd160: data_init = opJSR(0)             ;	// R7 <- PC = 161 (161 because PC <- PC+1 after fetch)
			// INIT:      (PC = 161)
			16'd161: data_init = opLDR(R1, R7, 12)    ;	// R1 <- xFFFF
			16'd162: data_init = opLDR(R2, R7, 13)    ;	// R2 <- d5
			// 1ST LOOP:  (PC = 163)
			16'd163: data_init = opDEC(R1)            ;	// Decrement first loop counter
			16'd164: data_init = opBR(z, 1)           ;	// (Go to 2ND LOOP) - R1 = 0, go to second loop
			16'd165: data_init = opBR(nzp, -3)        ;	// (Go to 1ST LOOP) - R1 != 0, repeat first loop
			// 2ND LOOP:  (PC = 166)
			16'd166: data_init = opDEC(R2)            ;	// Decrement second loop counter
			16'd167: data_init = opBR(z, 2)           ;	// (Go to DISPLAY) -  R2 = 0, show new number on hex displays
			16'd168: data_init = opLDR(R1, R7, 12)    ;	// R1 <- xFFFF (reset loop 1 counter)
			16'd169: data_init = opBR(nzp, -7)        ;	// (Go to 1ST LOOP) - R2 != 0, repeat first loop
			// DISPLAY:   (PC = 170)
			16'd170: data_init = opSTR(R3, R0, outHEX);	// Display counter to hex display
			16'd171: data_init = opINC(R3)            ;
			16'd172: data_init = opBR(nzp, -12)       ;	// (Go to INIT) - Repeat double for loop counting
			// CONSTANTS: (PC = 173)
			16'd173: data_init = 16'hFFFF             ;	// Constant for loading into R1 for counting/delay purposes xFFFF
			16'd174: data_init = 16'd5                ;	// Constant for loading into R2 for counting/delay purposes d750

			/* initialize with zero */
			default: data_init = 16'h0000             ;
		endcase

	end

	assign addr_init = addr;

endmodule
