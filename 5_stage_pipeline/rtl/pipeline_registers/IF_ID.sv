/* IF/ID pipeline register for the 5-stage RISC-V pipeline.
TODO: Add register for the next program counter value to support branch and jump instructions.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module IF_ID (
    input logic clk,
    input logic reset,
    
    input logic [31:0] pc_in,
    input logic [31:0] instruction_in,
    
    output logic [31:0] pc_out,
    output logic [31:0] instruction_out
);

logic [31:0] pc;
logic [31:0] instruction;

always_ff @(posedge clk) begin
    if (reset) begin
        pc <= 32'b0;
        instruction <= 32'b0;
    end
    else begin
        pc <= pc_in;
        instruction <= instruction_in;
    end    
end

endmodule