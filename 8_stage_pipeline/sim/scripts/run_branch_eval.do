onerror {quit -code 1 -f}
onbreak {quit -f}


proc verify_file {path} {
    if {![file exists $path]} {
        puts "Error: Required input file '$path' is missing."
        quit -code 1 -f
    }
}
# Navigate to logs directory
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Verify required inputs
verify_file ../scripts/modelsim.ini
verify_file ../../rtl/core/6_ex2/branch_eval.sv
verify_file ../../tb/tb_branch_eval.sv


# Copy configuration
file copy -force ../scripts/modelsim.ini modelsim.ini

# Create work library
if [file exists work] {
    vdel -lib work -all
}
vlib work
vmap work work

vlog -sv ../../rtl/core/6_ex2/branch_eval.sv ../../tb/tb_branch_eval.sv
vsim -batch -L work -voptargs="+acc" work.tb_branch_eval
run -all
quit -f
