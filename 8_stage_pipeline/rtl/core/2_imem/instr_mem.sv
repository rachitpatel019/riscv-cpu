/*
Instruction memory module modeling a synchronous ROM/RAM block.
Outputs the instruction at the PC address, inserting a NOP on flushes.
*/

module instr_mem (
    input logic clk,
    input logic reset,

    input logic stall,
    input logic flush,

    input logic [31:0] pc,

    output logic [31:0] pc_out,
    output logic [31:0] instruction
);

localparam MEM_DEPTH = 1024;

(* ramstyle = "M9K" *) logic [31:0] instruction_memory [0:MEM_DEPTH-1];

logic [31:0] instr_reg;
logic [31:0] pc_reg;

logic flush_reg;

// Initializes the instruction memory with program content from hex file.
initial begin
    $readmemh("program.hex", instruction_memory);
end

// Reads instruction memory synchronously and tracks the current PC.
always_ff @(posedge clk) begin
    if (!stall) begin
        instr_reg <= instruction_memory[pc[31:2]];
        pc_reg <= pc;
    end
end

// Pipeline register to track the flush state.
always_ff @(posedge clk) begin
    if (reset) begin
        flush_reg <= 1'b1;
    end
    else if (flush) begin
        flush_reg <= 1'b1;
    end
    else if (!stall) begin
        flush_reg <= 1'b0;
    end
end

// Output assignments selecting registered instruction/PC or bubble values.
assign instruction = (flush_reg) ? 32'h00000013 : instr_reg;
assign pc_out = (flush_reg) ? 32'b0 : pc_reg;

endmodule
