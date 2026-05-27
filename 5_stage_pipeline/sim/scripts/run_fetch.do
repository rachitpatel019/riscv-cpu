onerror {quit -f}
onbreak {quit -f}

# Navigate to the logs directory so artifacts are contained there
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Copy modelsim.ini
file copy -force ../scripts/modelsim.ini modelsim.ini

# Create a dummy program.hex to avoid warnings if necessary
if {![file exists program.hex]} {
    file copy -force ../test.hex program.hex
}

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
    ../../rtl/1_fetch/instr_mem.sv \
    ../../rtl/1_fetch/pc.sv \
    ../../rtl/1_fetch/pc_update.sv \
    ../../rtl/1_fetch/fetch.sv \
    ../../tb/fetch_tb.sv

# Run simulation
vsim -c -voptargs=+acc work.fetch_tb
run -all
quit -sim
quit -f
