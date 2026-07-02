/*
Pipeline register between EX1 and EX2 stages.
Holds execution operands, memory control, and writeback select lines.
*/

module EX1_EX2 (
    input logic clk,
    input logic reset,
    input logic flush,

    input logic [31:0] pc_in,
    input logic [3:0] alu_op_in,
    input logic [31:0] imm_in,
    input logic branch_in,
    input logic jump_in,
    input logic [2:0] branch_type_in,

    input logic reg_write_in,
    input logic [4:0] rd_in,

    input logic [31:0] operand_a_in,
    input logic [31:0] operand_b_in,
    input logic [31:0] rs2_data_in,

    input logic mem_read_in,
    input logic mem_write_in,
    input logic [1:0] mem_size_in,
    input logic mem_unsigned_in,
    input logic [1:0] wb_sel_in,

    output logic [31:0] pc_out,
    output logic [3:0] alu_op_out,
    output logic [31:0] imm_out,
    output logic branch_out,
    output logic jump_out,
    output logic [2:0] branch_type_out,

    output logic reg_write_out,
    output logic [4:0] rd_out,

    output logic [31:0] operand_a_out,
    output logic [31:0] operand_b_out,
    output logic [31:0] rs2_data_out,

    output logic mem_read_out,
    output logic mem_write_out,
    output logic [1:0] mem_size_out,
    output logic mem_unsigned_out,
    output logic [1:0] wb_sel_out
);

// Propagates Stage 5 (EX1) execution inputs to Stage 6 (EX2), supporting flush and reset.
always_ff @(posedge clk) begin
    if (reset || flush) begin
        pc_out <= 32'b0;
        alu_op_out <= 4'b0;
        imm_out <= 32'b0;
        branch_out <= 0;
        jump_out <= 0;
        branch_type_out <= 3'b0;
        reg_write_out <= 0;
        rd_out <= 5'b0;
        operand_a_out <= 32'b0;
        operand_b_out <= 32'b0;
        rs2_data_out <= 32'b0;
        mem_read_out <= 0;
        mem_write_out <= 0;
        mem_size_out <= 2'b0;
        mem_unsigned_out <= 0;
        wb_sel_out <= 2'b0;
    end
    else begin
        pc_out <= pc_in;
        alu_op_out <= alu_op_in;
        imm_out <= imm_in;
        branch_out <= branch_in;
        jump_out <= jump_in;
        branch_type_out <= branch_type_in;
        reg_write_out <= reg_write_in;
        rd_out <= rd_in;
        operand_a_out <= operand_a_in;
        operand_b_out <= operand_b_in;
        rs2_data_out <= rs2_data_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        mem_size_out <= mem_size_in;
        mem_unsigned_out <= mem_unsigned_in;
        wb_sel_out <= wb_sel_in;
    end
end

endmodule
