/*
Pipeline control unit for the 8-stage pipeline.
Combines hazard stall detection, global pipeline flushes, and early branch/jump redirects.
*/

module pipeline_control_unit (
    input logic [4:0] D_rs1,
    input logic [4:0] D_rs2,
    input logic D_uses_rs1,
    input logic D_uses_rs2,

    input logic RR_reg_write,
    input logic RR_mem_read,
    input logic [4:0] RR_rd,

    input logic E1_reg_write,
    input logic E1_mem_read,
    input logic [4:0] E1_rd,

    input logic E3_pc_sel,
    input logic IDRR_jump,
    input logic IDRR_uses_rs1,
    input logic IDRR_predict_taken,

    output logic stall,
    output logic flush,
    output logic stage4_pc_sel,
    output logic stage4_flush
);

// Decode-stage jump decoding signal.
logic IDRR_is_jal;

// Detects load-use data hazards from RR and EX1 stages to stall frontend pipeline.
always_comb begin
    stall = 1'b0;

    if (RR_reg_write && RR_mem_read && (RR_rd != 5'b0)) begin
        if ((RR_rd == D_rs1 && D_uses_rs1) || (RR_rd == D_rs2 && D_uses_rs2)) begin
            stall = 1'b1;
        end
    end

    if (E1_reg_write && (E1_rd != 5'b0)) begin
        if ((E1_rd == D_rs1 && D_uses_rs1) || (E1_rd == D_rs2 && D_uses_rs2)) begin
            if (E1_mem_read) begin
                stall = 1'b1;
            end
        end
    end
end

// Computes pipeline flushes, early jump PC redirects, and branch misprediction flushes.
always_comb begin
    flush = E3_pc_sel;
    IDRR_is_jal = IDRR_jump && !IDRR_uses_rs1;
    stage4_pc_sel = IDRR_predict_taken || IDRR_is_jal;
    stage4_flush = stage4_pc_sel;
end

endmodule
