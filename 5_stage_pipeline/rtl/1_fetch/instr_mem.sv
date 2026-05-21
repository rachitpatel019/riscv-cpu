/* Synchronous dual-port instruction memory for simulation and BRAM inference.
   The read data is available on the clock edge following the address. */

module instr_mem(
    input  logic clk,
    input  logic stall_a,
    input  logic stall_b,

    input  logic [31:0] pc_a,
    input  logic [31:0] pc_b,

    output logic [31:0] instruction_a,
    output logic [31:0] instruction_b
);

localparam MEM_DEPTH = 256;
logic [31:0] instruction_memory [0:MEM_DEPTH-1];

// Initialize memory
initial begin
    integer i;
    for (i = 0; i < MEM_DEPTH; i++)
        instruction_memory[i] = 32'b0;

    $readmemh("program.hex", instruction_memory);
end

// Dual-Port Synchronous Read
always_ff @(posedge clk) begin
    if (!stall_a) begin
        instruction_a <= instruction_memory[pc_a[31:2]];
    end
    if (!stall_b) begin
        instruction_b <= instruction_memory[pc_b[31:2]];
    end
end

endmodule
