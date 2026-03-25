module instr_mem(
    input  logic [31:0] pc,
    output logic [31:0] instruction
);

localparam MEM_DEPTH = 256; // stores up to 256 instructions
logic [31:0] memory [0:MEM_DEPTH-1] = '{default: '0};

initial begin
    memory[0] = 32'h00500093; // addi x1, x0, 5
    memory[1] = 32'h00108133; // add x2, x1, x1
    memory[2] = 32'h00202023; // sw x2, 0(x0)
end

localparam PC_WIDTH = 8; // 8 bits needed to represent 256 addresses
assign instruction = memory[pc[PC_WIDTH+1:2]];

endmodule