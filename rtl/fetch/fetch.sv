module fetch(
    input logic clk,
    input logic reset,
    output logic [31:0] pc,
    output logic [31:0] instruction
);

logic [31:0] next_address;

instr_mem imem(
    .pc(pc),
    .instruction(instruction)
);

pc_adder pc_add(
    .current_address(pc),
    .next_address(next_address)
);

pc pc_reg(
    .clk(clk),
    .reset(reset),
    .next_address(next_address),
    .current_address(pc)
);

endmodule