/* Register file module defining 32 32-bit registers with two read ports and one write port.
Register 0 is hardwired to 0. */

module regfile(
    input logic clk,

    // Read
    input logic [4:0] read_address1,
    input logic [4:0] read_address2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    // Write
    input logic [4:0] write_address,
    input logic [31:0] write_data,
    input logic write_enable
);

logic [31:0] registers [31:0] = '{default: '0};

// Read logic
always_comb begin
    // Read port 1
    // Implementing write forwarding for the case when the instruction is writing to a register that is being read in the same cycle. This is a common optimization in register files to avoid stalls.
    if (write_enable && (write_address == read_address1) && (write_address != 0))
        read_data1 = write_data;
    else
        read_data1 = registers[read_address1];

    // Read port 2
    // Implementing write forwarding for the case when the instruction is writing to a register that is being read in the same cycle. This is a common optimization in register files to avoid stalls.
    if (write_enable && (write_address == read_address2) && (write_address != 0))
        read_data2 = write_data;
    else
        read_data2 = registers[read_address2];
end

// Write logic
always_ff @(posedge clk) begin
    if (write_enable && (write_address != 0)) begin // register 0 is immutable
        registers[write_address] <= write_data;
    end
end

endmodule