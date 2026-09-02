/*
Pre-writeback operand multiplexer.
Selects between link PC (pc_plus_4) and ALU result for writeback.
*/

module fwd_sel (
    input logic [1:0] wb_sel,
    input logic [31:0] pc_plus_4,
    input logic [31:0] alu_result,

    output logic [31:0] fwd_val
);

// Multiplexes link PC vs ALU result
assign fwd_val = (wb_sel == 2'b10) ? pc_plus_4 : alu_result;

endmodule
