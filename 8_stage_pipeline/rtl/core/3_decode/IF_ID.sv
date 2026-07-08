/*
Pipeline register between Fetch and Decode stages.
Holds instruction and PC, and handles stalling and flushing.
*/

module IF_ID (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,

    input logic [31:0] pc_in,
    input logic [31:0] pc_plus_4_in,
    input logic [31:0] instruction_in,

    output logic [31:0] pc_out,
    output logic [31:0] pc_plus_4_out,
    output logic [31:0] instruction_out
);

// Propagates Fetch stage outputs to Decode stage registers, supporting reset, flush, and stall.
always_ff @(posedge clk) begin
    if (reset || flush) begin
        pc_out <= 32'b0;
        pc_plus_4_out <= 32'b0;
        instruction_out <= 32'h00000013;
    end
    else begin
        if (stall) begin
            pc_out <= pc_out;
            pc_plus_4_out <= pc_plus_4_out;
            instruction_out <= instruction_out;
        end
        else begin
            pc_out <= pc_in;
            pc_plus_4_out <= pc_plus_4_in;
            instruction_out <= instruction_in;
        end
    end
end

endmodule
