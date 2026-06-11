/**
 * Stage 8: Branch Evaluation
 * 
 * Calculates branch condition and target address in Stage 8 (EX2)
 * to provide registered inputs to Stage 9 (EX3), optimizing timing.
 */

module branch_eval(
    input  logic [31:0] pc,
    input  logic [31:0] imm,
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    input  logic [2:0]  branch_type,

    output logic        condition_met,
    output logic [31:0] branch_target
);

    always_comb begin
        case (branch_type)
            3'b000: condition_met = (operand_a == operand_b);         // BEQ
            3'b001: condition_met = (operand_a != operand_b);         // BNE
            3'b100: condition_met = ($signed(operand_a) < $signed(operand_b));  // BLT
            3'b101: condition_met = ($signed(operand_a) >= $signed(operand_b)); // BGE
            3'b110: condition_met = (operand_a < operand_b);          // BLTU
            3'b111: condition_met = (operand_a >= operand_b);         // BGEU
            default: condition_met = 1'b0;
        endcase
        branch_target = pc + imm;
    end

endmodule
