onerror {quit -code 1 -f}
onbreak {quit -f}

proc verify_file {path} {
    if {![file exists $path]} {
        puts "Error: Required input file '$path' is missing."
        quit -code 1 -f
    }
}
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Clean up ModelSim-generated transcript files
file delete -force ../scripts/transcript
file delete -force transcript

# Verify required inputs
verify_file ../scripts/modelsim.ini
verify_file ../../packages/alu_pkg.sv
verify_file ../../packages/decoder_pkg.sv
verify_file ../../rtl/core/7_ex3_mem/data_mem.sv
verify_file ../../tb/tb_data_mem.sv

file copy -force ../scripts/modelsim.ini modelsim.ini
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/7_ex3_mem/data_mem.sv ../../tb/tb_data_mem.sv
vsim -batch -L work -voptargs=+acc work.tb_data_mem
run -all
quit -f
