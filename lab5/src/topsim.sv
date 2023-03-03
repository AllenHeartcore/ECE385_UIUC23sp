`include "top.sv"
`include "utils.sv"


module SLC3TopSim (`TOP_INTERFACE);

	logic sRun, sContinue, sReset;
	logic rden, wren;
	logic [15:0] addr;
	logic [15:0] data_from_SRAM, data_to_SRAM;

	SLC3 cpu (.*,
		.Run(sRun), .Continue(sContinue), .Reset(sReset));
	MemSim mem (.Clk,
		.data(data_to_SRAM), .addr(addr[9:0]),
		.readout(data_from_SRAM),
		.rden, .wren, .Reset(sReset));
	SyncerFSM syncer (.*);

endmodule
