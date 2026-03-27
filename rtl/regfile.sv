module regfile(
    input logic clk,
    // Read
    input logic [4:0] read_address1, // 5 bits to represent registers 0-31
    input logic [4:0] read_address2, // 5 bits to represent registers 0-31
    output logic [31:0] read_data1, // 32 bit register size
    output logic [31:0] read_data2, // 32 bit register size

    // Write
    input logic [4:0] write_address, // 5 bits to represent registers 0-31
    input logic [31:0] write_data, // 32 bit register size
    input logic write_enable // update registers only when needed
);

logic [31:0] registers [31:0] = '{default: '0}; // creates 32 32-bit registers 

// Read logic
always_comb begin // change output immediately on input change
    // Read port 1
    if (write_enable && (write_address == read_address1) && (write_address != 0))
        read_data1 = write_data;
    else
        read_data1 = registers[read_address1];

    // Read port 2
    if (write_enable && (write_address == read_address2) && (write_address != 0))
        read_data2 = write_data;
    else
        read_data2 = registers[read_address2];
end

// Write logic
always_ff @(posedge clk) begin // update the registers at the end of the rising clock edge
    if (write_enable && (write_address != 0)) begin // register 0 is not mutable
        registers[write_address] <= write_data;
    end
end

endmodule