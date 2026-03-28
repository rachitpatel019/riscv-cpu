module pc_adder(
    input  logic [31:0] current_address,
    output logic [31:0] next_address
);

assign next_address = current_address + 32'd4; // increment pc address by 4

endmodule