/*
Calculates the target program counter for branch and jump instructions.
Aligns target address to 4-byte boundaries for JALR.
*/

module pc_target_calc (
    input logic [31:0] pc,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    input logic branch,
    input logic jump,
    input logic [2:0] branch_type,
    input logic [31:0] imm,
    input logic [31:0] alu_result,
    input logic condition_met_in,
    input logic [31:0] branch_target_in,

    output logic pc_sel,
    output logic [31:0] pc_target
);

// Combinational logic deciding target PC. Aligns JALR and branch targets to 4-byte boundaries.
always_comb begin
    pc_sel = jump || (branch && condition_met_in);

    if (jump) begin
        pc_target = alu_result & 32'hFFFFFFFC;
    end
    else if (branch && condition_met_in) begin
        pc_target = branch_target_in & 32'hFFFFFFFC;
    end
    else begin
        pc_target = 32'b0;
    end
end

endmodule
