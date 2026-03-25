module pc(
    input logic clk,
    input logic reset,
    input logic [31:0] next_address,
    output logic [31:0] current_address
);

logic [31:0] address = 32'b0; // stores the address of the current instruction

always_ff @(posedge clk) begin
    if (reset)
        address <= 32'b0;
    else
        address <= next_address; // updated the address of the current instruction every positive clock edge
    assign current_address = address;
end
    
endmodule