module data_sel (
    input logic [31:0] pc,
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm,
    input logic alu_src_a,
    input logic alu_src_b,
    input logic forward_a,
    input logic forward_b,
    input logic [31:0] forward_a_data,
    input logic [31:0] forward_b_data,

    output logic [31:0] operand_a,
    output logic [31:0] operand_b,
    output logic [31:0] rs2_data_out
);

assign operand_a = alu_src_a ? pc : (forward_a ? forward_a_data : rs1_data);
assign operand_b = alu_src_b ? imm : (forward_b ? forward_b_data : rs2_data);

assign rs2_data_out = forward_b ? forward_b_data : rs2_data;

endmodule