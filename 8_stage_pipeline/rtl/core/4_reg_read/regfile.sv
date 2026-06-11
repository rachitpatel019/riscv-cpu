/*
Register file module defining 32 32-bit registers with two read ports and one write port.
Register 0 is hardwired to 0.
*/

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

/* To infer distributed RAM for asynchronous read, we can use a simple array. */
logic [31:0] registers [31:0] = '{default: 32'b0};

// Synchronous Write Logic
logic [31:0] write_data_actual;
assign write_data_actual = (write_address == 5'b0) ? 32'b0 : write_data;

always_ff @(posedge clk) begin
    if (write_enable && (write_address != 5'b0)) begin
        registers[write_address] <= write_data_actual;
    end
end

// Asynchronous Read Logic with Internal Forwarding (Write-First)
assign read_data1 = (write_enable && (write_address == read_address1) && (write_address != 5'b0)) ? write_data_actual : registers[read_address1];
assign read_data2 = (write_enable && (write_address == read_address2) && (write_address != 5'b0)) ? write_data_actual : registers[read_address2];

// always_comb begin
//     // Port 1
//     if (write_enable && (write_address == read_address1) && (write_address != 5'b0))
//         read_data1 = write_data;
//     else
//         read_data1 = rs1;

//     // Port 2
//     if (write_enable && (write_address == read_address2) && (write_address != 5'b0))
//         read_data2 = write_data;
//     else
//         read_data2 = rs2;
// end

endmodule