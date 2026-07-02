/*
Register file defining 32 32-bit registers.
Supports two read ports and one write port, with register 0 tied to zero.
*/

module regfile (
    input logic clk,

    input logic [4:0] read_address1,
    input logic [4:0] read_address2,

    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    input logic [4:0] write_address,
    input logic [31:0] write_data,
    input logic write_enable
);

// Register storage array representation to infer distributed memory blocks.
logic [31:0] registers [31:0] = '{default: 32'b0};

logic [31:0] write_data_actual;

// Determines actual write data, enforcing that register 0 remains hardwired to zero.
assign write_data_actual = (write_address == 5'b0) ? 32'b0 : write_data;

// Writes write_data_actual to the register file on positive clock edges.
always_ff @(posedge clk) begin
    if (write_enable && (write_address != 5'b0)) begin
        registers[write_address] <= write_data_actual;
    end
end

// Reads operand data asynchronously, with write-forwarding if reading the register being written.
always_ff @(posedge clk) begin
    if (write_enable && (write_address == read_address1) && (write_address != 5'b0)) begin
        read_data1 <= write_data_actual;
    end
    else begin
        read_data1 <= registers[read_address1];
    end

    if (write_enable && (write_address == read_address2) && (write_address != 5'b0)) begin
        read_data2 <= write_data_actual;
    end
    else begin
        read_data2 <= registers[read_address2];
    end
end

endmodule