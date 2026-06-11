onerror {quit -f}
onbreak {quit -f}

# Navigate to the logs directory so artifacts are contained there
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Copy modelsim.ini
file copy -force ../scripts/modelsim.ini modelsim.ini

# Create and map library cleanly
if {[file exists work]} {
    vdel -all
}
vlib work
vmap work work

# Compile files
vlog -sv \
    ../../packages/decoder_pkg.sv \
    ../../packages/alu_pkg.sv \
    ../../rtl/3_execute/alu.sv \
    ../../rtl/3_execute/pc_target_calculator.sv \
    ../../rtl/3_execute/execute.sv \
    ../../tb/execute_tb.sv

# Run simulation
vsim -c -voptargs=+acc work.execute_tb
run -all
quit -sim
quit -f
