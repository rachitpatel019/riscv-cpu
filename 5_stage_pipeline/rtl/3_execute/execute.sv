/* Execute stage of the 5-stage RISC-V pipeline.
    This stage performs the following functions:
    1. Selects the operands for the ALU based on control signals and forwarding signals.
    2. Evaluates branch conditions.
    3. Computes the target address for branches and jumps. */

module execute (
    input logic [31:0] pc,
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm,
    input logic alu_src_a,
    input logic alu_src_b,
    input logic [3:0] alu_op,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic reg_write,
    input logic branch,
    input logic jump,
    input logic [2:0] branch_type,
    input logic forward_a,
    input logic forward_b,
    input logic [31:0] forward_a_data,
    input logic [31:0] forward_b_data,

    output logic [31:0] alu_result,
    output logic pc_sel,
    output logic [31:0] pc_target,
    output logic [4:0] rd_out,
    output logic reg_write_out,
    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out
);

// Pass through register locations for use in forwarding unit
assign rs1_out = rs1;
assign rs2_out = rs2;
assign rd_out = rd;
assign reg_write_out = reg_write;

logic [31:0] operand_a;
logic [31:0] operand_b;

// Select operands
assign operand_a = alu_src_a ? pc : (forward_a ? forward_a_data : rs1_data);
assign operand_b = alu_src_b ? imm : (forward_b ? forward_b_data : rs2_data);

pc_target_calculator pc_calc (
    .pc(pc),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .branch(branch),
    .jump(jump),
    .branch_type(branch_type),
    .imm(imm),
    .alu_result(alu_result),
    .pc_sel(pc_sel),
    .pc_target(pc_target)
);

alu alu_inst (
    .A(operand_a),
    .B(operand_b),
    .control(alu_op),
    .result(alu_result)
);

endmodule