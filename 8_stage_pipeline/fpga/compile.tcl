# Quartus Compilation Script for 8-stage balanced RISC-V CPU

# Load Quartus Prime Tcl packages
package require ::quartus::project
package require ::quartus::flow

# Change directory to the script's directory so it can be run from the repository root
set script_dir [file normalize [file dirname [info script]]]
cd $script_dir

# Project names
set project_name "cpu"
set top_level_entity "top"
set device "10M50DAF484C7G"

# List of required input files to verify existence
set required_files {
    "../packages/alu_pkg.sv"
    "../packages/decoder_pkg.sv"
    "../rtl/core/core.sv"
    "../rtl/core/1_fetch/pc_update.sv"
    "../rtl/core/2_imem/instr_mem.sv"
    "../rtl/core/3_decode/IF_ID.sv"
    "../rtl/core/3_decode/control.sv"
    "../rtl/core/3_decode/decode.sv"
    "../rtl/core/3_decode/ID_RR.sv"
    "../rtl/core/3_decode/imm_gen.sv"
    "../rtl/core/4_reg_read/regfile.sv"
    "../rtl/core/4_reg_read/bht.sv"
    "../rtl/core/4_reg_read/RR_EX1.sv"
    "../rtl/core/5_ex1/data_sel.sv"
    "../rtl/core/5_ex1/EX1_EX2.sv"
    "../rtl/core/6_ex2/alu.sv"
    "../rtl/core/6_ex2/branch_eval.sv"
    "../rtl/core/6_ex2/EX2_EX3.sv"
    "../rtl/core/7_ex3_mem/pc_target_calc.sv"
    "../rtl/core/7_ex3_mem/MEM_WB.sv"
    "../rtl/core/7_ex3_mem/data_mem.sv"
    "../rtl/core/8_wb/writeback.sv"
    "../rtl/core/hazard_control/forwarding_unit.sv"
    "../rtl/core/hazard_control/hazard_detection_unit.sv"
    "PLL.v"
    "top.sv"
    "program.hex"
    "cpu.sdc"
}

# Verify all input files exist
foreach file_path $required_files {
    if {![file exists $file_path]} {
        puts "Error: Required input file '$file_path' is missing."
        exit 1
    }
}

# Verify project files exist
if {![file exists "${project_name}.qpf"] || ![file exists "${project_name}.qsf"]} {
    puts "Error: Quartus project file(s) ${project_name}.qpf or ${project_name}.qsf not found."
    exit 1
}

# Open project
if {[catch {project_open $project_name} err]} {
    puts "Error: Could not open project $project_name: $err"
    exit 1
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
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/core/4_reg_read/bht.sv
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
set_global_assignment -name VERILOG_FILE PLL.v
set_global_assignment -name SYSTEMVERILOG_FILE top.sv
set_global_assignment -name HEX_FILE program.hex
set_global_assignment -name SDC_FILE cpu.sdc

# Constraints & Optimization
set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE PERFORMANCE"

# Run Compilation
puts "Running Quartus compilation flow..."
if {[catch {execute_flow -compile} err]} {
    puts "Error: Compilation flow failed: $err"
    project_close
    exit 1
}

# Close project
project_close
puts "Quartus compilation completed successfully."
