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
    ../rtl/3_execute/alu.sv \
    ../rtl/3_execute/pc_target_calculator.sv \
    ../rtl/3_execute/execute.sv \
    ../tb/execute_tb.sv

# Run simulation
vsim -c -voptargs=+acc work.execute_tb
run -all
quit -sim
quit -f
