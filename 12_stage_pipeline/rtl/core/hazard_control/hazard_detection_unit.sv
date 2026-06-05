`timescale 1ns / 1ps

/**
 * Hazard Detection Unit for 12-Stage Pipeline
 * 
 * Handles Load-Use hazards by stalling the front-end of the pipeline.
 * Data is available for forwarding from Stage 11 (M).
 * Instructions reach Stage 7 (EX1) in 3 cycles from Stage 4 (Decode).
 * Therefore, a Load in Stages 5, 6, or 7 will not have data ready by the time
 * the dependent instruction reaches Stage 7.
 */

module hazard_detection_unit (
    // Inputs from Stage 4 (Decode)
    input  logic [4:0]  D_rs1,
    input  logic [4:0]  D_rs2,
    input  logic        D_uses_rs1,
    input  logic        D_uses_rs2,

    // Inputs from Stage 5 (ID/RR)
    input  logic        IDRR_mem_read,
    input  logic [4:0]  IDRR_rd,

    // Inputs from Stage 6 (RR)
    input  logic        RR_mem_read,
    input  logic [4:0]  RR_rd,

    // Inputs from Stage 7 (EX1)
    input  logic        E1_mem_read,
    input  logic [4:0]  E1_rd,

    // Output
    output logic        stall
);

    always_comb begin
        stall = 1'b0;
        
        // Load-Use Hazard Detection
        // If a Load is in Stage 5, 6, or 7 and its destination matches Decode's source
        
        // Stage 5 Load
        if (IDRR_mem_read && (IDRR_rd != 5'b0)) begin
            if ((IDRR_rd == D_rs1 && D_uses_rs1) || (IDRR_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end
        
        // Stage 6 Load
        if (RR_mem_read && (RR_rd != 5'b0)) begin
            if ((RR_rd == D_rs1 && D_uses_rs1) || (RR_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end

        // Stage 7 Load
        if (E1_mem_read && (E1_rd != 5'b0)) begin
            if ((E1_rd == D_rs1 && D_uses_rs1) || (E1_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end
    end

endmodule
