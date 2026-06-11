`timescale 1ns / 1ps

/**
 * Hazard Detection Unit for Balanced 8-Stage Pipeline
 * 
 * Handles Load-Use hazards by stalling the front-end.
 * Data is available for forwarding from Stage 8 (WB).
 * Dependent instructions need data at Stage 5 (EX1).
 */

module hazard_detection_unit (
    // Inputs from Stage 3 (Decode)
    input  logic [4:0]  D_rs1,
    input  logic [4:0]  D_rs2,
    input  logic        D_uses_rs1,
    input  logic        D_uses_rs2,

    // Inputs from downstream stages (Load instructions)
    input  logic        RR_mem_read,    // S4
    input  logic [4:0]  RR_rd,
    
    input  logic        E1_mem_read,    // S5
    input  logic [4:0]  E1_rd,

    input  logic        E2_mem_read,    // S6
    input  logic [4:0]  E2_rd,
    
    input  logic        E3_mem_read,    // S7
    input  logic [4:0]  E3_rd,

    // Output
    output logic        stall
);

    always_comb begin
        stall = 1'b0;

        // Load-Use Hazard Detection
        // If a Load is in Stage 4, 5, 6, or 7 and its destination matches Decode's source

        // Stage 4 Load
        if (RR_mem_read && (RR_rd != 5'b0)) begin
            if ((RR_rd == D_rs1 && D_uses_rs1) || (RR_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end

        // Stage 5 Load
        if (E1_mem_read && (E1_rd != 5'b0)) begin
            if ((E1_rd == D_rs1 && D_uses_rs1) || (E1_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end

        // Stage 6 Load
        if (E2_mem_read && (E2_rd != 5'b0)) begin
            if ((E2_rd == D_rs1 && D_uses_rs1) || (E2_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end
        
        // Stage 7 Load
        if (E3_mem_read && (E3_rd != 5'b0)) begin
            if ((E3_rd == D_rs1 && D_uses_rs1) || (E3_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end
    end

endmodule
