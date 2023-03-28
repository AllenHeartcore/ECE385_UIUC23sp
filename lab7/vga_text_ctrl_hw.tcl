package require -exact qsys 16.1
set_module_property DESCRIPTION ""
set_module_property NAME vga_text_ctrl
set_module_property VERSION 1.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP "University Program/Audio & Video/Video"
set_module_property AUTHOR "Ziyuan Chen, Weijie Liang"
set_module_property DISPLAY_NAME "VGA Text Mode Controller"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL VGATextModeController
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file vga_text.sv SYSTEM_VERILOG PATH src/vga_text.sv TOP_LEVEL_FILE
add_fileset_file vga.sv SYSTEM_VERILOG PATH src/vga.sv
add_fileset_file font_rom.sv SYSTEM_VERILOG PATH src/font_rom.sv
add_fileset_file utils.sv SYSTEM_VERILOG PATH src/utils.sv

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL VGATextModeController
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file vga_text.sv SYSTEM_VERILOG PATH src/vga_text.sv
add_fileset_file vga.sv SYSTEM_VERILOG PATH src/vga.sv
add_fileset_file font_rom.sv SYSTEM_VERILOG PATH src/font_rom.sv
add_fileset_file utils.sv SYSTEM_VERILOG PATH src/utils.sv

add_interface clk clock end
set_interface_property clk clockRate 50000000
set_interface_property clk ENABLED true
set_interface_property clk EXPORT_OF ""
set_interface_property clk PORT_NAME_MAP ""
set_interface_property clk CMSIS_SVD_VARIABLES ""
set_interface_property clk SVD_ADDRESS_GROUP ""
add_interface_port clk clk clk Input 1

add_interface reset reset end
set_interface_property reset associatedClock clk
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""
add_interface_port reset reset reset Input 1

add_interface avl_mm_slave avalon end
set_interface_property avl_mm_slave addressUnits WORDS
set_interface_property avl_mm_slave associatedClock clk
set_interface_property avl_mm_slave associatedReset reset
set_interface_property avl_mm_slave bitsPerSymbol 8
set_interface_property avl_mm_slave burstOnBurstBoundariesOnly false
set_interface_property avl_mm_slave burstcountUnits WORDS
set_interface_property avl_mm_slave explicitAddressSpan 0
set_interface_property avl_mm_slave holdTime 0
set_interface_property avl_mm_slave linewrapBursts false
set_interface_property avl_mm_slave maximumPendingReadTransactions 0
set_interface_property avl_mm_slave maximumPendingWriteTransactions 0
set_interface_property avl_mm_slave readLatency 0
set_interface_property avl_mm_slave readWaitTime 1
set_interface_property avl_mm_slave setupTime 0
set_interface_property avl_mm_slave timingUnits Cycles
set_interface_property avl_mm_slave writeWaitTime 0
set_interface_property avl_mm_slave ENABLED true
set_interface_property avl_mm_slave EXPORT_OF ""
set_interface_property avl_mm_slave PORT_NAME_MAP ""
set_interface_property avl_mm_slave CMSIS_SVD_VARIABLES ""
set_interface_property avl_mm_slave SVD_ADDRESS_GROUP ""

add_interface_port avl_mm_slave avl_addr address Input 10
add_interface_port avl_mm_slave avl_byte_en byteenable Input 4
add_interface_port avl_mm_slave avl_cs chipselect Input 1
add_interface_port avl_mm_slave avl_read read Input 1
add_interface_port avl_mm_slave avl_readdata readdata Output 32
add_interface_port avl_mm_slave avl_write write Input 1
add_interface_port avl_mm_slave avl_writedata writedata Input 32
set_interface_assignment avl_mm_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avl_mm_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avl_mm_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avl_mm_slave embeddedsw.configuration.isPrintableDevice 0

add_interface VGA_port conduit end
set_interface_property VGA_port associatedClock clk
set_interface_property VGA_port associatedReset ""
set_interface_property VGA_port ENABLED true
set_interface_property VGA_port EXPORT_OF ""
set_interface_property VGA_port PORT_NAME_MAP ""
set_interface_property VGA_port CMSIS_SVD_VARIABLES ""
set_interface_property VGA_port SVD_ADDRESS_GROUP ""
add_interface_port VGA_port red red Output 4
add_interface_port VGA_port green green Output 4
add_interface_port VGA_port blue blue Output 4
add_interface_port VGA_port hs hs Output 1
add_interface_port VGA_port vs vs Output 1
