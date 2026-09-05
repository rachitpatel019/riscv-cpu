/*
Calculates the target program counter for branch and jump instructions.
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
    input logic predicted_taken_in,

    output logic pc_sel,
    output logic [31:0] pc_target
);

// Combinational logic deciding target PC.
always_comb begin
    logic actual_taken;
    logic mispredict;

    actual_taken = branch && condition_met_in;
    mispredict = branch && (actual_taken != predicted_taken_in);

    // Determines whether PC should be incremented by 4 or updated to target
    pc_sel = jump || mispredict;

    if (jump) begin
        pc_target = {alu_result[31:2], 2'b0};
    end
    else if (mispredict) begin
        if (actual_taken) begin
            pc_target = {branch_target_in[31:2], 2'b0};
        end else begin
            pc_target = pc + 32'd4;
        end
    end
    else begin
        pc_target = 32'b0;
    end
end

endmodule
