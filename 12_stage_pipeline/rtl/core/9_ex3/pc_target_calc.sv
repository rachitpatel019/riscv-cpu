module pc_target_calc(
    input logic [31:0] pc,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,

    input logic branch,
    input logic jump,
    input logic [2:0] branch_type,

    input logic [31:0] imm,
    input logic [31:0] alu_result,

    output logic pc_sel,
    output logic [31:0] pc_target
);

logic condition_met;

always_comb begin
    case (branch_type)
        3'b000: condition_met = operand_a == operand_b;
        3'b001: condition_met = operand_a != operand_b;
        3'b100: condition_met = $signed(operand_a) < $signed(operand_b);
        3'b101: condition_met = $signed(operand_a) >= $signed(operand_b);
        3'b110: condition_met = operand_a < operand_b;
        3'b111: condition_met = operand_a >= operand_b;
        default: condition_met = 0;
    endcase

    pc_sel = jump || (branch && condition_met);

    if (jump)
        pc_target = {alu_result[31:1], 1'b0};
    else if (branch & condition_met)
        pc_target = pc + imm;
	else
        pc_target = 32'b0;
end

endmodule