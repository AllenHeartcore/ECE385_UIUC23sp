`include "slc3pkg.sv"
import SLC3_2::*;


module MemSim (
	input  logic rden, wren, Reset, Clk,
	input  logic [9:0]  addr,
	input  logic [15:0] data,
	output logic [15:0] readout);

	parameter memsize = 256;
	parameter external_init = 0;

	logic [15:0] mem_array[0:memsize-1];
	logic [15:0] mem_out;

	MemSimParser #(.memsize(memsize)) parser();

// synthesis translate_off

	initial begin
		parser.parse(mem_array);
		if (~external_init) begin
			integer fptr = $fopen("memsimparser.mif", "w");
			for (integer i = 0; i < memsize; i++) begin
				$fwrite(fptr, "@%0h %0h\n", i, mem_array[i]);
			end
			$fclose(fptr);
		end
		$readmemh("memsimparser.mif", mem_array, 0, memsize-1);
	end

	always @ (posedge Clk or posedge Reset) begin
		if (Reset) begin
			$readmemh("memsimparser.mif", mem_array, 0, memsize-1);
			mem_out <= 16'bX;
		end else if (rden && ~wren) begin
			mem_out <= mem_array[addr[7:0]];
		end else if (~rden && wren) begin
			mem_array[addr[7:0]] <= data;
			mem_out <= 16'bX;
		end else begin
			mem_out <= 16'bX;
		end
	end

	assign readout = mem_out;

// synthesis translate_on

endmodule


module MemSimParser;

	parameter memsize = 256;

	task parse(output logic[15:0] mem_array[0:memsize-1]);

		mem_array[   0 ] = opCLR(R0)            ;
		mem_array[   1 ] = opLDR(R1, R0, inSW)  ;
		mem_array[   2 ] = opJMP(R1)            ;

		/* Basic I/O test 1 */
		mem_array[   3 ] = opLDR(R1, R0, inSW)  ;
		mem_array[   4 ] = opSTR(R1, R0, outHEX);
		mem_array[   5 ] = opBR(nzp, -3)        ;

		/* Basic I/O test 2 */
		mem_array[   6 ] = opPSE(12'h801)       ;
		mem_array[   7 ] = opLDR(R1, R0, inSW)  ;
		mem_array[   8 ] = opSTR(R1, R0, outHEX);
		mem_array[   9 ] = opPSE(12'hC02)       ;
		mem_array[  10 ] = opBR(nzp, -4)        ;

		/* Basic I/O test 3 (Self-modifying code) */
		mem_array[  11 ] = opPSE(12'h801)       ;
		mem_array[  12 ] = opJSR(0)             ;
		mem_array[  13 ] = opLDR(R2,R7,3)       ;
		mem_array[  14 ] = opLDR(R1, R0, inSW)  ;
		mem_array[  15 ] = opSTR(R1, R0, outHEX);
		mem_array[  16 ] = opPSE(12'hC02)       ;
		mem_array[  17 ] = opINC(R2)            ;
		mem_array[  18 ] = opSTR(R2,R7,3)       ;
		mem_array[  19 ] = opBR(nzp, -6)        ;

		/* XOR test */
		mem_array[  20 ] = opCLR(R0)            ;
		mem_array[  21 ] = opPSE(12'h801)       ;
		mem_array[  22 ] = opLDR(R1, R0, inSW)  ;
		mem_array[  23 ] = opPSE(12'h802)       ;
		mem_array[  24 ] = opLDR(R2, R0, inSW)  ;
		mem_array[  25 ] = opNOT(R3, R1)        ;
		mem_array[  26 ] = opAND(R3, R3, R2)    ;
		mem_array[  27 ] = opNOT(R3, R3)        ;
		mem_array[  28 ] = opNOT(R4, R2)        ;
		mem_array[  29 ] = opAND(R4, R4, R1)    ;
		mem_array[  30 ] = opNOT(R4, R4)        ;
		mem_array[  31 ] = opAND(R3, R3, R4)    ;
		mem_array[  32 ] = opNOT(R3, R3)        ;
		mem_array[  33 ] = opSTR(R3, R0, outHEX);
		mem_array[  34 ] = opPSE(12'h405)       ;
		mem_array[  35 ] = opBR(nzp, -15)       ;
		mem_array[  36 ] = NO_OP                ;
		mem_array[  37 ] = NO_OP                ;
		mem_array[  38 ] = NO_OP                ;
		mem_array[  39 ] = NO_OP                ;
		mem_array[  40 ] = NO_OP                ;
		mem_array[  41 ] = NO_OP                ;

		/* Run once test (also for JMP) */
		mem_array[  42 ] = opCLR(R0)            ;
		mem_array[  43 ] = opCLR(R1)            ;
		mem_array[  44 ] = opJSR(0)             ;
		mem_array[  45 ] = opSTR(R1, R0, outHEX);
		mem_array[  46 ] = opPSE(12'h401)       ;
		mem_array[  47 ] = opINC(R1)            ;
		mem_array[  48 ] = opRET()              ;

		/* Multiplier Program */
		mem_array[  49 ] = opCLR(R0)            ;
		mem_array[  50 ] = opJSR(0)             ;
		mem_array[  51 ] = opLDR(R3, R7, 22)    ;
		mem_array[  52 ] = opCLR(R4)            ;
		mem_array[  53 ] = opCLR(R5)            ;
		mem_array[  54 ] = opPSE(12'h801)       ;
		mem_array[  55 ] = opLDR(R1, R0, inSW)  ;
		mem_array[  56 ] = opPSE(12'h802)       ;
		mem_array[  57 ] = opLDR(R2, R0, inSW)  ;
		mem_array[  58 ] = opADD(R5, R5, R5)    ;
		mem_array[  59 ] = opAND(R7, R3, R1)    ;
		mem_array[  60 ] = opBR(z, 1)           ;
		mem_array[  61 ] = opADD(R5, R5, R2)    ;
		mem_array[  62 ] = opADDi(R4, R4, 0)    ;
		mem_array[  63 ] = opBR(p,2)            ;
		mem_array[  64 ] = opNOT(R5, R5)        ;
		mem_array[  65 ] = opINC(R5)            ;
		mem_array[  66 ] = opINC(R4)            ;
		mem_array[  67 ] = opADD(R1, R1, R1)    ;
		mem_array[  68 ] = opADDi(R7, R4, -8)   ;
		mem_array[  69 ] = opBR(n, -12)         ;
		mem_array[  70 ] = opSTR(R5, R0, outHEX);
		mem_array[  71 ] = opPSE(12'h403)       ;
		mem_array[  72 ] = opBR(nzp, -21)       ;
		mem_array[  73 ] = 16'h0080             ;

		/* Data for Bubble Sort */
		mem_array[  74 ] = 16'h00EF             ;
		mem_array[  75 ] = 16'h001B             ;
		mem_array[  76 ] = 16'h0001             ;
		mem_array[  77 ] = 16'h008C             ;
		mem_array[  78 ] = 16'h00DB             ;
		mem_array[  79 ] = 16'h00FA             ;
		mem_array[  80 ] = 16'h0047             ;
		mem_array[  81 ] = 16'h0046             ;
		mem_array[  82 ] = 16'h001F             ;
		mem_array[  83 ] = 16'h000d             ;
		mem_array[  84 ] = 16'h00B8             ;
		mem_array[  85 ] = 16'h0003             ;
		mem_array[  86 ] = 16'h006B             ;
		mem_array[  87 ] = 16'h004E             ;
		mem_array[  88 ] = 16'h00F8             ;
		mem_array[  89 ] = 16'h0007             ;
		mem_array[  90 ] = opCLR(R0)            ;
		mem_array[  91 ] = opJSR(0)             ;
		mem_array[  92 ] = opADDi(R6, R7, -16)  ;
		mem_array[  93 ] = opADDi(R6, R6, -2)   ;
		mem_array[  94 ] = opPSE(12'hBFF)       ;
		mem_array[  95 ] = opLDR(R1, R0, inSW)  ;
		mem_array[  96 ] = opBR(z, -3)          ;
		mem_array[  97 ] = opDEC(R1)            ;
		mem_array[  98 ] = opBR(np, 2)          ;
		mem_array[  99 ] = opJSR(9)             ;
		mem_array[ 100 ] = opBR(nzp, -7)        ;
		mem_array[ 101 ] = opDEC(R1)            ;
		mem_array[ 102 ] = opBR(np, 2)          ;
		mem_array[ 103 ] = opJSR(15)            ;
		mem_array[ 104 ] = opBR(nzp, -11)       ;
		mem_array[ 105 ] = opDEC(R1)            ;
		mem_array[ 106 ] = opBR(np, -13)        ;
		mem_array[ 107 ] = opJSR(29)            ;
		mem_array[ 108 ] = opBR(nzp, -15)       ;
		mem_array[ 109 ] = opCLR(R1)            ;
		mem_array[ 110 ] = opSTR(R1, R0, outHEX);
		mem_array[ 111 ] = opPSE(12'hC01)       ;
		mem_array[ 112 ] = opLDR(R2, R0, inSW)  ;
		mem_array[ 113 ] = opADD(R5, R6, R1)    ;
		mem_array[ 114 ] = opSTR(R2, R5, 0)     ;
		mem_array[ 115 ] = opINC(R1)            ;
		mem_array[ 116 ] = opADDi(R3, R1, -16)  ;
		mem_array[ 117 ] = opBR(n, -8)          ;
		mem_array[ 118 ] = opRET()              ;
		mem_array[ 119 ] = opADDi(R1, R0, -16)  ;
		mem_array[ 120 ] = opADDi(R2, R0, 1)    ;
		mem_array[ 121 ] = opADD(R3, R6, R2)    ;
		mem_array[ 122 ] = opLDR(R4, R3, -1)    ;
		mem_array[ 123 ] = opLDR(R5, R3, 0)     ;
		mem_array[ 124 ] = opNOT(R5, R5)        ;
		mem_array[ 125 ] = opADDi(R5, R5, 1)    ;
		mem_array[ 126 ] = opADD(R5, R4, R5)    ;
		mem_array[ 127 ] = opBR(nz, 3)          ;
		mem_array[ 128 ] = opLDR(R5, R3, 0)     ;
		mem_array[ 129 ] = opSTR(R5, R3, -1)    ;
		mem_array[ 130 ] = opSTR(R4, R3, 0)     ;
		mem_array[ 131 ] = opINC(R2)            ;
		mem_array[ 132 ] = opADD(R3, R1, R2)    ;
		mem_array[ 133 ] = opBR(n, -13)         ;
		mem_array[ 134 ] = opINC(R1)            ;
		mem_array[ 135 ] = opBR(n, -16)         ;
		mem_array[ 136 ] = opRET()              ;
		mem_array[ 137 ] = opCLR(R1)            ;
		mem_array[ 138 ] = opADD(R4, R7, R0)    ;
		mem_array[ 139 ] = opJSR(0)             ;
		mem_array[ 140 ] = opADD(R5, R7, R0)    ;
		mem_array[ 141 ] = opADD(R7, R4, R0)    ;
		mem_array[ 142 ] = opLDR(R3, R5, 15)    ;
		mem_array[ 143 ] = opADDi(R2, R0, 8)    ;
		mem_array[ 144 ] = opADD(R2, R2, R2)    ;
		mem_array[ 145 ] = opADD(R4, R6, R1)    ;
		mem_array[ 146 ] = opLDR(R4, R4, 0)     ;
		mem_array[ 147 ] = opSTR(R4, R0, outHEX);
		mem_array[ 148 ] = opPSE(12'h402)       ;
		mem_array[ 149 ] = opADD(R3, R3, R2)    ;
		mem_array[ 150 ] = opSTR(R3, R5, 8)     ;
		mem_array[ 151 ] = opINC(R1)            ;
		mem_array[ 152 ] = opADDi(R4, R1, -16)  ;
		mem_array[ 153 ] = opBR(n, -9)          ;
		mem_array[ 154 ] = opRET()              ;
		mem_array[ 155 ] = opPSE(12'h802)       ;

		/* Auto counting test */
		mem_array[ 156 ] = opCLR(R0)            ;
		mem_array[ 157 ] = opCLR(R1)            ;
		mem_array[ 158 ] = opCLR(R2)            ;
		mem_array[ 159 ] = opCLR(R3)            ;
		mem_array[ 160 ] = opJSR(0)             ;
		// INIT:      (PC = 161)
		mem_array[ 161 ] = opLDR(R1, R7, 12)    ;
		mem_array[ 162 ] = opLDR(R2, R7, 13)    ;
		// 1ST LOOP:  (PC = 163)
		mem_array[ 163 ] = opDEC(R1)            ;
		mem_array[ 164 ] = opBR(z, 1)           ;
		mem_array[ 165 ] = opBR(nzp, -3)        ;
		// 2ND LOOP:  (PC = 166)
		mem_array[ 166 ] = opDEC(R2)            ;
		mem_array[ 167 ] = opBR(z, 2)           ;
		mem_array[ 168 ] = opLDR(R1, R7, 12)    ;
		mem_array[ 169 ] = opBR(nzp, -7)        ;
		// DISPLAY:   (PC = 170)
		mem_array[ 170 ] = opSTR(R3, R0, outHEX);
		mem_array[ 171 ] = opINC(R3)            ;
		mem_array[ 172 ] = opBR(nzp, -12)       ;
		// CONSTANTS: (PC = 173)
		mem_array[ 173 ] = 16'h3                ;
		mem_array[ 174 ] = 16'd3                ;

		/* Assign the rest of the memory to 0 */
		for (integer i = 175; i <= memsize - 1; i++) begin
			mem_array[i] = 16'h0;
		end

	endtask

endmodule
