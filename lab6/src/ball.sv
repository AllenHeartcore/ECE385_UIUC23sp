`include "utils.sv"

module Ball (
	input  logic frame_clk, Reset,
	input  logic [7:0] keycode,
	output logic [9:0] BallX, BallY, BallS);

	logic [9:0] BallX_speed, BallY_speed;

	assign BallS = 4;

	always_ff @ (posedge Reset or posedge frame_clk) begin

		if (Reset) begin
			BallX <= `BALL_CENTER_X;
			BallY <= `BALL_CENTER_Y;
			BallX_speed <= 10'd0;
			BallY_speed <= 10'd0;
		end else begin

			if (BallY - BallS <= 0)							// bounce at top edge
				BallY_speed <= `BALL_STEP_Y;
			else if (BallY + BallS >= `VGA_DISP_Y - 1)		// bounce at bottom edge
				BallY_speed <= ~ (`BALL_STEP_Y) + 1'b1;
			else if (BallX - BallS <= 0)					// bounce at left edge
				BallX_speed <= `BALL_STEP_X;
			else if (BallX + BallS >= `VGA_DISP_X - 1)		// bounce at right edge
				BallX_speed <= ~ (`BALL_STEP_X) + 1'b1;
			else begin

				BallX_speed <= BallX_speed;					// keep moving
				BallY_speed <= BallY_speed;
				case (keycode)
					8'h1A: begin BallX_speed <=  0; BallY_speed <= -1; end	// W
					8'h16: begin BallX_speed <=  0; BallY_speed <=  1; end	// S
					8'h04: begin BallX_speed <= -1; BallY_speed <=  0; end	// A
					8'h07: begin BallX_speed <=  1; BallY_speed <=  0; end	// D
					default: ;
				endcase
			end

			BallX <= BallX + BallX_speed;	// update position
			BallY <= BallY + BallY_speed;

		end
	end

endmodule
