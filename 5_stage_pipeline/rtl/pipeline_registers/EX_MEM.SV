/* EX/MEM pipeline register for the 5-stage RISC-V pipeline.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module EX_MEM (
    input logic clk,
    input logic reset,
    
    input logic [31:0] alu_result_in, 
    input logic [31:0] pc_target_in, 
    input logic pc_sel_in,
    input logic [4:0] rd_in,
    input logic reg_write_in,
    
    output logic [31:0] alu_result_out,
    output logic [31:0] pc_target_out,
    output logic pc_sel_out,
    output logic [4:0] rd_out,
    output logic reg_write_out
);

always_ff @(posedge clk) begin
    if (reset) begin
        alu_result_out <= 32'b0;
        pc_target_out <= 32'b0;
        pc_sel_out <= 1'b0;
        rd_out <= 5'b0;
        reg_write_out <= 1'b0;
    end
    else begin
        alu_result_out <= alu_result_in;
        pc_target_out <= pc_target_in;
        pc_sel_out <= pc_sel_in;
        rd_out <= rd_in;
        reg_write_out <= reg_write_in;
    end    
end

endmodule