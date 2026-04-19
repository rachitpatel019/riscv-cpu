module decode(
    input logic clk,
    input logic [31:0] instruction,
    input logic [31:0] pc,             // NEW: PC input from Fetch stage

    // Write-back interface
    input logic reg_write_wb,
    input logic [4:0]  rd_wb,
    input logic [31:0] write_data_wb,

    // Outputs to execute stage
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] immediate,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic [31:0] pc_out,        // NEW: Route PC to Execute stage

    // Control signals
    output logic [3:0] alu_op,
    output logic alu_src_a,            // UPDATED: Replaced alu_src
    output logic alu_src_b,            // NEW: Second ALU source control
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic [1:0] mem_size,       // NEW: Size of memory access (B, H, W)
    output logic mem_unsigned,         // NEW: Unsigned memory load flag
    output logic [1:0] wb_sel,         // UPDATED: Replaced mem_to_reg for 3-way writeback
    output logic branch,
    output logic jump,
    output logic [2:0] branch_type     // NEW: Branch condition type
);

import decoder_package::*;

// Field Extraction
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd  = instruction[11:7];

// Pass PC through to the Execute stage
assign pc_out = pc;

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

    // Execution control
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