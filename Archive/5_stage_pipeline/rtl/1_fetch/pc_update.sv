/* Module to calculate the next program counter (PC) value by incrementing the current PC by 4.
TODO: Extend module to handle branch and jump instructions for more complex PC updates. */

module pc_update(
    input  logic [31:0] current_address,
    input logic stall,
    input logic pc_sel,
    input logic [31:0] pc_target,

    output logic [31:0] next_address
);

assign next_address = pc_sel ? pc_target : (stall ? current_address : current_address + 32'd4);

endmodule