/* Module to represent the instruction memory of the CPU.
Stores all instructions and outputs the current instruction. */

module instr_mem(
    input  logic clk,
    input  logic en,
    input  logic [31:0] pc,

    output logic [31:0] instruction
);

localparam MEM_DEPTH = 256;
(* ramstyle = "M9K" *) logic [31:0] instruction_memory [0:MEM_DEPTH-1];

// Initialize memory using hex file
initial begin
    $readmemh("program.hex", instruction_memory);
end

/* Synchronous read for BRAM inference. */
always_ff @(posedge clk) begin
    if (en) begin
        instruction <= instruction_memory[pc[31:2]];
    end
end

/* Note: Even though this is a ROM, Quartus sometimes requires a 
   write port (even if unused) to correctly map to some BRAM modes.
   The ramstyle attribute should handle this. */

endmodule