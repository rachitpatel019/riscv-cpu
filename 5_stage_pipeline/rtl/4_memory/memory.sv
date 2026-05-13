// Memory stage of the 5-stage RISC-V pipeline.

module memory (
    input logic clk,
    input logic [31:0] alu_result,
    input logic [31:0] rs2_data,
    input logic mem_read,
    input logic mem_write,
    input logic [1:0] mem_size,
    input logic mem_unsigned,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic reg_write,

    output logic [31:0] read_data,
    output logic [31:0] alu_result_output,
    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,
    output logic [4:0] rd_out,
    output logic reg_write_out
);

// Pass-through
assign alu_result_output = alu_result;
assign rs1_out = rs1;
assign rs2_out = rs2;
assign rd_out = rd;
assign reg_write_out = reg_write;

// Data memory instance
data_mem dmem (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .address(alu_result),
    .write_data(rs2_data),
    .read_data(read_data),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned)
);

endmodule