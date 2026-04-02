module memory (
    input logic clk,
    input logic [31:0] alu_result,
    input logic [31:0] rs2_data,
    input logic mem_read,
    input logic mem_write,

    output logic [31:0] read_data,
    output logic [31:0] alu_result_out
);

// Pass-through
assign alu_result_out = alu_result;

// Data memory instance
data_mem dmem (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .address(alu_result),
    .write_data(rs2_data),
    .read_data(read_data)
);

endmodule