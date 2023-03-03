`include "top.sv"
`include "utils.sv"


module SLC3TopSynth (`TOP_INTERFACE);

	logic sRun, sContinue, sReset;
	logic rden, wren, wren_select, wren_from_ISDU;
	logic [15:0] addr, addr_init, addr_from_CPU;
	logic [15:0] data_init, data_from_SRAM, data_to_SRAM, data_from_CPU;

	always_comb begin
		if (wren_select) begin
			wren = wren_select;
			data_to_SRAM = data_init;
			addr = addr_init;
		end else begin
			wren = wren_from_ISDU;
			data_to_SRAM = data_from_CPU;
			addr = addr_from_CPU;
		end
	end

	SLC3 cpu (.*,
		.addr(addr_from_CPU), .data_to_SRAM(data_from_CPU),
		.rden, .wren(wren_from_ISDU),
		.Run(sRun), .Continue(sContinue), .Reset(sReset));
	MemSynth mem (.Clk,
		.addr_init, .data_init,
		.wren(wren_select), .Reset(sReset));
	ram ram0 (.clock(Clk),
		.data(data_to_SRAM), .address(addr[9:0]),
		.q(data_from_SRAM), .rden, .wren);
	SyncerFSM syncer (.*);

endmodule
