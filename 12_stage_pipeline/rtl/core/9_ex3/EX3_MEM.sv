module EX3_MEM(
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,

    input logic reg_write_in,
    input logic [4:0] rs1_in,
    input logic [4:0] rs2_in,
    input logic [4:0] rd_in,

    input logic [31:0] rs2_data_in,
    input logic [31:0] alu_result_in,

    input logic pc_sel_in,
    input logic [31:0] pc_target_in,

    output logic reg_write_out,
    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,
    output logic [4:0] rd_out,

    output logic [31:0] rs2_data_out,
    output logic [31:0] alu_result_out,

    output logic pc_sel_out,
    output logic [31:0] pc_target_out,
);

always_ff @(posedge clk) begin
    if (reset || flush) begin
        reg_write_out <= 0;
        rs1_out <= 5'b0;
        rs2_out <= 5'b0;
        rd_out <= 5'b0;
        rs2_data_out <= 32'b0;
        alu_result_out <= 32'b0;
        pc_sel_out <= 0;
        pc_target_out <= 32'b0;
    end
    else if (stall) begin
        reg_write_out <= reg_write_out;
        rs1_out <= rs1_out;
        rs2_out <= rs2_out;
        rd_out <= rd_out;
        rs2_data_out <= rs2_data_out;
        alu_result_out <= alu_result_out;
        pc_sel_out <= pc_sel_out;
        pc_target_out <= pc_target_out;
    end
    else begin
        reg_write_out <= reg_write_in;
        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        rd_out <= rd_in;
        rs2_data_out <= rs2_data_in;
        alu_result_out <= alu_result_in;
        pc_sel_out < pc_sel_in;
        pc_target_out <= pc_target_in;
    end
end

endmodule