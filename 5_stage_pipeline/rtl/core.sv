`timescale 1ns / 1ps

module core (
    input logic clk,
    input logic reset,
    
    input logic [31:0] hart_id,
    input logic core_stall,

    // Instruction Memory Interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_instruction,

    // Data Memory Interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_write_data,
    output logic        dmem_mem_read,
    output logic        dmem_mem_write,
    output logic [1:0]  dmem_size,
    output logic        dmem_unsigned,
    input  logic [31:0] dmem_read_data,
    output logic        dmem_is_lr,
    output logic        dmem_is_sc,
    input  logic        dmem_sc_success
);

    // ==========================================
    // Inter-stage Wires & Control Signals
    // ==========================================
    
    // --- Hazard & Control ---
    logic stall;
    logic flush;
    logic forward_a, forward_b;
    logic [31:0] forward_a_data, forward_b_data;

    // --- Fetch Stage Wires ---
    logic [31:0] F_pc;
    logic [31:0] F_instruction;

    // --- Decode Stage Wires ---
    logic [31:0] D_pc;
    logic [31:0] D_instruction;
    logic [31:0] D_rs1_data, D_rs2_data, D_immediate;
    logic [4:0]  D_rs1, D_rs2, D_rd;
    logic [31:0] D_pc_out;
    logic D_uses_rs2;
    logic [3:0]  D_alu_op;
    logic D_alu_src_a, D_alu_src_b;
    logic D_reg_write, D_mem_read, D_mem_write;
    logic [1:0]  D_mem_size;
    logic D_mem_unsigned;
    logic [1:0]  D_wb_sel;
    logic D_branch, D_jump;
    logic [2:0]  D_branch_type;
    logic D_is_atomic;
    logic [4:0]  D_amo_op;

    // --- Execute Stage Wires ---
    logic [31:0] E_rs1_data, E_rs2_data, E_immediate;
    logic [4:0]  E_rs1, E_rs2, E_rd;
    logic [31:0] E_pc;
    logic [3:0]  E_alu_op;
    logic E_alu_src_a, E_alu_src_b;
    logic E_reg_write, E_mem_read, E_mem_write;
    logic [1:0]  E_mem_size;
    logic E_mem_unsigned;
    logic [1:0]  E_wb_sel;
    logic E_branch, E_jump;
    logic [2:0]  E_branch_type;
    logic E_uses_rs2;
    logic [31:0] E_alu_result;
    logic E_pc_sel;
    logic [31:0] E_pc_target;
    logic [4:0]  E_rd_out;
    logic [4:0]  E_rs1_out, E_rs2_out;
    logic E_reg_write_out;
    logic [31:0] E_rs2_data_fwd;
    logic E_is_atomic;
    logic [4:0]  E_amo_op;

    // --- Memory Stage Wires ---
    logic [31:0] M_rs2_data;
    logic [4:0]  M_rs1, M_rs2;
    logic [1:0]  M_mem_size;
    logic M_mem_unsigned;
    logic M_mem_read, M_mem_write;
    logic [1:0]  M_wb_sel;
    logic [31:0] M_pc;
    logic [31:0] M_alu_result;
    logic [31:0] M_pc_target;
    logic M_pc_sel;
    logic [4:0]  M_rd;
    logic M_reg_write;
    logic [31:0] M_read_data;
    logic [31:0] M_alu_result_out;
    logic [4:0]  M_rs1_out, M_rs2_out, M_rd_out;
    logic M_reg_write_out;
    logic M_is_atomic;
    logic [4:0]  M_amo_op;

    // --- Writeback Stage Wires ---
    logic [31:0] W_read_data;
    logic [31:0] W_alu_result;
    logic [4:0]  W_rd;
    logic W_reg_write;
    logic [1:0]  W_wb_sel;
    logic [31:0] W_pc;
    logic [31:0] W_write_data;

    // ==========================================
    // Control Logic Assignments
    // ==========================================
    
    // Flush the pipeline when a branch/jump is taken in the Execute stage
    assign flush = E_pc_sel;

    // ==========================================
    // Pipeline Stages & Registers Instantiations
    // ==========================================

    // 1. Fetch Stage
    fetch fetch_inst (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .pc_sel(E_pc_sel),         // PC selection fed back from EX stage
        .pc_target(E_pc_target),   // Target address fed back from EX stage
        .imem_addr(imem_addr),
        .imem_instruction(imem_instruction),
        .pc(F_pc),
        .instruction(F_instruction)
    );

    // IF/ID Pipeline Register
    IF_ID if_id_inst (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .pc_in(F_pc),
        .instruction_in(F_instruction),
        .pc_out(D_pc),
        .instruction_out(D_instruction)
    );

    // 2. Decode Stage
    decode decode_inst (
        .clk(clk),
        .pc(D_pc),
        .instruction(D_instruction),
        .reg_write_wb(W_reg_write), // Writeback loops back here
        .rd_wb(W_rd),
        .write_data_wb(W_write_data),
        .rs1_data(D_rs1_data),
        .rs2_data(D_rs2_data),
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
        .branch_type(D_branch_type),
        .is_atomic(D_is_atomic),
        .amo_op(D_amo_op)
    );

    // ID/EX Pipeline Register
    ID_EX id_ex_inst (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .rs1_data_in(D_rs1_data),
        .rs2_data_in(D_rs2_data),
        .immediate_in(D_immediate),
        .rs1_in(D_rs1),
        .rs2_in(D_rs2),
        .rd_in(D_rd),
        .pc_in(D_pc_out),
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
        .uses_rs2_in(D_uses_rs2),
        .is_atomic_in(D_is_atomic),
        .amo_op_in(D_amo_op),
        
        .rs1_data_out(E_rs1_data),
        .rs2_data_out(E_rs2_data),
        .immediate_out(E_immediate),
        .rs1_out(E_rs1),
        .rs2_out(E_rs2),
        .rd_out(E_rd),
        .pc_out(E_pc),
        .alu_op_out(E_alu_op),
        .alu_src_a_out(E_alu_src_a),
        .alu_src_b_out(E_alu_src_b),
        .reg_write_out(E_reg_write),
        .mem_read_out(E_mem_read),
        .mem_write_out(E_mem_write),
        .mem_size_out(E_mem_size),
        .mem_unsigned_out(E_mem_unsigned),
        .wb_sel_out(E_wb_sel),
        .branch_out(E_branch),
        .jump_out(E_jump),
        .branch_type_out(E_branch_type),
        .uses_rs2_out(E_uses_rs2),
        .is_atomic_out(E_is_atomic),
        .amo_op_out(E_amo_op)
    );

    // 3. Execute Stage
    execute execute_inst (
        .pc(E_pc),
        .rs1_data(E_rs1_data),
        .rs2_data(E_rs2_data),
        .imm(E_immediate),
        .alu_src_a(E_alu_src_a),
        .alu_src_b(E_alu_src_b),
        .alu_op(E_alu_op),
        .rs1(E_rs1),
        .rs2(E_rs2),
        .rd(E_rd),
        .reg_write(E_reg_write),
        .branch(E_branch),
        .jump(E_jump),
        .branch_type(E_branch_type),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_a_data(forward_a_data),
        .forward_b_data(forward_b_data),
        .alu_result(E_alu_result),
        .pc_sel(E_pc_sel),
        .pc_target(E_pc_target),
        .rd_out(E_rd_out),
        .reg_write_out(E_reg_write_out),
        .rs1_out(E_rs1_out),
        .rs2_out(E_rs2_out),
        .rs2_data_out(E_rs2_data_fwd)
    );

    // EX/MEM Pipeline Register
    EX_MEM ex_mem_inst (
        .clk(clk),
        .reset(reset),
        .alu_result_in(E_alu_result),
        .pc_target_in(E_pc_target),
        .pc_sel_in(E_pc_sel),
        .rs2_data_in(E_rs2_data_fwd),
        .rs1_in(E_rs1_out),
        .rs2_in(E_rs2_out),
        .rd_in(E_rd_out),
        .reg_write_in(E_reg_write_out),
        .mem_read_in(E_mem_read),
        .mem_write_in(E_mem_write),
        .mem_size_in(E_mem_size),
        .mem_unsigned_in(E_mem_unsigned),
        .wb_sel_in(E_wb_sel),
        .pc_in(E_pc),
        .is_atomic_in(E_is_atomic),
        .amo_op_in(E_amo_op),
        
        .alu_result_out(M_alu_result),
        .pc_target_out(M_pc_target),
        .pc_sel_out(M_pc_sel),
        .rs2_data_out(M_rs2_data),
        .rs1_out(M_rs1),
        .rs2_out(M_rs2),
        .rd_out(M_rd),
        .reg_write_out(M_reg_write),
        .mem_read_out(M_mem_read),
        .mem_write_out(M_mem_write),
        .mem_size_out(M_mem_size),
        .mem_unsigned_out(M_mem_unsigned),
        .wb_sel_out(M_wb_sel),
        .pc_out(M_pc),
        .is_atomic_out(M_is_atomic),
        .amo_op_out(M_amo_op)
    );

    // 4. Memory Stage
    memory memory_inst (
        .clk(clk),
        .reset(reset),
        .alu_result(M_alu_result),
        .rs2_data(M_rs2_data),
        .mem_read(M_mem_read),
        .mem_write(M_mem_write),
        .mem_size(M_mem_size),
        .mem_unsigned(M_mem_unsigned),
        .rs1(M_rs1),
        .rs2(M_rs2),
        .rd(M_rd),
        .reg_write(M_reg_write),
        .is_atomic(M_is_atomic),
        .amo_op(M_amo_op),
        
        .dmem_addr(dmem_addr),
        .dmem_write_data(dmem_write_data),
        .dmem_mem_read(dmem_mem_read),
        .dmem_mem_write(dmem_mem_write),
        .dmem_size(dmem_size),
        .dmem_unsigned(dmem_unsigned),
        .dmem_read_data(dmem_read_data),
        .dmem_is_lr(dmem_is_lr),
        .dmem_is_sc(dmem_is_sc),
        .dmem_sc_success(dmem_sc_success),

        .read_data(M_read_data),
        .alu_result_output(M_alu_result_out),
        .rs1_out(M_rs1_out),
        .rs2_out(M_rs2_out),
        .rd_out(M_rd_out),
        .reg_write_out(M_reg_write_out)
    );

    // MEM/WB Pipeline Register
    MEM_WB mem_wb_inst (
        .clk(clk),
        .reset(reset),
        .read_data_in(M_read_data),
        .alu_result_output_in(M_alu_result_out),
        .rd_in(M_rd_out),
        .reg_write_in(M_reg_write_out),
        .wb_sel_in(M_wb_sel),
        .pc_in(M_pc),
        
        .read_data_out(W_read_data),
        .alu_result_output_out(W_alu_result),
        .rd_out(W_rd),
        .reg_write_out(W_reg_write),
        .wb_sel_out(W_wb_sel),
        .pc_out(W_pc)
    );

    // 5. Writeback Stage
    writeback writeback_inst (
        .pc(W_pc),
        .alu_result(W_alu_result),
        .mem_data(W_read_data),
        .wb_sel(W_wb_sel), 
        .write_data(W_write_data)
    );

    // ==========================================
    // Hazard Handling & Forwarding
    // ==========================================

    forwarding_unit fwd_unit (
        .rs1_ex(E_rs1),
        .rs2_ex(E_rs2),
        .uses_rs2(E_uses_rs2),
        .rd_mem(M_rd),
        .reg_write_mem(M_reg_write),
        .alu_result_mem(M_alu_result),
        .rd_wb(W_rd),
        .reg_write_wb(W_reg_write),
        .write_data_wb(W_write_data),
        
        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_a_data(forward_a_data),
        .forward_b_data(forward_b_data)
    );

    hazard_detection_unit hazard_unit (
        .mem_read_ex(E_mem_read),
        .rd_ex(E_rd),
        .rs1_id(D_rs1),
        .rs2_id(D_rs2),
        .uses_rs2(D_uses_rs2),
        .core_stall(core_stall),
        
        .stall(stall)
    );

endmodule