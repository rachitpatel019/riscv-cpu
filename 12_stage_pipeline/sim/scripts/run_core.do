onerror {quit -f}
onbreak {quit -f}
# Create logs directory if it doesn't exist
if {![file exists ../logs]} {
    file mkdir ../logs
}
cd ../logs
file copy -force ../scripts/modelsim.ini modelsim.ini
# Always copy program.hex to ensure it's up to date
file copy -force ../program.hex program.hex
if {[file exists work]} { vdel -all }
vlib work
vmap work work
vlog -sv \
    ../../packages/alu_pkg.sv \
    ../../packages/decoder_pkg.sv \
    ../../rtl/core/1_fetch/pc_update.sv \
    ../../rtl/core/2_imem/instr_mem.sv \
    ../../rtl/core/3_IMEM_ID_REG/IMEM_ID.sv \
    ../../rtl/core/4_decode/control.sv \
    ../../rtl/core/4_decode/imm_gen.sv \
    ../../rtl/core/4_decode/decode.sv \
    ../../rtl/core/4_decode/ID_RR.sv \
    ../../rtl/core/5_reg_read/regfile.sv \
    ../../rtl/core/5_reg_read/RR.sv \
    ../../rtl/core/6_RR_EX1_REG/RR_EX1.sv \
    ../../rtl/core/7_ex1/data_sel.sv \
    ../../rtl/core/7_ex1/EX1_EX2.sv \
    ../../rtl/core/8_ex2/alu.sv \
    ../../rtl/core/8_ex2/EX2_EX3.sv \
    ../../rtl/core/9_ex3/pc_target_calc.sv \
    ../../rtl/core/9_ex3/EX3_MEM.sv \
    ../../rtl/core/10_mem/data_mem.sv \
    ../../rtl/core/10_mem/MEM.sv \
    ../../rtl/core/11_MEM_WB_REG/MEM_WB.sv \
    ../../rtl/core/12_wb/writeback.sv \
    ../../rtl/core/hazard_control/forwarding_unit.sv \
    ../../rtl/core/hazard_control/hazard_detection_unit.sv \
    ../../rtl/core/core.sv \
    ../../tb/tb_core.sv
vsim -batch -L work -voptargs=+acc work.tb_core
run -all
quit -f
