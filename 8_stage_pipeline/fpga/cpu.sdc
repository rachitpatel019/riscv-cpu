create_clock -name MAX10_CLK1_50 -period 8.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty

# Phase 4 Timing Optimization: False Path
# The structural forwarding path from the Stage 8 Data Memory (BRAM) output 
# to the Stage 5 EX1_EX2 registers is a false path. 
# The hazard detection unit stalls dependent instructions until the load data
# is safely written to the register file, meaning this combinational forwarding 
# multiplexer path is never functionally selected for memory loads.
set_false_path -from [get_registers *memory_rtl_0*] -to [get_registers *stage5_ex1_ex2_reg*]
