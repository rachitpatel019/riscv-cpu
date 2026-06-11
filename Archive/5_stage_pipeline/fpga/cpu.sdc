create_clock -name MAX10_CLK1_50 -period 10.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty
#set_false_path -from [get_ports {KEY[*]}] -to [all_registers]