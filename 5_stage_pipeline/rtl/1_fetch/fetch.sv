/* Fetch stage of the 5-stage RISC-V pipeline.
Responsible for fetching instructions from memory and updating the program counter (PC).
*/

module fetch(
    input logic clk,
    input logic reset,
    input logic stall,
    input logic pc_sel,
    input logic [31:0] pc_target,

    // Instruction Memory Interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_instruction,

    output logic [31:0] pc,
    output logic [31:0] instruction
);

logic [31:0] next_address;

// Interface assignment
assign imem_addr = pc;
assign instruction = imem_instruction;

pc_update pc_upd(
    .current_address(pc),
    .next_address(next_address),
    .stall(stall),
    .pc_sel(pc_sel),
    .pc_target(pc_target)
);

pc pc_reg(
    .clk(clk),
    .reset(reset),
    .next_address(next_address),
    .current_address(pc)
);

endmodule