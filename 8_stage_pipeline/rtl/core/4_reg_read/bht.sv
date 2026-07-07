/*
Synchronous Dual-Port Branch History Table (BHT).
Queries are clocked in on Port A; updates are written on Port B.
Configured for 1024 entries.
*/

module bht (
    input logic clk,
    input logic reset,

    // Port A: Read Port (Stage 3 -> Stage 4)
    input logic [9:0] read_index,
    input logic read_enable,
    output logic [1:0] read_counter_out,

    // Port B: Write Port (Stage 7 Update)
    input logic [9:0] write_index,
    input logic write_enable,
    input logic [1:0] write_counter_in
);

    // 1024 entries of 2-bit saturating counters initialized to 2'b01 (Weakly Not-Taken)
    (* ramstyle = "M9K" *) logic [1:0] bht_table [1023:0] = '{default: 2'b01};

    // Port A: Synchronous Read
    always_ff @(posedge clk) begin
        if (read_enable) begin
            read_counter_out <= bht_table[read_index];
        end
    end

    // Port B: Synchronous Write
    always_ff @(posedge clk) begin
        if (write_enable) begin
            bht_table[write_index] <= write_counter_in;
        end
    end

endmodule
