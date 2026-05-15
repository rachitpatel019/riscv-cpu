/* IF/ID pipeline register for the 5-stage RISC-V pipeline.
TODO: Add register for the next program counter value to support branch and jump instructions.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module IF_ID (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,
    
    input logic [31:0] pc_in,
    input logic [31:0] instruction_in,
    
    output logic [31:0] pc_out,
    output logic [31:0] instruction_out
);

always_ff @(posedge clk) begin
    if (reset ||flush) begin
        pc_out <= 32'b0;
        instruction_out <= 32'h00000013; // NOP instruction (ADDI x0, x0, 0)
    end
    else begin
        if (stall) begin
            pc_out <= pc_out;
            instruction_out <= instruction_out;
        end
        else begin
            pc_out <= pc_in;
            instruction_out <= instruction_in;
        end
    end    
end

endmodule