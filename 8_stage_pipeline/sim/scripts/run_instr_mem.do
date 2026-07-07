transcript ""
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
verify_file ../scripts/program.hex
verify_file ../../packages/alu_pkg.sv
verify_file ../../packages/decoder_pkg.sv
verify_file ../../rtl/core/2_imem/instr_mem.sv
verify_file ../../tb/tb_instr_mem.sv

file copy -force ../scripts/modelsim.ini modelsim.ini
file copy -force ../scripts/program.hex program.hex
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/2_imem/instr_mem.sv ../../tb/tb_instr_mem.sv
vsim -batch -L work -voptargs=+acc work.tb_instr_mem
run -all
if {[file exists work]} { file delete -force work }
if {[file exists modelsim.ini]} { file delete -force modelsim.ini }
if {[file exists program.hex]} { file delete -force program.hex }
quit -f
