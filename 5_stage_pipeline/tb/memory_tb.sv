`timescale 1ns/1ps

module memory_tb;

// DUT Signals
logic clk;
logic [31:0] alu_result;
logic [31:0] rs2_data;
logic mem_read;
logic mem_write;
logic [1:0] mem_size;
logic mem_unsigned;

logic [31:0] read_data;
logic [31:0] alu_result_out;

// Instantiate DUT with explicit port connections
memory dut (
    .clk(clk),
    .alu_result(alu_result),
    .rs2_data(rs2_data),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .read_data(read_data),
    .alu_result_output(alu_result_out)
);

// Clock generation
initial clk = 0;
always #5 clk = ~clk;

// Test tracking
int test_count = 0;
int fail_count = 0;

task store_test(
    input logic [31:0] address,
    input logic [31:0] data,
    input logic [1:0] size
);
begin
    test_count++;

    alu_result    = address;
    rs2_data      = data;
    mem_size      = size;
    mem_unsigned  = 0;
    mem_write     = 1;
    mem_read      = 0;

    @(posedge clk);

    mem_write = 0;

    $display("Store Test %0d: Wrote 0x%08h to address %0d (size=%0b)", test_count, data, address, size);
end
endtask

task load_test(
    input logic [31:0] address,
    input logic [31:0] expected,
    input logic [1:0] size,
    input logic unsigned_flag
);
begin
    test_count++;

    alu_result    = address;
    mem_size      = size;
    mem_unsigned  = unsigned_flag;
    mem_read      = 1;
    mem_write     = 0;

    #1; // allow combinational read

    if (read_data !== expected) begin
        $display("Load Test %0d FAILED", test_count);
        $display("  Address=%0d Size=%0b Unsigned=%0b Expected=0x%08h Got=0x%08h\n", address, size, unsigned_flag, expected, read_data);
        fail_count++;
    end else begin
        $display("Load Test %0d PASSED", test_count);
    end

    mem_read = 0;
end
endtask

task idle_test(
    input logic [31:0] address,
    input logic [1:0] size,
    input logic unsigned_flag
);
begin
    test_count++;

    alu_result    = address;
    mem_size      = size;
    mem_unsigned  = unsigned_flag;
    mem_read      = 0;
    mem_write     = 0;

    #1;

    if (read_data !== 0) begin
        $display("Idle Test %0d FAILED (read_data not zero)", test_count);
        fail_count++;
    end else begin
        $display("Idle Test %0d PASSED", test_count);
    end
end
endtask

// Test Cases
initial begin
    // Default control values
    mem_size     = 2'b10;
    mem_unsigned = 0;
    mem_read     = 0;
    mem_write    = 0;

    // Store + Load Basic (word)
    store_test(0, 32'h0000_002A, 2'b10);
    load_test(0, 32'h0000_002A, 2'b10, 0);

    // Multiple Addresses (word)
    store_test(4, 32'h0000_0064, 2'b10);
    store_test(8, 32'h0000_00C8, 2'b10);
    load_test(4, 32'h0000_0064, 2'b10, 0);
    load_test(8, 32'h0000_00C8, 2'b10, 0);

    // Overwrite Same Address (word)
    store_test(0, 32'h0000_0063, 2'b10);
    load_test(0, 32'h0000_0063, 2'b10, 0);

    // Edge Case: Zero (word)
    store_test(12, 32'h0000_0000, 2'b10);
    load_test(12, 32'h0000_0000, 2'b10, 0);

    // Edge Case: Negative Number (word)
    store_test(16, 32'hFFFF_FFFB, 2'b10);
    load_test(16, 32'hFFFF_FFFB, 2'b10, 0);

    // Halfword signed/unsigned
    store_test(20, 32'h0000_FF80, 2'b01);
    load_test(20, 32'hFFFF_FF80, 2'b01, 0);
    load_test(20, 32'h0000_FF80, 2'b01, 1);

    // Byte signed/unsigned
    store_test(24, 32'h0000_0080, 2'b00);
    load_test(24, 32'hFFFF_FF80, 2'b00, 0);
    load_test(24, 32'h0000_0080, 2'b00, 1);

    // Idle Behavior
    idle_test(0, 2'b10, 0);

    // Testing report
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    $finish;
end

endmodule