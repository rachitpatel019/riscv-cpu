/*
Forwarding unit for the 8-stage pipeline.
Calculates forwarding controls in ID/RR stage for execution operands.
*/

module forwarding_unit (
    input logic [4:0] IDRR_rs1,
    input logic [4:0] IDRR_rs2,
    input logic IDRR_uses_rs1,
    input logic IDRR_uses_rs2,

    input logic E2_reg_write,
    input logic E2_mem_read,
    input logic [4:0] E2_rd,

    input logic E3_reg_write,
    input logic [4:0] E3_rd,

    output logic [1:0] forward_a_sel,
    output logic [1:0] forward_b_sel
);

// Evaluates dependencies to generate register forwarding selectors for operands A and B.
always_comb begin
    forward_a_sel = 2'b00;
    forward_b_sel = 2'b00;

    if (IDRR_uses_rs1 && (IDRR_rs1 != 5'b0)) begin
        if (E2_reg_write && !E2_mem_read && (E2_rd == IDRR_rs1)) begin
            forward_a_sel = 2'b01;
        end
        else if (E3_reg_write && (E3_rd == IDRR_rs1)) begin
            forward_a_sel = 2'b10;
        end
    end

    if (IDRR_uses_rs2 && (IDRR_rs2 != 5'b0)) begin
        if (E2_reg_write && !E2_mem_read && (E2_rd == IDRR_rs2)) begin
            forward_b_sel = 2'b01;
        end
        else if (E3_reg_write && (E3_rd == IDRR_rs2)) begin
            forward_b_sel = 2'b10;
        end
    end
end

endmodule
