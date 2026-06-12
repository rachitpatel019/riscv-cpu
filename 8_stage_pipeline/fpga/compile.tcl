# Quartus Compilation Script for 8-stage balanced RISC-V CPU

# Load Quartus Prime Tcl packages
package require ::quartus::project
package require ::quartus::flow

# Project names
set project_name "cpu"
set top_level_entity "top"
set device "10M50DAF484C7G"

# Create project if it doesn't exist
if {[project_exists $project_name]} {
    project_open $project_name
} else {
    project_new $project_name
}

# Set project settings
set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE $device
set_global_assignment -name TOP_LEVEL_ENTITY $top_level_entity
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files

# Packages
set_global_assignment -name SYSTEMVERILOG_FILE ../packages/alu_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../packages/decoder_pkg.sv

# RTL Files (Reorganized 8-Stage)
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/core.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/1_fetch/pc_update.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/2_imem/instr_mem.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/3_decode/IF_ID.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/3_decode/control.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/3_decode/decode.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/3_decode/ID_RR.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/3_decode/imm_gen.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/4_reg_read/regfile.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/4_reg_read/RR_EX1.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/5_ex1/data_sel.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/5_ex1/EX1_EX2.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/6_ex2/alu.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/6_ex2/branch_eval.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/6_ex2/EX2_EX3.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/7_ex3_mem/pc_target_calc.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/7_ex3_mem/MEM_WB.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/7_ex3_mem/data_mem.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/8_wb/writeback.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/hazard_control/forwarding_unit.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/hazard_control/hazard_detection_unit.sv

# Other
set_global_assignment -name SYSTEMVERILOG_FILE top.sv
set_global_assignment -name HEX_FILE program.hex
set_global_assignment -name SDC_FILE cpu.sdc

# Constraints & Optimization
set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE PERFORMANCE"

# Run Compilation
execute_flow -compile

# Close project
project_close
