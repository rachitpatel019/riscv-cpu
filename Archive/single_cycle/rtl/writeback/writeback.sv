module writeback(
    input logic [31:0] pc,
    input logic [31:0] alu_result,
    input logic [31:0] read_data,
    input logic [1:0] wb_sel,

    output logic [31:0] write_data
);

always_comb begin
    case (wb_sel)
        2'b00: write_data = alu_result;
        2'b01: write_data = read_data;
        2'b10: write_data = pc + 32'd4;
        default: write_data = alu_result;
    endcase
end

endmodule