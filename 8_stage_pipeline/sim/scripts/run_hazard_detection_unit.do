transcript ""
onerror {quit -code 1 -f}
onbreak {quit -f}

proc verify_file {path} {
    if {![file exists $path]} {
        puts "Error: Required input file '$path' is missing."
        quit -code 1 -f
    }
}
cd [file normalize [file join [file dirname [info script]] ../scripts]]

# Clean up ModelSim-generated transcript files
if {[file normalize ../scripts/transcript] != [file normalize transcript]} { file delete -force ../scripts/transcript }
file delete -force transcript

# Verify required inputs
verify_file ../scripts/modelsim.ini
verify_file ../../packages/alu_pkg.sv
verify_file ../../packages/decoder_pkg.sv
verify_file ../../rtl/core/hazard_control/hazard_detection_unit.sv
verify_file ../../tb/tb_hazard_detection_unit.sv

if {[file normalize ../scripts/modelsim.ini] != [file normalize modelsim.ini]} { file copy -force ../scripts/modelsim.ini modelsim.ini }
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv ../../packages/alu_pkg.sv ../../packages/decoder_pkg.sv ../../rtl/core/hazard_control/hazard_detection_unit.sv ../../tb/tb_hazard_detection_unit.sv
vsim -batch -L work -voptargs=+acc work.tb_hazard_detection_unit
run -all
if {[file exists work]} { file delete -force work }
if {[file normalize ../scripts/modelsim.ini] != [file normalize modelsim.ini]} { file delete -force modelsim.ini }
if {[file normalize ../scripts/program.hex] != [file normalize program.hex]} { file delete -force program.hex }
quit -f

