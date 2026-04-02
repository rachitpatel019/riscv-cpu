module data_mem (
    input  logic clk,
    input  logic mem_read,
    input  logic mem_write,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

logic [31:0] memory [0:255]; // 256 words

// Write
always_ff @(posedge clk) begin
    if (mem_write)
        memory[address[31:2]] <= write_data;
end

// Read
always_comb begin
    if (mem_read)
        read_data = memory[address[31:2]];
    else
        read_data = 32'b0;
end

endmodule