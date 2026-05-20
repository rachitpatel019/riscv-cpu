# Ensure we are in the correct directory for the library
cd 5_stage_pipeline/sim/

# Create the library if it doesn't exist
if {![file isdirectory work]} {
    vlib work
}

vmap work work

# Compile files
vlog -sv \
    ../packages/decoder_pkg.sv \
    ../packages/alu_pkg.sv \
    ../rtl/4_memory/data_mem.sv \
    ../rtl/4_memory/amo_alu.sv \
    ../rtl/4_memory/memory.sv \
    ../tb/memory_tb.sv

# Run simulation
vsim -c -voptargs=+acc work.memory_tb
run -all
quit -sim
quit -f
