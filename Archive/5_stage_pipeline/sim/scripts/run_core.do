onerror {quit -f}
onbreak {quit -f}

# Navigate to the logs directory so artifacts are contained there
cd [file normalize [file join [file dirname [info script]] ../logs]]

# Copy modelsim.ini and test program
file copy -force ../scripts/modelsim.ini modelsim.ini
file copy -force ../test_core.hex program.hex

# Create and map library cleanly
if {[file exists work]} {
    vdel -all
}
vlib work
vmap work work

# Compile all files
vlog -sv \
    ../../packages/decoder_pkg.sv \
    ../../packages/alu_pkg.sv \
    ../../rtl/1_fetch/instr_mem.sv \
    ../../rtl/1_fetch/pc.sv \
    ../../rtl/1_fetch/pc_update.sv \
    ../../rtl/1_fetch/fetch.sv \
    ../../rtl/2_decode/regfile.sv \
    ../../rtl/2_decode/imm_gen.sv \
    ../../rtl/2_decode/control.sv \
    ../../rtl/2_decode/decode.sv \
    ../../rtl/3_execute/alu.sv \
    ../../rtl/3_execute/pc_target_calculator.sv \
    ../../rtl/3_execute/execute.sv \
    ../../rtl/4_memory/data_mem.sv \
    ../../rtl/4_memory/memory.sv \
    ../../rtl/5_writeback/writeback.sv \
    ../../rtl/pipeline_registers/IF_ID.sv \
    ../../rtl/pipeline_registers/ID_EX.sv \
    ../../rtl/pipeline_registers/EX_MEM.sv \
    ../../rtl/pipeline_registers/MEM_WB.sv \
    ../../rtl/hazard_handling/forwarding_unit.sv \
    ../../rtl/hazard_handling/hazard_detection_unit.sv \
    ../../rtl/core.sv \
    ../../tb/core_tb.sv

# Run simulation
vsim -c -voptargs=+acc work.core_tb
run -all
quit -sim
quit -f
