/* Decode stage of the RISC-V pipeline.
Responsible for decoding instructions and updating registers.
*/


module decode(
    input logic [31:0] pc,
    input logic [31:0] instruction,

    // Outputs to execute stage
    output logic [31:0] immediate,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [31:0] pc_out,

    // Control signals
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

// Field Extraction
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd  = instruction[11:7];

// Pass PC through to the Execute stage
assign pc_out = pc;

imm_gen ig (
    .instruction(instruction),
    .immediate(immediate)
);

control ctrl (
    .instruction(instruction),

    // Execution control
    .uses_rs1(uses_rs1),
    .uses_rs2(uses_rs2),
    .alu_op(alu_op),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b),
    
    // Memory and Writeback control
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .wb_sel(wb_sel),
    
    // Control flow
    .branch(branch),
    .jump(jump),
    .branch_type(branch_type)
);

endmodule
