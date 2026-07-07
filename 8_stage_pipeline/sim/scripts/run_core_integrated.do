# run_core_integrated.do
# ModelSim run script for the 8-stage balanced pipeline integrated testbench

# Guardrail: Exit on error to prevent hanging in interactive mode
onerror {quit -code 1 -f}
onbreak {quit -f}


proc verify_file {path} {
    if {![file exists $path]} {
        puts "Error: Required input file '$path' is missing."
        quit -code 1 -f
    }
}
# Navigate to logs directory
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Clean up ModelSim-generated transcript files
file delete -force ../scripts/transcript
file delete -force transcript

# Verify required inputs
verify_file ../scripts/modelsim.ini
verify_file ../scripts/program.hex
verify_file ../../packages/alu_pkg.sv
verify_file ../../packages/decoder_pkg.sv
verify_file ../../rtl/core/1_fetch/pc_update.sv
verify_file ../../rtl/core/2_imem/instr_mem.sv
verify_file ../../rtl/core/3_decode/IF_ID.sv
verify_file ../../rtl/core/3_decode/control.sv
verify_file ../../rtl/core/3_decode/decode.sv
verify_file ../../rtl/core/3_decode/imm_gen.sv
verify_file ../../rtl/core/3_decode/ID_RR.sv
verify_file ../../rtl/core/4_reg_read/regfile.sv
verify_file ../../rtl/core/4_reg_read/RR_EX1.sv
verify_file ../../rtl/core/5_ex1/data_sel.sv
verify_file ../../rtl/core/5_ex1/EX1_EX2.sv
verify_file ../../rtl/core/6_ex2/alu.sv
verify_file ../../rtl/core/6_ex2/branch_eval.sv
verify_file ../../rtl/core/6_ex2/EX2_EX3.sv
verify_file ../../rtl/core/7_ex3_mem/pc_target_calc.sv
verify_file ../../rtl/core/7_ex3_mem/MEM_WB.sv
verify_file ../../rtl/core/7_ex3_mem/data_mem.sv
verify_file ../../rtl/core/7_ex3_mem/mmio.sv
verify_file ../../rtl/core/7_ex3_mem/memory.sv
verify_file ../../rtl/core/8_wb/writeback.sv
verify_file ../../rtl/core/hazard_control/forwarding_unit.sv
verify_file ../../rtl/core/hazard_control/hazard_detection_unit.sv
verify_file ../../rtl/core/core.sv
verify_file ../../tb/tb_core.sv


# Copy configuration and program files
file copy -force ../scripts/modelsim.ini modelsim.ini
file copy -force ../scripts/program.hex program.hex

# Create work library
if [file exists work] {
    vdel -lib work -all
}
vlib work

# Compile packages first
vlog -work work ../../packages/alu_pkg.sv
vlog -work work ../../packages/decoder_pkg.sv

# Compile RTL (8-Stage Balanced Reorganized)
vlog -work work ../../rtl/core/1_fetch/pc_update.sv
vlog -work work ../../rtl/core/2_imem/instr_mem.sv
vlog -work work ../../rtl/core/3_decode/IF_ID.sv
vlog -work work ../../rtl/core/3_decode/control.sv
vlog -work work ../../rtl/core/3_decode/decode.sv
vlog -work work ../../rtl/core/3_decode/imm_gen.sv
vlog -work work ../../rtl/core/3_decode/ID_RR.sv
vlog -work work ../../rtl/core/4_reg_read/regfile.sv
vlog -work work ../../rtl/core/4_reg_read/RR_EX1.sv
vlog -work work ../../rtl/core/5_ex1/data_sel.sv
vlog -work work ../../rtl/core/5_ex1/EX1_EX2.sv
vlog -work work ../../rtl/core/6_ex2/alu.sv
vlog -work work ../../rtl/core/6_ex2/branch_eval.sv
vlog -work work ../../rtl/core/6_ex2/EX2_EX3.sv
vlog -work work ../../rtl/core/7_ex3_mem/pc_target_calc.sv
vlog -work work ../../rtl/core/7_ex3_mem/MEM_WB.sv
vlog -work work ../../rtl/core/7_ex3_mem/data_mem.sv
vlog -work work ../../rtl/core/7_ex3_mem/mmio.sv
vlog -work work ../../rtl/core/7_ex3_mem/memory.sv
vlog -work work ../../rtl/core/8_wb/writeback.sv
vlog -work work ../../rtl/core/hazard_control/forwarding_unit.sv
vlog -work work ../../rtl/core/hazard_control/hazard_detection_unit.sv
vlog -work work ../../rtl/core/core.sv

# Compile Testbench
vlog -work work ../../tb/tb_core.sv

# Load simulation
vsim -voptargs="+acc" -onfinish exit work.tb_core

# Run simulation
run -all

# Exit if finished successfully
quit -f
