/* Module to represent the instruction memory of the CPU.
Stores all instructions and outputs the current instruction. */

module instr_mem(
    input  logic [31:0] pc,

    output logic [31:0] instruction
);

localparam MEM_DEPTH = 256;
logic [31:0] instruction_memory [0:MEM_DEPTH-1];

// Initialize memory to zero & load program
initial begin
    integer i;
    for (i = 0; i < MEM_DEPTH; i++)
        instruction_memory[i] = 32'b0;

    $readmemh("program.hex", instruction_memory);
end

/* Because every instruction starts at an address that is a multiple of 4,
the last two bits of the Program Counter (PC) will always be 00. */
assign instruction = instruction_memory[pc[31:2]];

endmodule