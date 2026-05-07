/* Fetch stage of the 5-stage RISC-V pipeline.
Responsible for fetching instructions from memory and updating the program counter (PC).
TODO: Implement control flow handling for branch and jump instructions.
TODO: Output the next program counter value to support branch and jump instructions. */

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

pc_update pc_upd(
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