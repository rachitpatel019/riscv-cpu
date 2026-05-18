/* MEM/WB pipeline register for the 5-stage RISC-V pipeline.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module MEM_WB (
    input logic clk,
    input logic reset,
    
    input logic [31:0] read_data_in,
    input logic [31:0] alu_result_output_in,
    input logic [4:0] rd_in,
    input logic reg_write_in,
    input logic [1:0] wb_sel_in,
    input logic [31:0] pc_in,

    output logic [31:0] read_data_out,
    output logic [31:0] alu_result_output_out,
    output logic [4:0] rd_out,
    output logic reg_write_out,
    output logic [1:0] wb_sel_out,
    output logic [31:0] pc_out
);

always_ff @(posedge clk) begin
    if (reset) begin
        read_data_out <= 32'b0;
        alu_result_output_out <= 32'b0;
        rd_out <= 5'b0;
        reg_write_out <= 1'b0;
        wb_sel_out <= 2'b0;
        pc_out <= 32'b0;
    end
    else begin
        read_data_out <= read_data_in;
        alu_result_output_out <= alu_result_output_in;
        rd_out <= rd_in;
        reg_write_out <= reg_write_in;
        wb_sel_out <= wb_sel_in;
        pc_out <= pc_in;
    end    
end

endmodule