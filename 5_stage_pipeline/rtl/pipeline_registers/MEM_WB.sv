/* MEM/WB pipeline register for the 5-stage RISC-V pipeline.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module MEM_WB (
    input logic clk,
    input logic reset,
    
    output logic [31:0] read_data_in,
    output logic [31:0] alu_result_output_in,

    output logic [31:0] read_data_out,
    output logic [31:0] alu_result_output_out
);

logic [31:0] read_data;
logic [31:0] alu_result_output;

always_ff @(posedge clk) begin
    if (reset) begin
        read_data <= 32'b0;
        alu_result_output <= 32'b0;
    end
    else begin
        read_data <= read_data_in;
        alu_result_output <= alu_result_output_in;
    end    
end

endmodule