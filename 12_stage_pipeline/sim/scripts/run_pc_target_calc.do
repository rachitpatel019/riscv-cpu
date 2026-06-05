onerror {quit -f}
onbreak {quit -f}
cd [file normalize [file join [file dirname [info script]] ../logs]]
file copy -force ../scripts/modelsim.ini modelsim.ini
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/9_ex3/pc_target_calc.sv ../../tb/tb_pc_target_calc.sv
vsim -batch -L work -voptargs=+acc work.tb_pc_target_calc
run -all
quit -f
