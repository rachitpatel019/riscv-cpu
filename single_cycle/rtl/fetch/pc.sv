module pc(
    input logic clk,
    input logic reset,
    input logic [31:0] next_address,
    output logic [31:0] current_address
);

always_ff @(posedge clk) begin
    if (reset)
        current_address <= 32'b0;
    else
        current_address <= next_address;
end
    
endmodule