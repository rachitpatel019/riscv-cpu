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

// Internal registers for BRAM inference
logic [31:0] instr_reg;
logic [31:0] pc_reg;
logic        flush_reg;

initial begin
    $readmemh("program.hex", instruction_memory);
end

// Synchronous Read Block - MUST be simple for BRAM inference
always_ff @(posedge clk) begin
    if (!stall) begin
        instr_reg <= instruction_memory[pc[31:2]];
        pc_reg    <= pc;
    end
end

// Track flush state in a register to align with the synchronous memory output
always_ff @(posedge clk) begin
    if (reset) begin
        flush_reg <= 1'b1;
    end
    else if (!stall) begin
        flush_reg <= flush;
    end
end

// Combinatorial Output Logic
// Moving the "NOP" insertion here allows the read logic above to map to M9K BRAM.
assign instruction = (flush_reg) ? 32'h00000013 : instr_reg;
assign pc_out      = (flush_reg) ? 32'b0        : pc_reg;

endmodule
