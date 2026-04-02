module writeback(
    input logic [31:0] alu_result,
    input logic [31:0] read_data,
    input logic mem_to_reg,

    output logic [31:0] write_data
);

assign write_data = (mem_to_reg) ? read_data : alu_result;
    
endmodule