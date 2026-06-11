onerror {quit -f}
onbreak {quit -f}
cd [file normalize [file join [file dirname [info script]] ../logs]]
file copy -force ../scripts/modelsim.ini modelsim.ini
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/hazard_control/forwarding_unit.sv ../../tb/tb_forwarding_unit.sv
vsim -batch -L work -voptargs=+acc work.tb_forwarding_unit
run -all
quit -f
