`timescale 1ns / 1ps

/**
 * Hazard Detection Unit for 12-Stage Pipeline
 * 
 * Handles Load-Use hazards by stalling the pipeline.
 */

module hazard_detection_unit (
    // Inputs from Stage 4 (Decode)
    input  logic [4:0]  D_rs1,
    input  logic [4:0]  D_rs2,
    input  logic        D_uses_rs2,

    // Inputs from Stage 10 (M1)
    input  logic        M1_mem_read,
    input  logic [4:0]  M1_rd,

    // Inputs from Stage 11 (M)
    input  logic        M_reg_write,
    input  logic [1:0]  M_wb_sel,
    input  logic [4:0]  M_rd,

    // Output
    output logic        stall
);

    always_comb begin
        stall = 1'b0;
        
        // Stall on Load-Use Hazard
        // Load in Stage 10
        if (M1_mem_read && (M1_rd != 5'b0)) begin
            if (M1_rd == D_rs1 || (M1_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end
        
        // Load in Stage 11 (wb_sel 01 is MEM)
        if (M_reg_write && (M_wb_sel == 2'b01) && (M_rd != 5'b0)) begin
             if (M_rd == D_rs1 || (M_rd == D_rs2 && D_uses_rs2))
                stall = 1'b1;
        end
    end

endmodule
