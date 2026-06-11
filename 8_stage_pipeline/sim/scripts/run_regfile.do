onerror {quit -f}
onbreak {quit -f}
cd [file normalize [file join [file dirname [info script]] ../logs]]
file copy -force ../scripts/modelsim.ini modelsim.ini
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/4_reg_read/regfile.sv ../../tb/tb_regfile.sv
vsim -batch -L work -voptargs=+acc work.tb_regfile
run -all
quit -f
