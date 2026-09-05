/*
Writeback stage operand multiplexer.
Selects between memory read data and ALU execution results.
*/

module writeback (
    input logic [31:0] fwd_val,
    input logic [31:0] mem_data,
    input logic [1:0] wb_sel,

    output logic [31:0] write_data
);

// Multiplexes output writeback data, selecting memory read data and the forwarded value (pc+4 or alu result).
assign write_data = (wb_sel[0]) ? mem_data : fwd_val;

endmodule