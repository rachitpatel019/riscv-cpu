/*
Pipeline register between EX2 and EX3 stages.
Holds PC, execution results, memory parameters, and writeback select lines.
*/

module EX2_EX3 (
    input logic clk,
    input logic reset,
    input logic flush,

    input logic [31:0] pc_in,
    input logic [31:0] imm_in,
    input logic branch_in,
    input logic jump_in,
    input logic [2:0] branch_type_in,
    input logic predicted_taken_in,

    input logic reg_write_in,
    input logic [4:0] rd_in,

    input logic [31:0] operand_a_in,
    input logic [31:0] operand_b_in,
    input logic [31:0] rs2_data_in,
    input logic [31:0] alu_result_in,
    input logic condition_met_in,
    input logic [31:0] branch_target_in,

    input logic mem_read_in,
    input logic mem_write_in,
    input logic [1:0] mem_size_in,
    input logic mem_unsigned_in,
    input logic [1:0] wb_sel_in,
    input logic [1:0] counter_val_in,

    output logic [31:0] pc_out,
    output logic [31:0] imm_out,
    output logic branch_out,
    output logic jump_out,
    output logic [2:0] branch_type_out,
    output logic predicted_taken_out,

    output logic reg_write_out,
    output logic [4:0] rd_out,

    output logic [31:0] operand_a_out,
    output logic [31:0] operand_b_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] alu_result_out,
    output logic condition_met_out,
    output logic [31:0] branch_target_out,

    output logic mem_read_out,
    output logic mem_write_out,
    output logic [1:0] mem_size_out,
    output logic mem_unsigned_out,
    output logic [1:0] wb_sel_out,
    output logic [1:0] counter_val_out
);

// Propagates Stage 6 (EX2) execution results to Stage 7 (EX3/MEM), supporting flush and reset.
always_ff @(posedge clk) begin
    if (reset || flush) begin
        pc_out <= 32'b0;
        branch_out <= 0;
        jump_out <= 0;
        branch_type_out <= 3'b0;
        predicted_taken_out <= 0;
        reg_write_out <= 0;
        rd_out <= 5'b0;
        operand_a_out <= 32'b0;
        operand_b_out <= 32'b0;
        rs2_data_out <= 32'b0;
        alu_result_out <= 32'b0;
        condition_met_out <= 0;
        branch_target_out <= 32'b0;
        imm_out <= 32'b0;
        mem_read_out <= 0;
        mem_write_out <= 0;
        mem_size_out <= 2'b0;
        mem_unsigned_out <= 0;
        wb_sel_out <= 2'b0;
        counter_val_out <= 2'b0;
    end
    else begin
        pc_out <= pc_in;
        branch_out <= branch_in;
        jump_out <= jump_in;
        branch_type_out <= branch_type_in;
        predicted_taken_out <= predicted_taken_in;
        reg_write_out <= reg_write_in;
        rd_out <= rd_in;
        operand_a_out <= operand_a_in;
        operand_b_out <= operand_b_in;
        rs2_data_out <= rs2_data_in;
        alu_result_out <= alu_result_in;
        condition_met_out <= condition_met_in;
        branch_target_out <= branch_target_in;
        imm_out <= imm_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        mem_size_out <= mem_size_in;
        mem_unsigned_out <= mem_unsigned_in;
        wb_sel_out <= wb_sel_in;
        counter_val_out <= counter_val_in;
    end
end

endmodule
