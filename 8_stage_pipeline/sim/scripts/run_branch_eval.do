onerror {quit -f}
onbreak {quit -f}

# Navigate to logs directory
cd [file normalize [file join [file dirname [info script]] ../logs]]

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
