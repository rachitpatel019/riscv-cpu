`timescale 1ns / 1ps

/**
 * Forwarding Unit for 12-Stage Pipeline
 * 
 * Handles data hazards by bypassing results from later stages to EX1 (Stage 7).
 */

module forwarding_unit (
    // Inputs from Stage 7 (EX1)
    input  logic [4:0]  E1_rs1,
    input  logic [4:0]  E1_rs2,
    input  logic        E1_uses_rs2,

    // Inputs from Stage 9 (EX3)
    input  logic        E3_reg_write,
    input  logic [4:0]  E3_rd,
    input  logic [31:0] E3_alu_result,

    // Inputs from Stage 10 (M1)
    input  logic        M1_reg_write,
    input  logic [4:0]  M1_rd,
    input  logic [31:0] M1_alu_result,

    // Inputs from Stage 11 (M)
    input  logic        M_reg_write,
    input  logic [4:0]  M_rd,
    input  logic [31:0] M_alu_result,

    // Inputs from Stage 12 (WB)
    input  logic        W_reg_write,
    input  logic [4:0]  W_rd,
    input  logic [31:0] W_write_data,

    // Outputs to Stage 7 (EX1)
    output logic        E1_forward_a,
    output logic        E1_forward_b,
    output logic [31:0] E1_forward_a_data,
    output logic [31:0] E1_forward_b_data
);

    always_comb begin
        E1_forward_a = 1'b0;
        E1_forward_b = 1'b0;
        E1_forward_a_data = 32'b0;
        E1_forward_b_data = 32'b0;

        // Priority 1: Stage 9 result (available in E3_alu_result)
        if (E3_reg_write && (E3_rd != 5'b0)) begin
            if (E3_rd == E1_rs1) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = E3_alu_result;
            end
            if (E3_rd == E1_rs2 && E1_uses_rs2) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = E3_alu_result;
            end
        end

        // Priority 2: Stage 10 result (available in M1_alu_result)
        if (M1_reg_write && (M1_rd != 5'b0)) begin
            if (M1_rd == E1_rs1 && !E1_forward_a) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = M1_alu_result;
            end
            if (M1_rd == E1_rs2 && E1_uses_rs2 && !E1_forward_b) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = M1_alu_result;
            end
        end

        // Priority 3: Stage 11 result (available in M_alu_result)
        if (M_reg_write && (M_rd != 5'b0)) begin
            if (M_rd == E1_rs1 && !E1_forward_a) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = M_alu_result;
            end
            if (M_rd == E1_rs2 && E1_uses_rs2 && !E1_forward_b) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = M_alu_result;
            end
        end

        // Priority 4: WB Stage result (available in W_write_data)
        if (W_reg_write && (W_rd != 5'b0)) begin
            if (W_rd == E1_rs1 && !E1_forward_a) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = W_write_data;
            end
            if (W_rd == E1_rs2 && E1_uses_rs2 && !E1_forward_b) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = W_write_data;
            end
        end
    end

endmodule
