`timescale 1ns / 1ps

/**
 * 12-Stage RISC-V (RV32I) CPU Core
 * 
 * Pipeline Stages:
 * 1.  Fetch (pc_update)
 * 2.  I-Mem Address (instr_mem)
 * 3.  IF/ID Register (IF_ID)
 * 4.  Decode (decode)
 * 5.  Reg Read Address (ID_RR Register + regfile sync read)
 * 6.  Reg Data / RR_EX1 Register
 * 7.  EX1: Operand Selection (data_sel)
 * 8.  EX2: ALU (alu + EX1_EX2 Reg)
 * 9.  EX3: PC Target / Branch Eval (pc_target_calc + EX2_EX3 Reg)
 * 10. MEM Address (EX3_MEM Reg + data_mem sync read)
 * 11. MEM Data / MEM_WB Register
 * 12. Writeback (writeback)
 */

module core (
    input  logic        clk,
    input  logic        reset,
    
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
    logic stall;
    logic flush;

    // Stage 1: Fetch
    logic [31:0] F_pc;
    
    // Stage 2: I-Mem
    logic [31:0] IM_pc_out;
    logic [31:0] IM_instruction;

    // Stage 3: IF/ID Register
    logic [31:0] D_pc;
    logic [31:0] D_instruction;

    // Stage 4: Decode
    logic [31:0] D_immediate;
    logic [4:0]  D_rs1, D_rs2, D_rd;
    logic [31:0] D_pc_out;
    logic        D_uses_rs2;
    logic [3:0]  D_alu_op;
    logic        D_alu_src_a, D_alu_src_b;
    logic        D_reg_write, D_mem_read, D_mem_write;
    logic [1:0]  D_mem_size;
    logic        D_mem_unsigned;
    logic [1:0]  D_wb_sel;
    logic        D_branch, D_jump;
    logic [2:0]  D_branch_type;

    // Stage 5: ID/RR Register (Control Flow)
    logic [31:0] IDRR_immediate;
    logic [4:0]  IDRR_rs1, IDRR_rs2, IDRR_rd;
    logic [31:0] IDRR_pc;
    logic        IDRR_uses_rs2;
    logic [3:0]  IDRR_alu_op;
    logic        IDRR_alu_src_a, IDRR_alu_src_b;
    logic        IDRR_reg_write, IDRR_mem_read, IDRR_mem_write;
    logic [1:0]  IDRR_mem_size;
    logic        IDRR_mem_unsigned;
    logic [1:0]  IDRR_wb_sel;
    logic        IDRR_branch, IDRR_jump;
    logic [2:0]  IDRR_branch_type;

    // Stage 6: RR Register (Control Flow)
    logic [31:0] RR_immediate;
    logic [4:0]  RR_rs1, RR_rs2, RR_rd;
    logic [31:0] RR_pc;
    logic        RR_uses_rs2;
    logic [3:0]  RR_alu_op;
    logic        RR_alu_src_a, RR_alu_src_b;
    logic        RR_reg_write, RR_mem_read, RR_mem_write;
    logic [1:0]  RR_mem_size;
    logic        RR_mem_unsigned;
    logic [1:0]  RR_wb_sel;
    logic        RR_branch, RR_jump;
    logic [2:0]  RR_branch_type;

    // Stage 6: Reg Read (Sync output)
    logic [31:0] RF_read_data1, RF_read_data2;

    // Stage 6 -> 7: RR_EX1 Register
    logic [31:0] E1_immediate;
    logic [4:0]  E1_rs1, E1_rs2, E1_rd;
    logic [31:0] E1_rs1_data, E1_rs2_data;
    logic [31:0] E1_pc;
    logic        E1_uses_rs2;
    logic [3:0]  E1_alu_op;
    logic        E1_alu_src_a, E1_alu_src_b;
    logic        E1_reg_write, E1_mem_read, E1_mem_write;
    logic [1:0]  E1_mem_size;
    logic        E1_mem_unsigned;
    logic [1:0]  E1_wb_sel;
    logic        E1_branch, E1_jump;
    logic [2:0]  E1_branch_type;

    // Stage 7: EX1 (Operand Selection)
    logic [31:0] E1_operand_a, E1_operand_b, E1_rs2_data_fwd;
    logic        E1_forward_a, E1_forward_b;
    logic [31:0] E1_forward_a_data, E1_forward_b_data;

    // Stage 8: EX2 (ALU)
    logic [31:0] E2_pc;
    logic [3:0]  E2_alu_op;
    logic [31:0] E2_imm;
    logic        E2_branch, E2_jump;
    logic [2:0]  E2_branch_type;
    logic        E2_reg_write, E2_mem_read, E2_mem_write;
    logic [1:0]  E2_mem_size;
    logic        E2_mem_unsigned;
    logic [1:0]  E2_wb_sel;
    logic [4:0]  E2_rs1, E2_rs2, E2_rd;
    logic [31:0] E2_operand_a, E2_operand_b, E2_rs2_data;
    logic [31:0] E2_alu_result;

    // Stage 9: EX3 (Branch Eval)
    logic [31:0] E3_pc;
    logic [31:0] E3_imm;
    logic        E3_branch, E3_jump;
    logic [2:0]  E3_branch_type;
    logic        E3_reg_write, E3_mem_read, E3_mem_write;
    logic [1:0]  E3_mem_size;
    logic        E3_mem_unsigned;
    logic [1:0]  E3_wb_sel;
    logic [4:0]  E3_rs1, E3_rs2, E3_rd;
    logic [31:0] E3_operand_a, E3_operand_b, E3_rs2_data;
    logic [31:0] E3_alu_result;
    logic        E3_pc_sel;
    logic [31:0] E3_pc_target;

    // Stage 10: MEM Address
    logic        M1_reg_write, M1_mem_read, M1_mem_write;
    logic [1:0]  M1_mem_size;
    logic        M1_mem_unsigned;
    logic [1:0]  M1_wb_sel;
    logic [4:0]  M1_rs1, M1_rs2, M1_rd;
    logic [31:0] M1_rs2_data, M1_alu_result;
    logic [31:0] M1_pc;

    // Stage 11: MEM Data
    logic        M_reg_write;
    logic [1:0]  M_wb_sel;
    logic [4:0]  M_rs1, M_rs2, M_rd;
    logic [31:0] M_rs2_data, M_alu_result;
    logic [31:0] M_pc;
    logic [31:0] M_read_data;

    // Stage 11 -> 12: MEM/WB Register
    logic [4:0]  W_rs1, W_rs2, W_rd;
    logic        W_reg_write;
    logic [31:0] W_alu_result, W_mem_read_data;
    logic [1:0]  W_wb_sel;
    logic [31:0] W_pc;

    // Stage 12: Writeback
    logic [31:0] W_write_data;

    // =========================================================================
    // Control Logic
    // =========================================================================
    
    assign flush = E3_pc_sel;

    // =========================================================================
    // Stage 1: Fetch
    // =========================================================================
    pc_update stage1_fetch (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_sel(E3_pc_sel),
        .pc_target(E3_pc_target),
        .pc(F_pc)
    );

    // =========================================================================
    // Stage 2: I-Mem
    // =========================================================================
    instr_mem stage2_imem (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc(F_pc),
        .pc_out(IM_pc_out),
        .instruction(IM_instruction)
    );

    // =========================================================================
    // Stage 3: IF/ID Register
    // =========================================================================
    IF_ID stage3_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_in(IM_pc_out),
        .instruction_in(IM_instruction),
        .pc_out(D_pc),
        .instruction_out(D_instruction)
    );

    // =========================================================================
    // Stage 4: Decode
    // =========================================================================
    decode stage4_decode (
        .clk(clk),
        .en(!stall),
        .pc(D_pc),
        .instruction(D_instruction),
        .reg_write_wb(W_reg_write),
        .rd_wb(W_rd),
        .write_data_wb(W_write_data),
        .immediate(D_immediate),
        .rs1(D_rs1),
        .rs2(D_rs2),
        .rd(D_rd),
        .pc_out(D_pc_out),
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

    // =========================================================================
    // Stage 5: ID/RR Register
    // =========================================================================
    ID_RR stage5_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .immediate_in(D_immediate),
        .rs1_in(D_rs1),
        .rs2_in(D_rs2),
        .rd_in(D_rd),
        .pc_in(D_pc_out),
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
    // Stage 5/6: Register Read
    // =========================================================================
    regfile stage5_regfile (
        .clk(clk),
        .stall(stall),
        .read_address1(IDRR_rs1),
        .read_address2(IDRR_rs2),
        .read_data1(RF_read_data1),
        .read_data2(RF_read_data2),
        .write_address(W_rd),
        .write_data(W_write_data),
        .write_enable(W_reg_write)
    );

    // =========================================================================
    // Stage 6: RR Register
    // =========================================================================
    RR stage6_rr_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .immediate_in(IDRR_immediate),
        .rs1_in(IDRR_rs1),
        .rs2_in(IDRR_rs2),
        .rd_in(IDRR_rd),
        .pc_in(IDRR_pc),
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
        .immediate_out(RR_immediate),
        .rs1_out(RR_rs1),
        .rs2_out(RR_rs2),
        .rd_out(RR_rd),
        .pc_out(RR_pc),
        .uses_rs2_out(RR_uses_rs2),
        .alu_op_out(RR_alu_op),
        .alu_src_a_out(RR_alu_src_a),
        .alu_src_b_out(RR_alu_src_b),
        .reg_write_out(RR_reg_write),
        .mem_read_out(RR_mem_read),
        .mem_write_out(RR_mem_write),
        .mem_size_out(RR_mem_size),
        .mem_unsigned_out(RR_mem_unsigned),
        .wb_sel_out(RR_wb_sel),
        .branch_out(RR_branch),
        .jump_out(RR_jump),
        .branch_type_out(RR_branch_type)
    );

    // =========================================================================
    // Stage 6: RR_EX1 Register
    // =========================================================================
    RR_EX1 stage6_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .immediate_in(RR_immediate),
        .rs1_in(RR_rs1),
        .rs2_in(RR_rs2),
        .rs1_data_in(RF_read_data1),
        .rs2_data_in(RF_read_data2),
        .rd_in(RR_rd),
        .pc_in(RR_pc),
        .uses_rs2_in(RR_uses_rs2),
        .alu_op_in(RR_alu_op),
        .alu_src_a_in(RR_alu_src_a),
        .alu_src_b_in(RR_alu_src_b),
        .reg_write_in(RR_reg_write),
        .mem_read_in(RR_mem_read),
        .mem_write_in(RR_mem_write),
        .mem_size_in(RR_mem_size),
        .mem_unsigned_in(RR_mem_unsigned),
        .wb_sel_in(RR_wb_sel),
        .branch_in(RR_branch),
        .jump_in(RR_jump),
        .branch_type_in(RR_branch_type),
        .immediate_out(E1_immediate),
        .rs1_out(E1_rs1),
        .rs2_out(E1_rs2),
        .rs1_data_out(E1_rs1_data),
        .rs2_data_out(E1_rs2_data),
        .rd_out(E1_rd),
        .pc_out(E1_pc),
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
    // Stage 7: EX1 (Data Selection)
    // =========================================================================
    data_sel stage7_data_sel (
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

    // =========================================================================
    // Stage 8: EX2 (ALU)
    // =========================================================================
    EX1_EX2 stage8_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_in(E1_pc),
        .alu_op_in(E1_alu_op),
        .imm_in(E1_immediate),
        .branch_in(E1_branch),
        .jump_in(E1_jump),
        .branch_type_in(E1_branch_type),
        .reg_write_in(E1_reg_write),
        .rs1_in(E1_rs1),
        .rs2_in(E1_rs2),
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
        .rs1_out(E2_rs1),
        .rs2_out(E2_rs2),
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

    alu stage8_alu (
        .A(E2_operand_a),
        .B(E2_operand_b),
        .control(E2_alu_op),
        .result(E2_alu_result)
    );

    // =========================================================================
    // Stage 9: EX3 (PC Target Calc)
    // =========================================================================
    EX2_EX3 stage9_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_in(E2_pc),
        .imm_in(E2_imm),
        .branch_in(E2_branch),
        .jump_in(E2_jump),
        .branch_type_in(E2_branch_type),
        .reg_write_in(E2_reg_write),
        .rs1_in(E2_rs1),
        .rs2_in(E2_rs2),
        .rd_in(E2_rd),
        .operand_a_in(E2_operand_a),
        .operand_b_in(E2_operand_b),
        .rs2_data_in(E2_rs2_data),
        .alu_result_in(E2_alu_result),
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
        .rs1_out(E3_rs1),
        .rs2_out(E3_rs2),
        .rd_out(E3_rd),
        .operand_a_out(E3_operand_a),
        .operand_b_out(E3_operand_b),
        .rs2_data_out(E3_rs2_data),
        .alu_result_out(E3_alu_result),
        .mem_read_out(E3_mem_read),
        .mem_write_out(E3_mem_write),
        .mem_size_out(E3_mem_size),
        .mem_unsigned_out(E3_mem_unsigned),
        .wb_sel_out(E3_wb_sel)
    );

    pc_target_calc stage9_calc (
        .pc(E3_pc),
        .operand_a(E3_operand_a),
        .operand_b(E3_operand_b),
        .branch(E3_branch),
        .jump(E3_jump),
        .branch_type(E3_branch_type),
        .imm(E3_imm),
        .alu_result(E3_alu_result),
        .pc_sel(E3_pc_sel),
        .pc_target(E3_pc_target)
    );

    // =========================================================================
    // Stage 10: MEM Address
    // =========================================================================
    EX3_MEM stage10_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(1'b0), // MEM stage is not flushed by Stage 9 branches
        .reg_write_in(E3_reg_write),
        .rs1_in(E3_rs1),
        .rs2_in(E3_rs2),
        .rd_in(E3_rd),
        .rs2_data_in(E3_rs2_data),
        .alu_result_in(E3_alu_result),
        .pc_sel_in(E3_pc_sel),
        .pc_target_in(E3_pc_target),
        .mem_read_in(E3_mem_read),
        .mem_write_in(E3_mem_write),
        .mem_size_in(E3_mem_size),
        .mem_unsigned_in(E3_mem_unsigned),
        .wb_sel_in(E3_wb_sel),
        .pc_in(E3_pc),
        .reg_write_out(M1_reg_write),
        .rs1_out(M1_rs1),
        .rs2_out(M1_rs2),
        .rd_out(M1_rd),
        .rs2_data_out(M1_rs2_data),
        .alu_result_out(M1_alu_result),
        .mem_read_out(M1_mem_read),
        .mem_write_out(M1_mem_write),
        .mem_size_out(M1_mem_size),
        .mem_unsigned_out(M1_mem_unsigned),
        .wb_sel_out(M1_wb_sel),
        .pc_out(M1_pc)
    );

    data_mem stage10_data_mem (
        .clk(clk),
        .stall(stall),
        .mem_read(M1_mem_read),
        .mem_write(M1_mem_write),
        .address(M1_alu_result),
        .write_data(M1_rs2_data),
        .mem_size(M1_mem_size),
        .mem_unsigned(M1_mem_unsigned),
        .read_data(M_read_data)
    );

    // =========================================================================
    // Stage 11: MEM Data
    // =========================================================================
    MEM stage11_mem_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(1'b0), // MEM stage is not flushed by Stage 9 branches
        .rs1_in(M1_rs1),
        .rs2_in(M1_rs2),
        .rd_in(M1_rd),
        .reg_write_in(M1_reg_write),
        .alu_result_in(M1_alu_result),
        .rs2_data_in(M1_rs2_data),
        .wb_sel_in(M1_wb_sel),
        .pc_in(M1_pc),
        .rs1_out(M_rs1),
        .rs2_out(M_rs2),
        .rd_out(M_rd),
        .reg_write_out(M_reg_write),
        .alu_result_out(M_alu_result),
        .rs2_data_out(M_rs2_data),
        .wb_sel_out(M_wb_sel),
        .pc_out(M_pc)
    );

    MEM_WB stage11_reg (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(1'b0), // WB stage is not flushed by Stage 9 branches
        .rs1_in(M_rs1),
        .rs2_in(M_rs2),
        .rd_in(M_rd),
        .reg_write_in(M_reg_write),
        .alu_result_in(M_alu_result),
        .mem_read_data_in(M_read_data),
        .wb_sel_in(M_wb_sel),
        .pc_in(M_pc),
        .rs1_out(W_rs1),
        .rs2_out(W_rs2),
        .rd_out(W_rd),
        .reg_write_out(W_reg_write),
        .alu_result_out(W_alu_result),
        .mem_read_data_out(W_mem_read_data),
        .wb_sel_out(W_wb_sel),
        .pc_out(W_pc)
    );

    // =========================================================================
    // Stage 12: Writeback
    // =========================================================================
    writeback stage12_wb (
        .pc(W_pc),
        .alu_result(W_alu_result),
        .mem_data(W_mem_read_data),
        .wb_sel(W_wb_sel),
        .write_data(W_write_data)
    );

    // =========================================================================
    // Forwarding & Hazard Units (Placeholders/Basic Logic)
    // =========================================================================

    // Forwarding to Stage 7 (EX1)
    always_comb begin
        E1_forward_a = 0;
        E1_forward_b = 0;
        E1_forward_a_data = 32'b0;
        E1_forward_b_data = 32'b0;

        // Priority 1: Stage 9 result (available in E3_alu_result)
        if (E3_reg_write && (E3_rd != 0)) begin
            if (E3_rd == E1_rs1) begin
                E1_forward_a = 1;
                E1_forward_a_data = E3_alu_result;
            end
            if (E3_rd == E1_rs2 && E1_uses_rs2) begin
                E1_forward_b = 1;
                E1_forward_b_data = E3_alu_result;
            end
        end

        // Priority 2: Stage 10 result (available in M1_alu_result)
        if (M1_reg_write && (M1_rd != 0)) begin
            if (M1_rd == E1_rs1 && !E1_forward_a) begin
                E1_forward_a = 1;
                E1_forward_a_data = M1_alu_result;
            end
            if (M1_rd == E1_rs2 && E1_uses_rs2 && !E1_forward_b) begin
                E1_forward_b = 1;
                E1_forward_b_data = M1_alu_result;
            end
        end

        // Priority 3: Stage 11 result (available in M_alu_result)
        if (M_reg_write && (M_rd != 0)) begin
            if (M_rd == E1_rs1 && !E1_forward_a && !E1_forward_a) begin
                E1_forward_a = 1;
                E1_forward_a_data = M_alu_result;
            end
            if (M_rd == E1_rs2 && E1_uses_rs2 && !E1_forward_b && !E1_forward_b) begin
                E1_forward_b = 1;
                E1_forward_b_data = M_alu_result;
            end
        end

        // Priority 4: WB Stage result (available in W_write_data)
        if (W_reg_write && (W_rd != 0)) begin
            if (W_rd == E1_rs1 && !E1_forward_a && !E1_forward_a && !E1_forward_a) begin
                E1_forward_a = 1;
                E1_forward_a_data = W_write_data;
            end
            if (W_rd == E1_rs2 && E1_uses_rs2 && !E1_forward_b && !E1_forward_b && !E1_forward_b) begin
                E1_forward_b = 1;
                E1_forward_b_data = W_write_data;
            end
        end
    end

    // Stall logic (Very basic)
    always_comb begin
        stall = 0;
        // Stall on Load-Use Hazard
        // Load in Stage 10
        if (M1_mem_read && (M1_rd != 0)) begin
            if (M1_rd == D_rs1 || (M1_rd == D_rs2 && D_uses_rs2))
                stall = 1;
        end
        // Load in Stage 11
        if (M_reg_write && M_wb_sel == 2'b01 && (M_rd != 0)) begin // wb_sel 01 is MEM
             if (M_rd == D_rs1 || (M_rd == D_rs2 && D_uses_rs2))
                stall = 1;
        end
    end

    // =========================================================================
    // External Outputs
    // =========================================================================
    assign out_pc             = W_pc;
    assign out_writeback_data = W_write_data;
    assign out_reg_write      = W_reg_write;
    assign out_alu_result     = E2_alu_result;

endmodule
