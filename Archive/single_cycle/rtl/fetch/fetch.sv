module fetch(
    input logic clk,
    input logic reset,
    input logic [31:0] pc_target, // Route from Execute
    input logic pc_sel,           // Route from Execute
    output logic [31:0] pc,
    output logic [31:0] instruction
);

logic [31:0] pc_plus_4;
logic [31:0] next_address;

// Multiplexer to choose between sequential execution and control flow jumps
assign next_address = pc_sel ? pc_target : pc_plus_4;

instr_mem imem(
    .pc(pc),
    .instruction(instruction)
);

// Dedicated +4 adder
pc_adder pc_add(
    .current_address(pc),
    .next_address(pc_plus_4) 
);

pc pc_reg(
    .clk(clk),
    .reset(reset),
    .next_address(next_address),
    .current_address(pc)
);

endmodule