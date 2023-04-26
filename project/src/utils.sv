`ifndef __UTILS__
`define __UTILS__


/* Region Definition */
`define VGA_MAX_X		10'd800
`define VGA_MAX_Y		10'd525
`define VGA_DISP_X		10'd639
`define VGA_DISP_Y		10'd480
`define VGA_HSYNC_START	10'd656
`define VGA_HSYNC_END	10'd752
`define VGA_VSYNC_START	10'd490
`define VGA_VSYNC_END	10'd492

`define BG_X_SIZE       10'd213
`define BG_Y_SIZE       10'd160

`define FIG_X_START     10'd384
`define FIG_X_SIZE      10'd128
`define FIG_Y_START_F   10'd112
`define FIG_Y_START_H   10'd384
`define FIG_Y_SIZE      10'd256

`define KBD_X_START     10'd12
`define KBD_X_END       10'd628
`define KBD_Y_START     10'd128
`define KBD_Y_END       10'd352

`define GAUGE_X_START   10'd368
`define GAUGE_Y_START_L 10'd68
`define GAUGE_Y_END_L   10'd76
`define GAUGE_Y_START_S 10'd84
`define GAUGE_Y_END_S   10'd92

`define GST_STATE_IDLE   2'd0
`define GST_STATE_CONFIG 2'd1
`define GST_STATE_PLAY   2'd2
`define GST_STATE_REPORT 2'd3


module HexDriver (
	input  logic [3:0] in,
	output logic [6:0] out);

	always_comb begin
		unique case (in)
			4'b0000: out = 7'b1000000;
			4'b0001: out = 7'b1111001;
			4'b0010: out = 7'b0100100;
			4'b0011: out = 7'b0110000;
			4'b0100: out = 7'b0011001;
			4'b0101: out = 7'b0010010;
			4'b0110: out = 7'b0000010;
			4'b0111: out = 7'b1111000;
			4'b1000: out = 7'b0000000;
			4'b1001: out = 7'b0010000;
			4'b1010: out = 7'b0001000;
			4'b1011: out = 7'b0000011;
			4'b1100: out = 7'b1000110;
			4'b1101: out = 7'b0100001;
			4'b1110: out = 7'b0000110;
			4'b1111: out = 7'b0001110;
			default: out = 7'bX;
		endcase
	end

endmodule

`endif
