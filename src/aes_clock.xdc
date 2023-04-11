set clock_cycle 9
set io_delay 0.2


create_clock -name clk -period $clock_cycle [get_ports clk]

set_input_delay $io_delay -clock clk [all_inputs]
set_output_delay $io_delay -clock clk [all_outputs]
