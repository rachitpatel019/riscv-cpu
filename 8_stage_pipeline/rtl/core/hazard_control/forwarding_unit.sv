`timescale 1ns / 1ps

/**
 * Forwarding Unit for Balanced 8-Stage Pipeline (Optimized)
 * 
 * Performs address comparisons in Stage 4 (ID/RR) to pre-calculate
 * forwarding decisions for Stage 5 (EX1).
 */

module forwarding_unit (
    // Inputs from Stage 4 (ID/RR)
    input  logic [4:0]  IDRR_rs1,
    input  logic [4:0]  IDRR_rs2,
    input  logic        IDRR_uses_rs1,
    input  logic        IDRR_uses_rs2,

    // Inputs from downstream stages (Current positions)
    input  logic        E2_reg_write,   // S6/S7 boundary
    input  logic        E2_mem_read,
    input  logic [4:0]  E2_rd,

    input  logic        E3_reg_write,   // S7/S8 boundary
    input  logic [4:0]  E3_rd,

    // Outputs (Selection signals for S5)
    // 00: No forward, 01: S7 (E2), 10: S8 (E3/W)
    output logic [1:0]  forward_a_sel,
    output logic [1:0]  forward_b_sel
);

    always_comb begin
        forward_a_sel = 2'b00;
        forward_b_sel = 2'b00;

        // RS1 Forwarding Logic (Priority: S7 > S8)
        if (IDRR_uses_rs1 && (IDRR_rs1 != 5'b0)) begin
            if (E2_reg_write && !E2_mem_read && (E2_rd == IDRR_rs1))
                forward_a_sel = 2'b01;
            else if (E3_reg_write && (E3_rd == IDRR_rs1))
                forward_a_sel = 2'b10;
        end

        // RS2 Forwarding Logic
        if (IDRR_uses_rs2 && (IDRR_rs2 != 5'b0)) begin
            if (E2_reg_write && !E2_mem_read && (E2_rd == IDRR_rs2))
                forward_b_sel = 2'b01;
            else if (E3_reg_write && (E3_rd == IDRR_rs2))
                forward_b_sel = 2'b10;
        end
    end

endmodule
