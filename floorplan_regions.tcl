# Vajra_6G Functional Region Constraints (Coordinates in Microns)
# 1. PROCESSING BOX (Vajra Core + Kyber Accelerator)
add_region proc_box "400 1500 2200 3500"
inst_assign_region proc_box [get_cells -hierarchical *picorv64*]
inst_assign_region proc_box [get_cells -hierarchical *kyber*]

# 2. COMMUNICATION BOX (UART + SPI + Interfaces)
add_region comm_box "2800 1500 4600 3500"
inst_assign_region comm_box [get_cells -hierarchical *uart*]
inst_assign_region comm_box [get_cells -hierarchical *spi*]
inst_assign_region comm_box [get_cells -hierarchical *gpio*]