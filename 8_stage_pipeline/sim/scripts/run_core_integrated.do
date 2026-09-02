# run_core_integrated.do
# ModelSim run script for the 8-stage balanced pipeline integrated testbench

# Guardrail: Exit on error to prevent hanging in interactive mode
transcript off
onerror {quit -code 1 -f}
onbreak {quit -f}


proc verify_file {path} {
    if {![file exists $path]} {
        puts "Error: Required input file '$path' is missing."
        quit -code 1 -f
    }
}
# Navigate to logs directory
cd [file normalize [file join [file dirname [info script]] ../scripts]]

# Clean up ModelSim-generated transcript files
if {[file normalize ../scripts/transcript] != [file normalize transcript]} { file delete -force ../scripts/transcript }
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
verify_file ../../rtl/core/4_reg_read/bht.sv
verify_file ../../rtl/core/4_reg_read/branch_predictor.sv
verify_file ../../rtl/core/4_reg_read/RR_EX1.sv
verify_file ../../rtl/core/5_ex1/data_sel.sv
verify_file ../../rtl/core/5_ex1/EX1_EX2.sv
verify_file ../../rtl/core/6_ex2/alu.sv
verify_file ../../rtl/core/6_ex2/branch_eval.sv
verify_file ../../rtl/core/6_ex2/EX2_EX3.sv
verify_file ../../rtl/core/7_ex3_mem/pc_target_calc.sv
verify_file ../../rtl/core/7_ex3_mem/fwd_sel.sv
verify_file ../../rtl/core/7_ex3_mem/MEM_WB.sv
verify_file ../../rtl/core/7_ex3_mem/data_mem.sv
verify_file ../../rtl/core/7_ex3_mem/mmio.sv
verify_file ../../rtl/core/7_ex3_mem/memory.sv
verify_file ../../rtl/core/8_wb/writeback.sv
verify_file ../../rtl/core/hazard_control/forwarding_unit.sv
verify_file ../../rtl/core/hazard_control/pipeline_control_unit.sv
verify_file ../../rtl/core/core.sv
verify_file ../../tb/tb_core.sv


# Copy configuration and program files
if {[file normalize ../scripts/modelsim.ini] != [file normalize modelsim.ini]} { file copy -force ../scripts/modelsim.ini modelsim.ini }
if {[file normalize ../scripts/program.hex] != [file normalize program.hex]} { file copy -force ../scripts/program.hex program.hex }

# Create work library
if [file exists work] {
    vdel -lib work -all
}
vlib work
vmap work work

# Compile packages first
vlog -sv ../../packages/alu_pkg.sv
vlog -sv ../../packages/decoder_pkg.sv

# Compile RTL (8-Stage Balanced Reorganized)
vlog -sv ../../rtl/core/1_fetch/pc_update.sv
vlog -sv ../../rtl/core/2_imem/instr_mem.sv
vlog -sv ../../rtl/core/3_decode/IF_ID.sv
vlog -sv ../../rtl/core/3_decode/control.sv
vlog -sv ../../rtl/core/3_decode/decode.sv
vlog -sv ../../rtl/core/3_decode/imm_gen.sv
vlog -sv ../../rtl/core/3_decode/ID_RR.sv
vlog -sv ../../rtl/core/4_reg_read/regfile.sv
vlog -sv ../../rtl/core/4_reg_read/bht.sv
vlog -sv ../../rtl/core/4_reg_read/branch_predictor.sv
vlog -sv ../../rtl/core/4_reg_read/RR_EX1.sv
vlog -sv ../../rtl/core/5_ex1/data_sel.sv
vlog -sv ../../rtl/core/5_ex1/EX1_EX2.sv
vlog -sv ../../rtl/core/6_ex2/alu.sv
vlog -sv ../../rtl/core/6_ex2/branch_eval.sv
vlog -sv ../../rtl/core/6_ex2/EX2_EX3.sv
vlog -sv ../../rtl/core/7_ex3_mem/pc_target_calc.sv
vlog -sv ../../rtl/core/7_ex3_mem/fwd_sel.sv
vlog -sv ../../rtl/core/7_ex3_mem/MEM_WB.sv
vlog -sv ../../rtl/core/7_ex3_mem/data_mem.sv
vlog -sv ../../rtl/core/7_ex3_mem/mmio.sv
vlog -sv ../../rtl/core/7_ex3_mem/memory.sv
vlog -sv ../../rtl/core/8_wb/writeback.sv
vlog -sv ../../rtl/core/hazard_control/forwarding_unit.sv
vlog -sv ../../rtl/core/hazard_control/pipeline_control_unit.sv
vlog -sv ../../rtl/core/core.sv

# Compile Testbench
vlog -sv ../../tb/tb_core.sv

# Load simulation
vsim -batch -L work -voptargs=+acc work.tb_core

# Run simulation
run -all

# Cleanup work library
if {[file exists work]} { file delete -force work }
if {[file normalize ../scripts/modelsim.ini] != [file normalize modelsim.ini]} { file delete -force modelsim.ini }
if {[file normalize ../scripts/program.hex] != [file normalize program.hex]} { file delete -force program.hex }
quit -f

