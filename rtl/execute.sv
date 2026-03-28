module execute (
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm,
    input logic alu_src,
    input logic [3:0] alu_op,

    output logic [31:0] alu_result
);

logic [31:0] operand_b;

// Select second operand
assign operand_b = (alu_src) ? imm : rs2_data;

// ALU instance
alu alu_inst (
    .A(rs1_data),
    .B(operand_b),
    .control(alu_op),
    .result(alu_result)
);

endmodule