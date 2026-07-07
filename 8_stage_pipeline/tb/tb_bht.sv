`timescale 1ns / 1ps

module tb_bht;
int tests_total;
int tests_passed;
int tests_failed;

localparam CLK_PERIOD = 10;

logic clk;
logic reset;
logic [9:0] read_index;
logic read_enable;
logic [1:0] read_counter_out;
logic [9:0] write_index;
logic write_enable;
logic [1:0] write_counter_in;

bht dut (.*);

always #(CLK_PERIOD / 2) clk = ~clk;

task automatic report_info(string id, string msg);
    $display("[UVM_INFO]  %s @ %0t: %s", id, $time, msg);
endtask

task automatic report_error(string id, string msg);
    $display("[UVM_ERROR] %s @ %0t: %s", id, $time, msg);
    tests_failed++;
    tests_total++;
endtask

task automatic report_fatal(string id, string msg);
    $display("[UVM_FATAL] %s @ %0t: %s", id, $time, msg);
    $finish;
endtask

task automatic reset_dut();
    reset = 1;
    read_index = 0;
    read_enable = 0;
    write_index = 0;
    write_enable = 0;
    write_counter_in = 0;
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    @(posedge clk);
endtask

task automatic drive_read(
    input logic [9:0] i_read_idx,
    input logic i_read_en
);
    read_index = i_read_idx;
    read_enable = i_read_en;
endtask

task automatic drive_write(
    input logic [9:0] i_write_idx,
    input logic i_write_en,
    input logic [1:0] i_write_data
);
    write_index = i_write_idx;
    write_enable = i_write_en;
    write_counter_in = i_write_data;
endtask

task automatic check_read(input logic [1:0] expected_counter);
    if (read_counter_out === expected_counter) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Expected Counter=%b, Actual=%b, Read Index=%d", 
            expected_counter, read_counter_out, read_index));
    end
endtask

initial begin
    #100_000;
    report_fatal("WATCHDOG", "Simulation timed out.");
end

initial begin
    clk = 0;
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    report_info("TB", "Starting BHT unit tests.");

    reset_dut();

    // Test Case 1: Verify all entries are initialized to 2'b01 (Weakly Not-Taken)
    // Query index 0 and 5
    @(negedge clk);
    drive_read(10'd0, 1'b1);
    @(posedge clk);
    #1;
    // BRAM read has 1-cycle latency. Prediction should be ready on next cycle
    drive_read(10'd5, 1'b1); // Pipeline next address
    check_read(2'b01);

    @(posedge clk);
    #1;
    drive_read(10'd0, 1'b0); // Disable read
    check_read(2'b01);

    // Test Case 2: Write update to index 10 (Strongly Taken 2'b11) and verify update
    @(negedge clk);
    drive_write(10'd10, 1'b1, 2'b11);
    @(posedge clk);
    #1;
    // Disable write, drive read for index 10
    drive_write(10'd0, 1'b0, 2'b00);
    drive_read(10'd10, 1'b1);
    
    @(posedge clk);
    #1;
    // Read data for index 10 is ready
    check_read(2'b11);

    // Test Case 3: Verify read_enable gating
    @(negedge clk);
    drive_read(10'd20, 1'b0); // Disable read, address is 20
    @(posedge clk);
    #1;
    // Output should still hold the previous read (which was index 10 -> 2'b11)
    check_read(2'b11);

    // Test Case 4: Simultaneous read/write on different addresses
    @(negedge clk);
    drive_write(10'd30, 1'b1, 2'b10);
    drive_read(10'd10, 1'b1);
    @(posedge clk);
    #1;
    // Read data for index 10 is ready (should be 2'b11)
    check_read(2'b11);
    
    drive_write(10'd0, 1'b0, 2'b00);
    drive_read(10'd30, 1'b1);
    @(posedge clk);
    #1;
    // Read data for index 30 is ready (should be 2'b10)
    check_read(2'b10);

    report_info("TB", "All BHT tests complete.");
    $display("--- BHT Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
