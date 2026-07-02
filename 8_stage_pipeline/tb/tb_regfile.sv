`timescale 1ns / 1ps

module tb_regfile;
int tests_total;
int tests_passed;
int tests_failed;

localparam CLK_PERIOD = 10;

logic clk;
logic [4:0] read_address1;
logic [4:0] read_address2;
logic [4:0] write_address;
logic [31:0] write_data;
logic write_enable;

logic [31:0] read_data1;
logic [31:0] read_data2;

regfile dut (.*);

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

task automatic drive_write(input logic [4:0] addr, input logic [31:0] data, input logic en);
    @(negedge clk);
    write_address = addr;
    write_data = data;
    write_enable = en;
endtask

task automatic drive_read(input logic [4:0] addr1, input logic [4:0] addr2);
    @(negedge clk);
    read_address1 = addr1;
    read_address2 = addr2;
endtask

task automatic check_read(input logic [31:0] exp1, input logic [31:0] exp2);
    @(posedge clk);
    @(posedge clk);
    #1;
    if (read_data1 === exp1 && read_data2 === exp2) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Read1: Exp=%h, Act=%h, Read2: Exp=%h, Act=%h", 
            exp1, read_data1, exp2, read_data2));
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
    write_enable = 0;
    report_info("TB", "Starting regfile tests.");

    drive_write(5'd1, 32'hAAAA_BBBB, 1);
    drive_write(5'd2, 32'hCCCC_DDDD, 1);
    drive_read(5'd1, 5'd2);
    check_read(32'hAAAA_BBBB, 32'hCCCC_DDDD);

    drive_write(5'd0, 32'hFFFF_FFFF, 1);
    drive_read(5'd0, 5'd1);
    check_read(32'h0, 32'hAAAA_BBBB);

    drive_write(5'd3, 32'h1234_5678, 1);
    drive_read(5'd3, 5'd1);
    check_read(32'h1234_5678, 32'hAAAA_BBBB);

    @(negedge clk);
    write_address = 5'd5;
    write_data = 32'hFEED_FACE;
    write_enable = 1;
    read_address1 = 5'd5;
    read_address2 = 5'd1;
    check_read(32'hFEED_FACE, 32'hAAAA_BBBB);

    report_info("TB", "All tests complete.");
    $display("--- regfile Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
