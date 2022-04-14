create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_pins STARTUPE3_inst/CFGMCLK]

set_property IOSTANDARD LVCMOS18 [get_ports {BUTTON_IN[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {BUTTON_IN[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {BUTTON_IN[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {BUTTON_IN[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {BUTTON_IN[0]}]

set_property PACKAGE_PIN AE10 [get_ports {BUTTON_IN[0]}]
set_property PACKAGE_PIN AD10 [get_ports {BUTTON_IN[1]}]
set_property PACKAGE_PIN AF8 [get_ports {BUTTON_IN[2]}]
set_property PACKAGE_PIN AF9 [get_ports {BUTTON_IN[3]}]
set_property PACKAGE_PIN AE8 [get_ports {BUTTON_IN[4]}]

set_property PACKAGE_PIN R23 [get_ports LED]		#LED Location changed to LED6 for distinguish with "Update Image"
set_property IOSTANDARD LVCMOS18 [get_ports LED]

set_property PACKAGE_PIN K26 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS18 [get_ports UART_TX]

set_property PACKAGE_PIN G25 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS18 [get_ports UART_RX]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_BUFG]

##########################   Bitstream options #####################################
set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 0x02C0000 [current_design]
set_property BITSTREAM.CONFIG.NEXT_CONFIG_REBOOT ENABLE [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.TIMER_CFG 1000000 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
