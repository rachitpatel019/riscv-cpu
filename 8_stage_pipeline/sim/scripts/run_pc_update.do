transcript ""
onerror {quit -code 1 -f}
onbreak {quit -f}


proc verify_file {path} {
    if {![file exists $path]} {
        puts "Error: Required input file '$path' is missing."
        quit -code 1 -f
    }
}
# Navigate to the logs directory
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Clean up ModelSim-generated transcript files
file delete -force ../scripts/transcript
file delete -force transcript

# Verify required inputs
verify_file ../scripts/modelsim.ini


# Copy modelsim.ini
file copy -force ../scripts/modelsim.ini modelsim.ini

# Create and map library
if {[file exists work]} {
    vdel -all
}
vlib work
vmap work work

# Compile packages and RTL
vlog -sv \
    ../../packages/alu_pkg.sv \
    ../../packages/decoder_pkg.sv \
    ../../rtl/core/1_fetch/pc_update.sv \
    ../../tb/tb_pc_update.sv

# Run simulation
vsim -batch -L work -voptargs="+acc" work.tb_pc_update
run -all
if {[file exists work]} { file delete -force work }
if {[file exists modelsim.ini]} { file delete -force modelsim.ini }
if {[file exists program.hex]} { file delete -force program.hex }
quit -f
