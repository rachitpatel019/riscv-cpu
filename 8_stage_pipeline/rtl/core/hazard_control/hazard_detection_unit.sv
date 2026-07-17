/*
Hazard detection unit for the 8-stage pipeline.
Stalls fetch and decode stages on detecting data hazards.
*/

module hazard_detection_unit (
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

    output logic stall
);

// Determines if a stall is required by comparing Decode registers with downstream destination registers.
always_comb begin
    stall = 1'b0;

    if (RR_reg_write && (RR_rd != 5'b0)) begin
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

endmodule
