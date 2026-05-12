# Timing Constraints for Vajra-6G SoC

# Create clock
create_clock -name clk -period 10.0 [get_ports clk]

# Set input delays
set_input_delay -clock clk 2.0 [get_ports {resetn mem_ready mem_rdata irq}]

# Set output delays
set_output_delay -clock clk 2.0 [get_ports {mem_valid mem_instr mem_addr mem_wdata mem_wstrb eoi trace_valid trace_data}]

# Load/Drive
set_load 10 [all_outputs]
set_driving_cell -lib_cell BUF_X1 [all_inputs]
