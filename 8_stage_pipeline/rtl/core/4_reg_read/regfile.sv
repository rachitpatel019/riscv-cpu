/*
Register file defining 32 32-bit registers.
Uses replicated BRAM arrays to support two read ports and one write port synchronously.
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

// Replicated memory arrays configured as block RAM to allow simultaneous dual-port reads.
(* ramstyle = "M9K" *) logic [31:0] registers_a [31:0] = '{default: 32'b0};
(* ramstyle = "M9K" *) logic [31:0] registers_b [31:0] = '{default: 32'b0};

logic [31:0] write_data_actual;

// Enforces that register 0 remains hardwired to zero by filtering the write data.
assign write_data_actual = (write_address == 5'b0) ? 32'b0 : write_data;

// Synchronously updates both replicated arrays with the write data on the active clock edge.
always_ff @(posedge clk) begin
    if (write_enable && (write_address != 5'b0)) begin
        registers_a[write_address] <= write_data_actual;
        registers_b[write_address] <= write_data_actual;
    end
end

// Reads data from the first memory array, forwarding write data if a read-during-write collision occurs.
always_ff @(posedge clk) begin
    if (write_enable && (write_address == read_address1) && (write_address != 5'b0)) begin
        read_data1 <= write_data_actual;
    end
    else begin
        read_data1 <= registers_a[read_address1];
    end
end

// Reads data from the second memory array, forwarding write data if a read-during-write collision occurs.
always_ff @(posedge clk) begin
    if (write_enable && (write_address == read_address2) && (write_address != 5'b0)) begin
        read_data2 <= write_data_actual;
    end
    else begin
        read_data2 <= registers_b[read_address2];
    end
end

endmodule