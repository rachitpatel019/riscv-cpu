`timescale 1ns / 1ps

/**
 * Forwarding Unit for 12-Stage Pipeline
 * 
 * Handles data hazards by bypassing results from later stages to EX1 (Stage 7).
 * Priority: Stage 8 > Stage 9 > Stage 10 > Stage 11 > Stage 12
 */

module forwarding_unit (
    // Inputs from Stage 7 (EX1)
    input  logic [4:0]  E1_rs1,
    input  logic [4:0]  E1_rs2,
    input  logic        E1_uses_rs1,
    input  logic        E1_uses_rs2,

    // Inputs from Stage 8 (EX2) - Result ready
    input  logic        E2_reg_write,
    input  logic        E2_mem_read,
    input  logic [4:0]  E2_rd,
    input  logic [31:0] E2_forward_data,

    // Inputs from Stage 9 (EX3) - Registered Result
    input  logic        E3_reg_write,
    input  logic        E3_mem_read,
    input  logic [4:0]  E3_rd,
    input  logic [31:0] E3_forward_data,

    // Inputs from Stage 10 (M1)
    input  logic        M1_reg_write,
    input  logic        M1_mem_read,
    input  logic [4:0]  M1_rd,
    input  logic [31:0] M1_forward_data,

    // Inputs from Stage 11 (M) - Load Data or ALU Result
    input  logic        M_reg_write,
    input  logic [4:0]  M_rd,
    input  logic [31:0] M_forward_data,

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

        // RS1 Forwarding Logic
        if (E1_uses_rs1) begin
            if (E2_reg_write && !E2_mem_read && (E2_rd != 5'b0) && (E2_rd == E1_rs1)) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = E2_forward_data;
            end
            else if (E3_reg_write && !E3_mem_read && (E3_rd != 5'b0) && (E3_rd == E1_rs1)) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = E3_forward_data;
            end
            else if (M1_reg_write && !M1_mem_read && (M1_rd != 5'b0) && (M1_rd == E1_rs1)) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = M1_forward_data;
            end
            else if (M_reg_write && (M_rd != 5'b0) && (M_rd == E1_rs1)) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = M_forward_data;
            end
            else if (W_reg_write && (W_rd != 5'b0) && (W_rd == E1_rs1)) begin
                E1_forward_a = 1'b1;
                E1_forward_a_data = W_write_data;
            end
        end

        // RS2 Forwarding Logic
        if (E1_uses_rs2) begin
            if (E2_reg_write && !E2_mem_read && (E2_rd != 5'b0) && (E2_rd == E1_rs2)) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = E2_forward_data;
            end
            else if (E3_reg_write && !E3_mem_read && (E3_rd != 5'b0) && (E3_rd == E1_rs2)) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = E3_forward_data;
            end
            else if (M1_reg_write && !M1_mem_read && (M1_rd != 5'b0) && (M1_rd == E1_rs2)) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = M1_forward_data;
            end
            else if (M_reg_write && (M_rd != 5'b0) && (M_rd == E1_rs2)) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = M_forward_data;
            end
            else if (W_reg_write && (W_rd != 5'b0) && (W_rd == E1_rs2)) begin
                E1_forward_b = 1'b1;
                E1_forward_b_data = W_write_data;
            end
        end
    end

endmodule
