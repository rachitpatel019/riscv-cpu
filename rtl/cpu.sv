module cpu (
    input logic clk,
    input logic reset
);

// FETCH
logic [31:0] pc;
logic [31:0] instruction;

fetch fetch_inst (
    .clk(clk),
    .reset(reset),
    .pc(pc),
    .instruction(instruction)
);

// DECODE
logic [31:0] rs1_data, rs2_data, imm;
logic [4:0]  rs1, rs2, rd;

// Control signals
logic alu_src, mem_read, mem_write, mem_to_reg, reg_write;
logic branch, jump;
logic [3:0] alu_op;
logic [31:0] write_data;

decode decode_inst (
    .clk(clk),
    .instruction(instruction),

    // Writeback interface
    .reg_write_wb(reg_write),
    .rd_wb(rd),
    .write_data_wb(write_data),

    // Outputs
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .immediate(imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),

    .alu_src(alu_src),
    .alu_op(alu_op),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .reg_write(reg_write),
    .branch(branch),
    .jump(jump)
);

// EXECUTE
logic [31:0] alu_result;

execute execute_inst (
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .imm(imm),
    .alu_src(alu_src),
    .alu_op(alu_op),
    .alu_result(alu_result)
);

// MEMORY
logic [31:0] read_data;

memory memory_inst (
    .clk(clk),
    .alu_result(alu_result),
    .rs2_data(rs2_data),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .read_data(read_data),
    .alu_result_out() // unused for now
);

// WRITEBACK

writeback wb_inst (
    .alu_result(alu_result),
    .read_data(read_data),
    .mem_to_reg(mem_to_reg),
    .write_data(write_data)
);

endmodule