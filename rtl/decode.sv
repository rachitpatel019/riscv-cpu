module decode(
    input  logic clk,
    input  logic [31:0] instruction,

    // Write-back interface
    input  logic reg_write_wb,
    input  logic [4:0]  rd_wb,
    input  logic [31:0] write_data_wb,

    // Outputs to execute stage
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] immediate,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    // Control signals
    output logic [3:0] alu_op,
    output logic alu_src,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic mem_to_reg,
    output logic branch,
    output logic jump
);

import decoder_package::*;

// Field Extraction
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd  = instruction[11:7];

// Register File
regfile rf (
    .clk(clk),

    .read_address1(rs1),
    .read_address2(rs2),
    .read_data1(rs1_data),
    .read_data2(rs2_data),

    .write_address(rd_wb),
    .write_data(write_data_wb),
    .write_enable(reg_write_wb)
);

// Immediate Generator
imm_gen ig (
    .instruction(instruction),
    .immediate(immediate)
);

// Control Unit
control ctrl (
    .instruction(instruction),

    .alu_op(alu_op),
    .alu_src(alu_src),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .branch(branch),
    .jump(jump)
);

endmodule