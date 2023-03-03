module Mem2IO (
	input  logic rden, wren, Reset, Clk,
	input  logic [15:0] addr, data_from_CPU, data_from_SRAM,
	input  logic [9:0]  SW,
	output logic [15:0] data_to_CPU, data_to_SRAM,
	output logic [3:0]  hexvals[3:0]);

	logic [15:0] hex_data;

	always_comb begin
		data_to_CPU = 16'd0;
		if (~wren && rden)
			if (addr[15:0] == 16'hFFFF)
				data_to_CPU = {6'b000000, SW};
			else
				data_to_CPU = data_from_SRAM;
	end

	always_ff @ (posedge Clk) begin
		if (Reset)
			hex_data <= 16'd0;
		else if (wren && (addr[15:0] == 16'hFFFF))
			hex_data <= data_from_CPU;
	end

	assign hexvals[0] = hex_data[3:0];
	assign hexvals[1] = hex_data[7:4];
	assign hexvals[2] = hex_data[11:8];
	assign hexvals[3] = hex_data[15:12];
	assign data_to_SRAM = data_from_CPU;

endmodule
