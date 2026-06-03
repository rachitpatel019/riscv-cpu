/*
Register file module defining 32 32-bit registers with two read ports and one write port.
Register 0 is hardwired to 0.
*/

module regfile(
    input logic clk,
    input logic stall,

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

/* To infer BRAM for a 2-Read, 1-Write memory, we duplicate the storage.
   Each 'registers' array will be mapped to a separate M9K block. */
(* ramstyle = "M9K" *) logic [31:0] registersa [31:0] = '{default: 32'b0};
(* ramstyle = "M9K" *) logic [31:0] registersb [31:0] = '{default: 32'b0};

// Synchronous Write Logic
logic [31:0] write_data_actual;
assign write_data_actual = (write_address == 5'b0) ? 32'b0 : write_data;

always_ff @(posedge clk) begin
    if (write_enable && !stall) begin
        registersa[write_address] <= write_data_actual;
        registersb[write_address] <= write_data_actual;
    end
end

// Synchronous Read Logic
always_ff @(posedge clk) begin
    if (!stall) begin
        read_data1 <= registersa[read_address1];
        read_data2 <= registersb[read_address2];
    end
end

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