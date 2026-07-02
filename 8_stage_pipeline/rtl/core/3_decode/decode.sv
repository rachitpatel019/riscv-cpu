/*
Decode stage of the RISC-V pipeline.
Extracts instruction fields, generates control signals, and sign-extends immediates.
*/

module decode (
    input logic [31:0] pc,
    input logic [31:0] instruction,

    output logic [31:0] immediate,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [31:0] pc_out,

    output logic uses_rs1,
    output logic uses_rs2,
    output logic [3:0] alu_op,
    output logic alu_src_a,
    output logic alu_src_b,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic [1:0] mem_size,
    output logic mem_unsigned,
    output logic [1:0] wb_sel,
    output logic branch,
    output logic jump,
    output logic [2:0] branch_type
);

import decoder_package::*;

// Extracts register source/destination addresses and PC.
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd = instruction[11:7];
assign pc_out = pc;

// Instantiates the immediate generator.
imm_gen ig (
    .instruction(instruction),
    .immediate(immediate)
);

// Instantiates the control logic generator.
control ctrl (
    .instruction(instruction),
    .uses_rs1(uses_rs1),
    .uses_rs2(uses_rs2),
    .alu_op(alu_op),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .wb_sel(wb_sel),
    .branch(branch),
    .jump(jump),
    .branch_type(branch_type)
);

endmodule
