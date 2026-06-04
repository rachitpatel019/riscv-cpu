onerror {quit -f}
onbreak {quit -f}
cd [file normalize [file join [file dirname [info script]] ../logs]]
file copy -force ../scripts/modelsim.ini modelsim.ini
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/10_mem/data_mem.sv ../../tb/data_mem_tb.sv
vsim -batch -L work -voptargs=+acc work.data_mem_tb
run -all
quit -f
