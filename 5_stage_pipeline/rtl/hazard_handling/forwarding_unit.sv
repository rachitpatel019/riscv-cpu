/* Forwarding Unit for a 5-stage pipeline
This unit checks for data hazards and forwards data from the MEM and WB stages to the EX stage when necessary.
TODO: Implement stalling logic for load use hazards */

module forwarding_unit (
    input logic [4:0] rs1_ex,
    input logic [4:0] rs2_ex,
    input logic uses_rs2, // Signal to indicate if the instruction in EX stage uses rs2

    input logic [4:0] rd_mem,
    input logic reg_write_mem,
    input logic [31:0] alu_result_mem,

    input logic [4:0] rd_wb,
    input logic reg_write_wb,
    input logic [31:0] write_data_wb,

    output logic forward_a,
    output logic forward_b,
    output logic [31:0] forward_a_data,
    output logic [31:0] forward_b_data
);

always_comb begin
    // Default
    forward_a = 0;
    forward_b = 0;
    forward_a_data = 32'b0;
    forward_b_data = 32'b0;

    // Forward A (rs1)
    if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs1_ex)) begin
        forward_a = 1;
        forward_a_data = alu_result_mem;
    end
    else if (uses_rs2 && reg_write_wb && (rd_wb != 0) && (rd_wb == rs1_ex)) begin
        forward_a = 1;
        forward_a_data = write_data_wb; 
    end

    // Forward B (rs2)
    if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs2_ex)) begin
        forward_b = 1;
        forward_b_data = alu_result_mem; 
    end
    else if (uses_rs2 && reg_write_wb && (rd_wb != 0) && (rd_wb == rs2_ex)) begin
        forward_b = 1;
        forward_b_data = write_data_wb; 
    end
end

endmodule