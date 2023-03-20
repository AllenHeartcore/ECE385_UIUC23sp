//SLC-3 Top level module for synthesis using physical RAM
//All synchronizers go here (both inputs and outputs)


module slc3_sramtop(
	input logic [9:0] SW,
	input logic	Clk, Run, Continue,
	output logic [9:0] LED,
	output logic [6:0] HEX0, HEX1, HEX2, HEX3
);

// Input button synchronizer to cross clock domain
logic RUN_S, CONTINUE_S;
logic RUN, CONTINUE;

sync button_sync[1:0] (Clk, {Run, Continue}, {RUN_S, CONTINUE_S});


assign RUN = RUN_S;
assign CONTINUE = CONTINUE_S;

// Declaration of push button active high signals	
logic Reset_ah, Continue_ah, Run_ah;
logic [15:0] Data_from_SRAM, Data_to_SRAM, init_data, Data_from_CPU;
logic [15:0] ADDR, init_ADDR, ADDR_from_CPU ;
logic OE, WE;
logic we_select, we_from_ISDU;



assign Run_ah = ~RUN;
assign Continue_ah = ~CONTINUE;
assign Reset_ah =  ~RUN & ~CONTINUE;


always_comb begin
	if(we_select)
		WE = we_select;
	else
		WE = we_from_ISDU;
end

always_comb begin
	if(we_select)
		Data_to_SRAM = init_data;
	else
		Data_to_SRAM = Data_from_CPU;
end

always_comb begin
	if(we_select)
		ADDR = init_ADDR;
	else
		ADDR = ADDR_from_CPU;
end


//sync_r1 sram_sync[4:0] (Clk, Reset_ah, {CE_S, UB_S, LB_S, OE_S, WE_S}, {CE, UB, LB, OE, WE});

slc3 slc(.Reset(Reset_ah), .Continue(Continue_ah), .Run(Run_ah), .WE(we_from_ISDU), .OE(OE), .Data_to_SRAM(Data_from_CPU), .ADDR(ADDR_from_CPU), .*);

Instantiateram instaRam(.Clk(Clk), .Reset(Reset_ah),.ADDR(init_ADDR), .data(init_data), .wren(we_select));

//This is the physical on-chip memory, consult the documentation regarding Megafunctions for a tutorial on how to generate this.
ram ram0(.address(ADDR[9:0]), .clock(Clk), .data(Data_to_SRAM),  .rden(OE), .wren(WE), .q(Data_from_SRAM)); 

endmodule
