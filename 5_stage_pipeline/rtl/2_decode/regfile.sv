/* Register file module defining 32 32-bit registers with two read ports and one write port.
Register 0 is hardwired to 0. */

module regfile(
    input logic clk,
    input logic en,

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
(* ramstyle = "M9K" *) logic [31:0] registers1 [31:0];
(* ramstyle = "M9K" *) logic [31:0] registers2 [31:0];

// Initialize registers to zero
initial begin
    for (int i = 0; i < 32; i++) begin
        registers1[i] = 32'b0;
        registers2[i] = 32'b0;
    end
end

// Synchronous Write Logic
always_ff @(posedge clk) begin
    if (write_enable) begin
        registers1[write_address] <= write_data;
        registers2[write_address] <= write_data;
    end
end

// Pure Synchronous Read Logic + Signal Registration
// This simple pattern is guaranteed to infer BRAM in Quartus.
logic [31:0] ram_out1, ram_out2;
logic [4:0]  raddr1_reg, raddr2_reg;
logic [4:0]  waddr_reg;
logic [31:0] wdata_reg;
logic        we_reg;

always_ff @(posedge clk) begin
    if (en) begin
        ram_out1   <= registers1[read_address1];
        ram_out2   <= registers2[read_address2];
        raddr1_reg <= read_address1;
        raddr2_reg <= read_address2;
        waddr_reg  <= write_address;
        wdata_reg  <= write_data;
        we_reg     <= write_enable;
    end
end

// Combinational Bypass and x0 Logic
// This logic operates on the registered outputs, ensuring it is mapped 
// into the next stage (Execute) path, matching the 5-stage pipeline timing.
always_comb begin
    // Port 1
    if (raddr1_reg == 5'b0)
        read_data1 = 32'b0;
    else if (we_reg && (waddr_reg == raddr1_reg))
        read_data1 = wdata_reg;
    else
        read_data1 = ram_out1;

    // Port 2
    if (raddr2_reg == 5'b0)
        read_data2 = 32'b0;
    else if (we_reg && (waddr_reg == raddr2_reg))
        read_data2 = wdata_reg;
    else
        read_data2 = ram_out2;
end

endmodule