/*
Branch evaluation unit for RISC-V.
Evaluates conditions and calculates the branch target address.
*/

module branch_eval (
    input logic [31:0] pc,
    input logic [31:0] imm,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    input logic [2:0] branch_type,

    output logic condition_met,
    output logic [31:0] branch_target
);

// Computes whether the branch condition is satisfied and evaluates branch target PC.
always_comb begin
    case (branch_type)
        3'b000: condition_met = (operand_a == operand_b);
        3'b001: condition_met = (operand_a != operand_b);
        3'b100: condition_met = ($signed(operand_a) < $signed(operand_b));
        3'b101: condition_met = ($signed(operand_a) >= $signed(operand_b));
        3'b110: condition_met = (operand_a < operand_b);
        3'b111: condition_met = (operand_a >= operand_b);
        default: condition_met = 1'b0;
    endcase
    branch_target = pc + imm;
end

endmodule
