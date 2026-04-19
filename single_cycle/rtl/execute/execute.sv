module execute (
    input logic [31:0] pc,
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm,
    input logic alu_src_a,
    input logic alu_src_b,
    input logic [3:0] alu_op,
    input logic branch,
    input logic jump,
    input logic [2:0] branch_type,

    output logic [31:0] alu_result,
    output logic [31:0] pc_target,
    output logic pc_sel
);

logic [31:0] operand_a;
logic [31:0] operand_b;

// Select operands
assign operand_a = alu_src_a ? pc : rs1_data;
assign operand_b = alu_src_b ? imm : rs2_data;

logic condition_met;

always_comb begin
    case (branch_type)
        3'b000: condition_met = rs1_data == rs2_data;
        3'b001: condition_met = rs1_data != rs2_data;
        3'b100: condition_met = $signed(rs1_data) < $signed(rs2_data);
        3'b101: condition_met = $signed(rs1_data) >= $signed(rs2_data);
        3'b110: condition_met = rs1_data < rs2_data;
        3'b111: condition_met = rs1_data >= rs2_data;
        default: condition_met = 0;
    endcase

    pc_sel = jump | (branch & condition_met);

    if (jump)
        pc_target = {alu_result[31:1], 1'b0};
    else if (branch & condition_met)
        pc_target = pc + imm;
end

// ALU instance
alu alu_inst (
    .A(operand_a),
    .B(operand_b),
    .control(alu_op),
    .result(alu_result)
);

endmodule