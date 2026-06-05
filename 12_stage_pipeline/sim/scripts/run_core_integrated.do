# run_core_integrated.do
# ModelSim run script for the 12-stage pipeline integrated testbench

# Guardrail: Exit on error to prevent hanging in interactive mode
onerror {quit -f -code 1}

# Create work library
if [file exists work] {
    vdel -lib work -all
}
vlib work

# Compile packages first
vlog -work work ../../packages/alu_pkg.sv
vlog -work work ../../packages/decoder_pkg.sv

# Compile RTL
vlog -work work ../../rtl/core/1_fetch/pc_update.sv
vlog -work work ../../rtl/core/2_imem/instr_mem.sv
vlog -work work ../../rtl/core/3_IMEM_ID_REG/IMEM_ID.sv
vlog -work work ../../rtl/core/4_decode/control.sv
vlog -work work ../../rtl/core/4_decode/decode.sv
vlog -work work ../../rtl/core/4_decode/imm_gen.sv
vlog -work work ../../rtl/core/4_decode/ID_RR.sv
vlog -work work ../../rtl/core/5_reg_read/regfile.sv
vlog -work work ../../rtl/core/5_reg_read/RR.sv
vlog -work work ../../rtl/core/6_RR_EX1_REG/RR_EX1.sv
vlog -work work ../../rtl/core/7_ex1/data_sel.sv
vlog -work work ../../rtl/core/7_ex1/EX1_EX2.sv
vlog -work work ../../rtl/core/8_ex2/alu.sv
vlog -work work ../../rtl/core/8_ex2/branch_eval.sv
vlog -work work ../../rtl/core/8_ex2/EX2_EX3.sv
vlog -work work ../../rtl/core/9_ex3/EX3_MEM.sv
vlog -work work ../../rtl/core/9_ex3/pc_target_calc.sv
vlog -work work ../../rtl/core/10_mem/data_mem.sv
vlog -work work ../../rtl/core/10_mem/MEM.sv
vlog -work work ../../rtl/core/11_MEM_WB_REG/MEM_WB.sv
vlog -work work ../../rtl/core/12_wb/writeback.sv
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
