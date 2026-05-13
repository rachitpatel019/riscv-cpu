/* MEM/WB pipeline register for the 5-stage RISC-V pipeline.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module MEM_WB (
    input logic clk,
    input logic reset,
    
    output logic [31:0] read_data_in,
    output logic [31:0] alu_result_output_in,
    input logic [4:0] rd_in,
    input logic reg_write_in,

    output logic [31:0] read_data_out,
    output logic [31:0] alu_result_output_out,
    output logic [4:0] rd_out,
    output logic reg_write_out
);

logic [31:0] read_data;
logic [31:0] alu_result_output;
logic [4:0] rd;
logic reg_write;

always_ff @(posedge clk) begin
    if (reset) begin
        read_data <= 32'b0;
        alu_result_output <= 32'b0;
        rd <= 5'b0;
        reg_write <= 1'b0;
    end
    else begin
        read_data <= read_data_in;
        alu_result_output <= alu_result_output_in;
        rd <= rd_in;
        reg_write <= reg_write_in;
    end    
end

endmodule