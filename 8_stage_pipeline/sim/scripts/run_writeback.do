onerror {quit -code 1 -f}
onbreak {quit -f}

proc verify_file {path} {
    if {![file exists $path]} {
        puts "Error: Required input file '$path' is missing."
        quit -code 1 -f
    }
}
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Verify required inputs
verify_file ../scripts/modelsim.ini
verify_file ../../packages/alu_pkg.sv
verify_file ../../packages/decoder_pkg.sv
verify_file ../../rtl/core/8_wb/writeback.sv
verify_file ../../tb/tb_writeback.sv

file copy -force ../scripts/modelsim.ini modelsim.ini
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/8_wb/writeback.sv ../../tb/tb_writeback.sv
vsim -batch -L work -voptargs=+acc work.tb_writeback
run -all
quit -f
