//-------------------------------------------------------------------------
//      test_memory.vhd                                                  --
//      Stephen Kempf                                                    --
//      Summer 2005                                                      --
//                                                                       --
//      Revised 3-15-2006                                                --
//              3-22-2007                                                --
//              7-26-2013                                                --
//                                                                       --
//      For use with ECE 385 Experment 6                                 --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------

// This memory has similar behavior to the SRAM IC on the DE2 board.  This
// file should be used for simulations only.  In simulation, this memory is
// guaranteed to work at least as well as the actual memory (that is, the
// actual memory may require more careful treatment than this test memory).

// To use, you should create a seperate top-level entity for simulation
// that connects this memory module to your computer.  You can create this
// extra entity either in the same project (temporarily setting it to be the
// top module) or in a new one, and create a new vector waveform file for it.



module test_memory ( input Reset,
							input	  Clk,
							input	[15:0]  data,
							input	[9:0]  address,
							input	  rden,
							input	  wren,
							output logic [15:0]  readout);
												
  //-------------------------------------------------------------------------
//      test_memory.sv                                                   --
//      Stephen Kempf                                                    --
//      Summer 2005                                                      --
//                                                                       --
//      Revised 3-15-2006                                                --
//              3-22-2007                                                --
//              7-26-2013                                                --
//              10-19-2017 by Anand Ramachandran and Po-Han Huang        --
//                        Spring 2018 Distribution  --
//					 6-6-2020   by Xinying Wang Fall 2020
//                                                                       --
//      For use with ECE 385 Experment 6                                 --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------

// This memory has similar behavior to the on-Chip memory on the MAX10 board.  This
// file is for simulations only.  In simulation, this memory is guaranteed
// to work at least as well as the actual memory (that is, the actual
// memory may require more careful treatment than this test memory).
// At synthesis, this will be synthesized into a blank module.


    parameter size          = 256; // expand memory as needed (currently it is 256 words)
    parameter init_external = 0;   // If init external is 0, it means you want to parse the memory_contents.sv file, otherwise you are providing a parsed .dat file

    integer ptr;
    integer x;

    logic [15:0] mem_array [0:size-1];
    logic [15:0] mem_out;


    // A[7:0] is because size = 256, so we only use the lower 8 bits of the address.
    // It should be changed accordingly if size is modified.

    // Requires memory_contents.sv
    memory_parser #(.size(size)) parser();

// synthesis translate_off
// This line turns off Quartus' synthesis tool because test memory is NOT synthesizable.

    initial begin
        parser.memory_contents(mem_array);
      
        // Parse into machine code and write into file
        if (~init_external) begin
            ptr = $fopen("memory_contents.mif", "w");
            
            for (integer x = 0; x < size; x++) begin
                $fwrite(ptr, "@%0h %0h\n", x, mem_array[x]);
            end
            
            $fclose(ptr);
        end

        $readmemh("memory_contents.mif", mem_array, 0, size-1);
    end
    
    // Memory read logic
    always @ (posedge Clk or posedge Reset)
    begin
	     if(Reset) begin
            $readmemh("memory_contents.mif", mem_array, 0, size-1);
				mem_out <= 16'bxxxxxxxxxxxxxxxx;
        end
		  else if(rden && ~wren) begin
				mem_out <= mem_array[address[7:0]]; // Read a specific memory cell. 
        // Flip-flop with negedge Clk is used to simulate the 10ns access time.
        // (Assuming address changes at rising clock edge)
		  end
		  else if(~rden && wren) begin
				mem_array[address[7:0]] <= data;
				mem_out <= 16'bxxxxxxxxxxxxxxxx;
				end
		  else begin
				mem_out <= 16'bxxxxxxxxxxxxxxxx;
				end
    end
    

	 assign readout = mem_out;
    

// synthesis translate_on
endmodule