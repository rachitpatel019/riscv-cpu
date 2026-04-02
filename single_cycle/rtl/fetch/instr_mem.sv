module instr_mem(
    input  logic [31:0] pc,
    output logic [31:0] instruction
);

localparam MEM_DEPTH = 256;
logic [31:0] memory [0:MEM_DEPTH-1];

// Initialize memory to zero + load program
initial begin
    integer i;
    for (i = 0; i < MEM_DEPTH; i++)
        memory[i] = 32'b0;

    $readmemh("program.hex", memory);
end

assign instruction = memory[pc[31:2]];

endmodule