`timescale 1ns/1ps

module memory_tb;

// DUT Signals
logic clk;
logic [31:0] alu_result;
logic [31:0] rs2_data;
logic mem_read;
logic mem_write;

logic [31:0] read_data;
logic [31:0] alu_result_out;

// Instantiate DUT
memory dut (.*);

// Clock generation
initial clk = 0;
always #5 clk = ~clk;

// Test tracking
int test_count = 0;
int fail_count = 0;

task store_test(
    input logic [31:0] address,
    input logic [31:0] data
);
begin
    test_count++;

    alu_result = address;
    rs2_data   = data;
    mem_write  = 1;
    mem_read   = 0;

    @(posedge clk);

    mem_write = 0;

    $display("Store Test %0d: Wrote %0d to address %0d", test_count, data, address);
end
endtask

task load_test(
    input logic [31:0] address,
    input logic [31:0] expected
);
begin
    test_count++;

    alu_result = address;
    mem_read   = 1;
    mem_write  = 0;

    #1; // allow combinational read

    if (read_data !== expected) begin
        $display("Load Test %0d FAILED", test_count);
        $display("  Address=%0d Expected=%0d Got=%0d\n", address, expected, read_data);
        fail_count++;
    end else begin
        $display("Load Test %0d PASSED", test_count);
    end

    mem_read = 0;
end
endtask

task idle_test(
    input logic [31:0] address
);
begin
    test_count++;

    alu_result = address;
    mem_read   = 0;
    mem_write  = 0;

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
    // Store + Load Basic
    store_test(0, 42);
    load_test(0, 42);

    // Multiple Addresses
    store_test(4, 100);
    store_test(8, 200);

    load_test(4, 100);
    load_test(8, 200);

    // Overwrite Same Address
    store_test(0, 99);
    load_test(0, 99);

    // Edge Case: Zero
    store_test(12, 0);
    load_test(12, 0);

    // Edge Case: Negative Number
    store_test(16, -5);
    load_test(16, -5);

    // Idle Behavior
    idle_test(0);

    // Testing report
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    $finish;
end

endmodule