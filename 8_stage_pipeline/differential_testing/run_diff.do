# run_diff.do
# ModelSim run script for differential testing testbench
onerror {quit -code 1 -f}
onbreak {quit -f}

# Navigate to the script's directory so relative paths work
cd [file normalize [file dirname [info script]]]

if [file exists work] {
    vdel -lib work -all
}
vlib work

# Compile packages first
vlog -work work ../packages/alu_pkg.sv
vlog -work work ../packages/decoder_pkg.sv

# Compile RTL
vlog -work work ../rtl/core/1_fetch/pc_update.sv
vlog -work work ../rtl/core/2_imem/instr_mem.sv
vlog -work work ../rtl/core/3_decode/IF_ID.sv
vlog -work work ../rtl/core/3_decode/control.sv
vlog -work work ../rtl/core/3_decode/decode.sv
vlog -work work ../rtl/core/3_decode/imm_gen.sv
vlog -work work ../rtl/core/3_decode/ID_RR.sv
vlog -work work ../rtl/core/4_reg_read/regfile.sv
vlog -work work ../rtl/core/4_reg_read/RR_EX1.sv
vlog -work work ../rtl/core/5_ex1/data_sel.sv
vlog -work work ../rtl/core/5_ex1/EX1_EX2.sv
vlog -work work ../rtl/core/6_ex2/alu.sv
vlog -work work ../rtl/core/6_ex2/branch_eval.sv
vlog -work work ../rtl/core/6_ex2/EX2_EX3.sv
vlog -work work ../rtl/core/7_ex3_mem/pc_target_calc.sv
vlog -work work ../rtl/core/7_ex3_mem/MEM_WB.sv
vlog -work work ../rtl/core/7_ex3_mem/data_mem.sv
vlog -work work ../rtl/core/7_ex3_mem/mmio.sv
vlog -work work ../rtl/core/7_ex3_mem/memory.sv
vlog -work work ../rtl/core/8_wb/writeback.sv
vlog -work work ../rtl/core/hazard_control/forwarding_unit.sv
vlog -work work ../rtl/core/hazard_control/hazard_detection_unit.sv
vlog -work work ../rtl/core/core.sv

# Compile Testbench
vlog -work work tb_diff.sv

# Load simulation with arguments from command line
eval vsim -c -onfinish exit -voptargs="+acc" work.tb_diff $argv

# Run simulation
run -all
quit -f
