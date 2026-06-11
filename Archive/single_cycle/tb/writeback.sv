`timescale 1ns/1ps

module writeback_tb;

// DUT Signals
logic [31:0] alu_result;
logic [31:0] read_data;
logic mem_to_reg;

logic [31:0] write_data;

// Instantiate DUT
writeback dut (.*);

// Test tracking
int test_count = 0;
int fail_count = 0;

task run_test(
    input logic [31:0] alu_in,
    input logic [31:0] mem_in,
    input logic sel,
    input logic [31:0] expected
);
begin
    test_count++;

    alu_result = alu_in;
    read_data  = mem_in;
    mem_to_reg = sel;

    #1; // allow combinational logic to settle

    if (write_data !== expected) begin
        $display("Test %0d FAILED", test_count);
        $display("  alu_result=%0d read_data=%0d mem_to_reg=%0b", alu_in, mem_in, sel);
        $display("  Expected=%0d, Got=%0d\n", expected, write_data);
        fail_count++;
    end else begin
        $display("Test %0d PASSED", test_count);
    end
end
endtask

// Test Cases
initial begin
    // ALU path (mem_to_reg = 0)
    run_test(10, 100, 0, 10);
    run_test(0,  999, 0, 0);
    run_test(32'hFFFFFFFF, 123, 0, 32'hFFFFFFFF);

    // Memory path (mem_to_reg = 1)
    run_test(10, 100, 1, 100);
    run_test(555, 42, 1, 42);
    run_test(32'hABCDEF01, 32'h12345678, 1, 32'h12345678);

    // Edge Cases
    run_test(0, 0, 0, 0);
    run_test(0, 0, 1, 0);

    // Mixed values
    run_test(32'h7FFFFFFF, 32'h80000000, 0, 32'h7FFFFFFF);
    run_test(32'h7FFFFFFF, 32'h80000000, 1, 32'h80000000);

    // Testing report
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    $finish;
end

endmodule