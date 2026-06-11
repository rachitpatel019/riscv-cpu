onerror {quit -f}
onbreak {quit -f}
cd [file normalize [file join [file dirname [info script]] ../logs]]
file copy -force ../scripts/modelsim.ini modelsim.ini
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/3_decode/imm_gen.sv ../../rtl/core/3_decode/control.sv ../../rtl/core/3_decode/decode.sv ../../tb/tb_decode.sv
vsim -batch -L work -voptargs=+acc work.tb_decode
run -all
quit -f
