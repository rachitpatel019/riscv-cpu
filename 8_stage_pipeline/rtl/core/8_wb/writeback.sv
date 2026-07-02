/*
Writeback stage operand multiplexer.
Selects between memory read data and ALU execution results.
*/

module writeback (
    input logic [31:0] pc,
    input logic [31:0] alu_result,
    input logic [31:0] mem_data,
    input logic [1:0] wb_sel,

    output logic [31:0] write_data
);

// Multiplexes output writeback data, selecting memory read data, ALU results, or link PC.
assign write_data = (wb_sel[0]) ? mem_data : alu_result;

endmodule