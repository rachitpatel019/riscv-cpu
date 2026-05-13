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

logic [31:0] alu_result;
logic [31:0] pc_target;
logic pc_sel;
logic [4:0] rd;
logic reg_write;

always_ff @(posedge clk) begin
    if (reset) begin
        alu_result <= 32'b0;
        pc_target <= 32'b0;
        pc_sel <= 1'b0;
        rd <= 5'b0;
        reg_write <= 1'b0;
    end
    else begin
        alu_result <= alu_result_in;
        pc_target <= pc_target_in;
        pc_sel <= pc_sel_in;
        rd <= rd_in;
        reg_write <= reg_write_in;
    end    
end

endmodule