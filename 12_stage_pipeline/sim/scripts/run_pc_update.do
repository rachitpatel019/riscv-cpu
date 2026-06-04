onerror {quit -f}
onbreak {quit -f}

# Navigate to the logs directory
cd [file normalize [file join [file dirname [info script]] ../logs]]

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
    ../../tb/pc_update_tb.sv

# Run simulation
vsim -batch -L work -voptargs="+acc" work.pc_update_tb
run -all
quit -f
