module MEM_WB(
    input logic clk,
    input logic reset,

    input logic stall,
    input logic flush,

    input logic [4:0] rs1_in,
    input logic [4:0] rs2_in,
    input logic [4:0] rd_in,
    input logic reg_write_in,
    input logic [31:0] alu_result_in,
    input logic [31:0] mem_read_data_in,
    input logic [1:0] wb_sel_in,
    input logic [31:0] pc_in,

    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,
    output logic [4:0] rd_out,
    output logic reg_write_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] mem_read_data_out,
    output logic [1:0] wb_sel_out,
    output logic [31:0] pc_out
);

always_ff @(posedge clk) begin
    if (reset || flush) begin
        rs1_out <= 5'b0;
        rs2_out <= 5'b0;
        rd_out <= 5'b0;
        reg_write_out <= 0;
        alu_result_out <= 32'b0;
        mem_read_data_out <= 32'b0;
        wb_sel_out <= 2'b0;
        pc_out <= 32'b0;
    end
    else if (stall) begin
        rs1_out <= rs1_out;
        rs2_out <= rs2_out;
        rd_out <= rd_out;
        reg_write_out <= reg_write_out;
        alu_result_out <= alu_result_out;
        mem_read_data_out <= mem_read_data_out;
        wb_sel_out <= wb_sel_out;
        pc_out <= pc_out;
    end
    else begin
        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        rd_out <= rd_in;
        reg_write_out <= reg_write_in;
        alu_result_out <= alu_result_in;
        mem_read_data_out <= mem_read_data_in;
        wb_sel_out <= wb_sel_in;
        pc_out <= pc_in;
    end
end
    
endmodule