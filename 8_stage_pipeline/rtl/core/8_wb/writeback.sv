// Writeback stage - Optimized 2-to-1 Mux
module writeback(
    input logic [31:0] pc,            // Not used anymore in simplified mux
    input logic [31:0] alu_result,    // Pre-muxed with PC+4 in S7
    input logic [31:0] mem_data,
    input logic [1:0]  wb_sel,

    output logic [31:0] write_data
);

// wb_sel == 2'b01 is Load instruction
assign write_data = (wb_sel[0]) ? mem_data : alu_result;

endmodule