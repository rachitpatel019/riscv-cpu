`timescale 1ns / 1ps

/**
 * 8-Stage RISC-V (RV32I) CPU Core (Optimized & Balanced for Fmax)
 * 
 * Pipeline Stages:
 * 1.  Fetch (pc_update) - Muxes next PC
 * 2.  I-Mem Access (instr_mem) - BRAM access
 * 3.  Decode (decode + IF_ID reg) - BREAKS BRAM->PC Path
 * 4.  Reg Read (regfile async)
 * 5.  EX1: Op Selection (data_sel) - Bottleneck
 * 6.  EX2: ALU (alu + branch_eval)
 * 7.  EX3/MEM (target_calc + data_mem addr)
 * 8.  WB (data_mem read + wb mux)
 */

module core (
    input  logic        clk,
    input  logic        reset,

    // MMIO Interface
    input  logic [1:0]  mmio_keys,
    input  logic [9:0]  mmio_switches,
    output logic [9:0]  mmio_leds,
    output logic [23:0] mmio_hex,

    // Outputs for debugging/FPGA
    output logic [31:0] out_pc,
    output logic [31:0] out_writeback_data,
    output logic        out_reg_write,
    output logic [31:0] out_alu_result
);

    // =========================================================================
    // Signal Definitions
    // =========================================================================

    // Global Control
    logic stall_frontend;
    logic flush;

    // Stage 1: Fetch
    logic [31:0] F_pc;

    // Stage 2: I-Mem
    logic [31:0] IM_pc_out;
    logic [31:0] IM_instruction;

    // Stage 3: IF/ID & Decode
    logic [31:0] D_pc;
    logic [31:0] D_instruction;

    logic [31:0] D_immediate;
    logic [4:0]  D_rs1, D_rs2, D_rd;
    logic [31:0] D_pc_out;
    logic        D_uses_rs1, D_uses_rs2;
    logic [3:0]  D_alu_op;
    logic        D_alu_src_a, D_alu_src_b;
    logic        D_reg_write, D_mem_read, D_mem_write;
    logic [1:0]  D_mem_size;
    logic        D_mem_unsigned;
    logic [1:0]  D_wb_sel;
    logic        D_branch, D_jump;
    logic [2:0]  D_branch_type;

    // Stage 4: ID/RR (Reg Read)
    logic [31:0] IDRR_immediate;
    logic [4:0]  IDRR_rs1, IDRR_rs2, IDRR_rd;
    logic [31:0] IDRR_pc;
    logic        IDRR_uses_rs1, IDRR_uses_rs2;
    logic [3:0]  IDRR_alu_op;
    logic        IDRR_alu_src_a, IDRR_alu_src_b;
    logic        IDRR_reg_write, IDRR_mem_read, IDRR_mem_write;
    logic [1:0]  IDRR_mem_size;
    logic        IDRR_mem_unsigned;
    logic [1:0]  IDRR_wb_sel;
    logic        IDRR_branch, IDRR_jump;
    logic [2:0]  IDRR_branch_type;

    logic [31:0] RF_read_data1, RF_read_data2;

    // Stage 5: RR/EX1 (Op Sel)
    logic [31:0] E1_immediate;
    logic [4:0]  E1_rs1, E1_rs2, E1_rd;
    logic [31:0] E1_rs1_data, E1_rs2_data;
    logic [31:0] E1_pc;
    logic        E1_uses_rs1, E1_uses_rs2;
    logic [3:0]  E1_alu_op;
    logic        E1_alu_src_a, E1_alu_src_b;
    logic        E1_reg_write, E1_mem_read, E1_mem_write;
    logic [1:0]  E1_mem_size;
    logic        E1_mem_unsigned;
    logic [1:0]  E1_wb_sel;
    logic        E1_branch, E1_jump;
    logic [2:0]  E1_branch_type;

    logic [31:0] E1_operand_a, E1_operand_b, E1_rs2_data_fwd;
    logic        E1_forward_a, E1_forward_b;
    logic [31:0] E1_forward_a_data, E1_forward_b_data;

    // Stage 6: EX1/EX2 (ALU)
    logic [31:0] E2_pc;
    logic [3:0]  E2_alu_op;
    logic [31:0] E2_imm;
    logic        E2_branch, E2_jump;
    logic [2:0]  E2_branch_type;
    logic        E2_reg_write, E2_mem_read, E2_mem_write;
    logic [1:0]  E2_mem_size;
    logic        E2_mem_unsigned;
    logic [1:0]  E2_wb_sel;
    logic [4:0]  E2_rd;
    logic [31:0] E2_operand_a, E2_operand_b, E2_rs2_data;
    logic [31:0] E2_alu_result;
    logic        E2_condition_met;
    logic [31:0] E2_branch_target;

    // Stage 7: EX2/EX3 (Target + Mem Addr)
    logic [31:0] E3_pc;
    logic [31:0] E3_imm;
    logic        E3_branch, E3_jump;
    logic [2:0]  E3_branch_type;
    logic        E3_reg_write, E3_mem_read, E3_mem_write;
    logic [1:0]  E3_mem_size;
    logic        E3_mem_unsigned;
    logic [1:0]  E3_wb_sel;
    logic [4:0]  E3_rd;
    logic [31:0] E3_operand_a, E3_operand_b, E3_rs2_data;
    logic [31:0] E3_alu_result;
    logic        E3_condition_met;
    logic [31:0] E3_branch_target;

    logic        E3_pc_sel;
    logic [31:0] E3_pc_target;

    // Stage 8: MEM/WB (Data Mem + WB logic)
    logic        W_reg_write;
    logic [4:0]  W_rd;
    logic [31:0] W_alu_result;
    logic [31:0] W_pc;
    logic [31:0] W_mem_read_data;
    logic [1:0]  W_wb_sel;

    logic [31:0] W_write_data;

    // =========================================================================
    // Control Logic
    // =========================================================================

    assign flush = E3_pc_sel;

    // =========================================================================
    // Stage 1: Fetch (Muxes Next PC)
    // =========================================================================
    pc_update stage1_fetch (
        .clk(clk),
        .reset(reset),
        .stall(stall_frontend),
        .pc_sel(E3_pc_sel),
        .pc_target(E3_pc_target),
        .pc(F_pc)
    );

    // =========================================================================
    // Stage 2: I-Mem (BRAM Read)
    // =========================================================================
    instr_mem stage2_imem (
        .clk(clk),
        .reset(reset),
        .stall(stall_frontend),
        .flush(flush),
        .pc(F_pc),
        .pc_out(IM_pc_out),
        .instruction(IM_instruction)
    );

    // =========================================================================
    // Stage 3: IF/ID & Decode (Breaks BRAM->PC Path)
    // =========================================================================
    IF_ID stage3_if_id_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall_frontend),
        .flush(flush),
        .pc_in(IM_pc_out),
        .instruction_in(IM_instruction),
        .pc_out(D_pc),
        .instruction_out(D_instruction)
    );

    decode stage3_decode (
        .pc(D_pc),
        .instruction(D_instruction),
        .immediate(D_immediate),
        .rs1(D_rs1),
        .rs2(D_rs2),
        .rd(D_rd),
        .pc_out(D_pc_out),
        .uses_rs1(D_uses_rs1),
        .uses_rs2(D_uses_rs2),
        .alu_op(D_alu_op),
        .alu_src_a(D_alu_src_a),
        .alu_src_b(D_alu_src_b),
        .reg_write(D_reg_write),
        .mem_read(D_mem_read),
        .mem_write(D_mem_write),
        .mem_size(D_mem_size),
        .mem_unsigned(D_mem_unsigned),
        .wb_sel(D_wb_sel),
        .branch(D_branch),
        .jump(D_jump),
        .branch_type(D_branch_type)
    );

    // ID/RR Register
    ID_RR stage3_id_rr_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall_frontend),
        .flush(flush || stall_frontend), 
        .immediate_in(D_immediate),
        .rs1_in(D_rs1),
        .rs2_in(D_rs2),
        .rd_in(D_rd),
        .pc_in(D_pc_out),
        .uses_rs1_in(D_uses_rs1),
        .uses_rs2_in(D_uses_rs2),
        .alu_op_in(D_alu_op),
        .alu_src_a_in(D_alu_src_a),
        .alu_src_b_in(D_alu_src_b),
        .reg_write_in(D_reg_write),
        .mem_read_in(D_mem_read),
        .mem_write_in(D_mem_write),
        .mem_size_in(D_mem_size),
        .mem_unsigned_in(D_mem_unsigned),
        .wb_sel_in(D_wb_sel),
        .branch_in(D_branch),
        .jump_in(D_jump),
        .branch_type_in(D_branch_type),
        .immediate_out(IDRR_immediate),
        .rs1_out(IDRR_rs1),
        .rs2_out(IDRR_rs2),
        .rd_out(IDRR_rd),
        .pc_out(IDRR_pc),
        .uses_rs1_out(IDRR_uses_rs1),
        .uses_rs2_out(IDRR_uses_rs2),
        .alu_op_out(IDRR_alu_op),
        .alu_src_a_out(IDRR_alu_src_a),
        .alu_src_b_out(IDRR_alu_src_b),
        .reg_write_out(IDRR_reg_write),
        .mem_read_out(IDRR_mem_read),
        .mem_write_out(IDRR_mem_write),
        .mem_size_out(IDRR_mem_size),
        .mem_unsigned_out(IDRR_mem_unsigned),
        .wb_sel_out(IDRR_wb_sel),
        .branch_out(IDRR_branch),
        .jump_out(IDRR_jump),
        .branch_type_out(IDRR_branch_type)
    );

    // =========================================================================
    // Stage 4: Reg Read (Captured by RR_EX1)
    // =========================================================================
    regfile stage4_regfile (
        .clk(clk),
        .read_address1(IDRR_rs1),
        .read_address2(IDRR_rs2),
        .read_data1(RF_read_data1),
        .read_data2(RF_read_data2),
        .write_address(W_rd),
        .write_data(W_write_data),
        .write_enable(W_reg_write)
    );

    RR_EX1 stage4_rr_ex1_reg (
        .clk(clk),
        .reset(reset),
        .flush(flush),
        .immediate_in(IDRR_immediate),
        .rs1_in(IDRR_rs1),
        .rs2_in(IDRR_rs2),
        .rs1_data_in(RF_read_data1),
        .rs2_data_in(RF_read_data2),
        .rd_in(IDRR_rd),
        .pc_in(IDRR_pc),
        .uses_rs1_in(IDRR_uses_rs1),
        .uses_rs2_in(IDRR_uses_rs2),
        .alu_op_in(IDRR_alu_op),
        .alu_src_a_in(IDRR_alu_src_a),
        .alu_src_b_in(IDRR_alu_src_b),
        .reg_write_in(IDRR_reg_write),
        .mem_read_in(IDRR_mem_read),
        .mem_write_in(IDRR_mem_write),
        .mem_size_in(IDRR_mem_size),
        .mem_unsigned_in(IDRR_mem_unsigned),
        .wb_sel_in(IDRR_wb_sel),
        .branch_in(IDRR_branch),
        .jump_in(IDRR_jump),
        .branch_type_in(IDRR_branch_type),
        .immediate_out(E1_immediate),
        .rs1_out(E1_rs1),
        .rs2_out(E1_rs2),
        .rs1_data_out(E1_rs1_data),
        .rs2_data_out(E1_rs2_data),
        .rd_out(E1_rd),
        .pc_out(E1_pc),
        .uses_rs1_out(E1_uses_rs1),
        .uses_rs2_out(E1_uses_rs2),
        .alu_op_out(E1_alu_op),
        .alu_src_a_out(E1_alu_src_a),
        .alu_src_b_out(E1_alu_src_b),
        .reg_write_out(E1_reg_write),
        .mem_read_out(E1_mem_read),
        .mem_write_out(E1_mem_write),
        .mem_size_out(E1_mem_size),
        .mem_unsigned_out(E1_mem_unsigned),
        .wb_sel_out(E1_wb_sel),
        .branch_out(E1_branch),
        .jump_out(E1_jump),
        .branch_type_out(E1_branch_type)
    );

    // =========================================================================
    // Stage 5: EX1 (Operand Selection) - Bottleneck
    // =========================================================================
    data_sel stage5_data_sel (
        .pc(E1_pc),
        .rs1_data(E1_rs1_data),
        .rs2_data(E1_rs2_data),
        .imm(E1_immediate),
        .alu_src_a(E1_alu_src_a),
        .alu_src_b(E1_alu_src_b),
        .forward_a(E1_forward_a),
        .forward_b(E1_forward_b),
        .forward_a_data(E1_forward_a_data),
        .forward_b_data(E1_forward_b_data),
        .operand_a(E1_operand_a),
        .operand_b(E1_operand_b),
        .rs2_data_out(E1_rs2_data_fwd)
    );

    EX1_EX2 stage5_ex1_ex2_reg (
        .clk(clk),
        .reset(reset),
        .flush(flush),
        .pc_in(E1_pc),
        .alu_op_in(E1_alu_op),
        .imm_in(E1_immediate),
        .branch_in(E1_branch),
        .jump_in(E1_jump),
        .branch_type_in(E1_branch_type),
        .reg_write_in(E1_reg_write),
        .rd_in(E1_rd),
        .operand_a_in(E1_operand_a),
        .operand_b_in(E1_operand_b),
        .rs2_data_in(E1_rs2_data_fwd),
        .mem_read_in(E1_mem_read),
        .mem_write_in(E1_mem_write),
        .mem_size_in(E1_mem_size),
        .mem_unsigned_in(E1_mem_unsigned),
        .wb_sel_in(E1_wb_sel),
        .pc_out(E2_pc),
        .alu_op_out(E2_alu_op),
        .imm_out(E2_imm),
        .branch_out(E2_branch),
        .jump_out(E2_jump),
        .branch_type_out(E2_branch_type),
        .reg_write_out(E2_reg_write),
        .rd_out(E2_rd),
        .operand_a_out(E2_operand_a),
        .operand_b_out(E2_operand_b),
        .rs2_data_out(E2_rs2_data),
        .mem_read_out(E2_mem_read),
        .mem_write_out(E2_mem_write),
        .mem_size_out(E2_mem_size),
        .mem_unsigned_out(E2_mem_unsigned),
        .wb_sel_out(E2_wb_sel)
    );

    // =========================================================================
    // Stage 6: EX2 (ALU)
    // =========================================================================
    alu stage6_alu (
        .A(E2_operand_a),
        .B(E2_operand_b),
        .control(E2_alu_op),
        .result(E2_alu_result)
    );

    branch_eval stage6_branch_eval (
        .pc(E2_pc),
        .imm(E2_imm),
        .operand_a(E2_operand_a),
        .operand_b(E2_operand_b),
        .branch_type(E2_branch_type),
        .condition_met(E2_condition_met),
        .branch_target(E2_branch_target)
    );

    EX2_EX3 stage6_ex2_ex3_reg (
        .clk(clk),
        .reset(reset),
        .flush(flush),
        .pc_in(E2_pc),
        .imm_in(E2_imm),
        .branch_in(E2_branch),
        .jump_in(E2_jump),
        .branch_type_in(E2_branch_type),
        .reg_write_in(E2_reg_write),
        .rd_in(E2_rd),
        .operand_a_in(E2_operand_a),
        .operand_b_in(E2_operand_b),
        .rs2_data_in(E2_rs2_data),
        .alu_result_in(E2_alu_result),
        .condition_met_in(E2_condition_met),
        .branch_target_in(E2_branch_target),
        .mem_read_in(E2_mem_read),
        .mem_write_in(E2_mem_write),
        .mem_size_in(E2_mem_size),
        .mem_unsigned_in(E2_mem_unsigned),
        .wb_sel_in(E2_wb_sel),
        .pc_out(E3_pc),
        .imm_out(E3_imm),
        .branch_out(E3_branch),
        .jump_out(E3_jump),
        .branch_type_out(E3_branch_type),
        .reg_write_out(E3_reg_write),
        .rd_out(E3_rd),
        .operand_a_out(E3_operand_a),
        .operand_b_out(E3_operand_b),
        .rs2_data_out(E3_rs2_data),
        .alu_result_out(E3_alu_result),
        .condition_met_out(E3_condition_met),
        .branch_target_out(E3_branch_target),
        .mem_read_out(E3_mem_read),
        .mem_write_out(E3_mem_write),
        .mem_size_out(E3_mem_size),
        .mem_unsigned_out(E3_mem_unsigned),
        .wb_sel_out(E3_wb_sel)
    );

    // =========================================================================
    // Stage 7: EX3/MEM (Branch Target + Data Mem Addr)
    // =========================================================================
    pc_target_calc stage7_calc (
        .pc(E3_pc),
        .operand_a(E3_operand_a),
        .operand_b(E3_operand_b),
        .branch(E3_branch),
        .jump(E3_jump),
        .branch_type(E3_branch_type),
        .imm(E3_imm),
        .alu_result(E3_alu_result),
        .condition_met_in(E3_condition_met),
        .branch_target_in(E3_branch_target),
        .pc_sel(E3_pc_sel),
        .pc_target(E3_pc_target)
    );

    // Intermediate WB mux to save time in S8
    logic [31:0] W_wb_intermediate;
    assign W_wb_intermediate = (E3_wb_sel == 2'b10) ? E3_pc + 32'd4 : E3_alu_result;

    // MEM/WB Register
    MEM_WB stage7_mem_wb_reg (
        .clk(clk),
        .reset(reset),
        .flush(1'b0), 
        .rd_in(E3_rd),
        .reg_write_in(E3_reg_write),
        .alu_result_in(W_wb_intermediate), // ALU or PC+4
        .mem_read_data_in(32'b0),          // Handled by data_mem internally
        .wb_sel_in(E3_wb_sel),
        .pc_in(E3_pc),
        .rd_out(W_rd),
        .reg_write_out(W_reg_write),
        .alu_result_out(W_alu_result),
        .mem_read_data_out(),              // Not used
        .wb_sel_out(W_wb_sel),
        .pc_out(W_pc)
    );

    // =========================================================================
    // Stage 8: MEM Read & WB Logic
    // =========================================================================
    memory stage8_memory_system (
        .clk(clk),
        .reset(reset),
        .mem_read(E3_mem_read),
        .mem_write(E3_mem_write),
        .address(E3_alu_result),
        .write_data(E3_rs2_data),
        .mem_size(E3_mem_size),
        .mem_unsigned(E3_mem_unsigned),
        .read_data(W_mem_read_data),
        
        // MMIO connections
        .mmio_keys(mmio_keys),
        .mmio_switches(mmio_switches),
        .mmio_leds(mmio_leds),
        .mmio_hex(mmio_hex)
    );

    writeback stage8_wb (
        .pc(W_pc),
        .alu_result(W_alu_result),
        .mem_data(W_mem_read_data),
        .wb_sel(W_wb_sel),
        .write_data(W_write_data)
    );

    // =========================================================================
    // Forwarding & Hazard Units
    // =========================================================================

    // Forwarding data selection logic
    logic [31:0] E2_fwd_val, E3_fwd_val, M_fwd_val;
    assign E2_fwd_val = (E2_wb_sel == 2'b10) ? E2_pc + 32'd4 : E2_alu_result;
    assign E3_fwd_val = (E3_wb_sel == 2'b10) ? E3_pc + 32'd4 : E3_alu_result;
    assign M_fwd_val  = W_write_data; // WB result ready at start of S8

    forwarding_unit fwd_unit (
        .E1_rs1(E1_rs1),
        .E1_rs2(E1_rs2),
        .E1_uses_rs1(E1_uses_rs1),
        .E1_uses_rs2(E1_uses_rs2),
        .E2_reg_write(E2_reg_write),
        .E2_mem_read(E2_mem_read),
        .E2_rd(E2_rd),
        .E2_forward_data(E2_fwd_val),
        .E3_reg_write(E3_reg_write),
        .E3_mem_read(E3_mem_read),
        .E3_rd(E3_rd),
        .E3_forward_data(E3_fwd_val),
        .W_reg_write(W_reg_write),
        .W_rd(W_rd),
        .W_write_data(W_write_data),
        .E1_forward_a(E1_forward_a),
        .E1_forward_b(E1_forward_b),
        .E1_forward_a_data(E1_forward_a_data),
        .E1_forward_b_data(E1_forward_b_data)
    );


    hazard_detection_unit hazard_unit (
        .D_rs1(D_rs1),
        .D_rs2(D_rs2),
        .D_uses_rs1(D_uses_rs1),
        .D_uses_rs2(D_uses_rs2),
        .RR_mem_read(IDRR_mem_read),
        .RR_rd(IDRR_rd),
        .E1_mem_read(E1_mem_read),
        .E1_rd(E1_rd),
        .E2_mem_read(E2_mem_read),
        .E2_rd(E2_rd),
        .E3_mem_read(E3_mem_read),
        .E3_rd(E3_rd),
        .stall(stall_frontend)
    );

    // =========================================================================
    // External Outputs
    // =========================================================================
    assign out_pc             = W_pc;
    assign out_writeback_data = W_write_data;
    assign out_reg_write      = W_reg_write;
    assign out_alu_result     = E2_alu_result;

endmodule
