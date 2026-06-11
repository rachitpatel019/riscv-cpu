# do ../scripts/run_branch_eval.do
vmap work work
vlog -sv ../../rtl/core/6_ex2/branch_eval.sv ../../tb/tb_branch_eval.sv
vsim -batch -L work -voptargs="+acc" work.tb_branch_eval
run -all
exit
