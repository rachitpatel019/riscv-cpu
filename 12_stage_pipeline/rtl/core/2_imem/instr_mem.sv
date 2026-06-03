/* Stage 2
Module to represent the instruction memory of the CPU.
Stores all instructions and outputs the current instruction.
*/

module instr_mem(
    input logic clk,
    input logic reset,

    input logic stall,
    input logic flush,

    input logic [31:0] pc,
    output logic [31:0] pc_out,
    output logic [31:0] instruction
);

localparam MEM_DEPTH = 256;
(* ramstyle = "M9K" *) logic [31:0] instruction_memory [0:MEM_DEPTH-1];

initial begin
    $readmemh("program.hex", instruction_memory);
end

always_ff @(posedge clk) begin
    (!stall) begin
        instruction <= instruction_memory[pc[31:2]];
        pc_out <= pc;
    end
end

endmodule