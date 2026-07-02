`timescale 1ns / 1ps

module tb_pc_update;
int tests_total;
int tests_passed;
int tests_failed;

localparam CLK_PERIOD = 10;

logic clk;
logic reset;
logic stall;
logic pc_sel;
logic [31:0] pc_target;

logic [31:0] pc;

pc_update dut (.*);

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
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    @(posedge clk);
endtask

task automatic drive(
    input logic i_reset,
    input logic i_stall,
    input logic i_pc_sel,
    input logic [31:0] i_pc_target
);
    @(negedge clk);
    reset = i_reset;
    stall = i_stall;
    pc_sel = i_pc_sel;
    pc_target = i_pc_target;
endtask

task automatic check(input logic [31:0] expected_pc);
    @(posedge clk);
    #1;
    if (pc === expected_pc) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Expected=%h, Actual=%h, Inputs: reset=%b, stall=%b, pc_sel=%b, pc_target=%h", 
            expected_pc, pc, reset, stall, pc_sel, pc_target));
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
    report_info("TB", "Starting pc_update tests.");

    reset_dut();

    drive(1, 0, 1, 32'h100); check(32'h0);
    
    drive(0, 0, 0, 0); check(32'h4);
    drive(0, 0, 0, 0); check(32'h8);

    drive(0, 1, 0, 0); check(32'h8);
    drive(0, 1, 1, 32'h300); check(32'h300);

    drive(0, 0, 1, 32'h400); check(32'h400);
    drive(0, 0, 0, 0); check(32'h404);

    drive(0, 0, 1, 32'h00000002); check(32'h00000002);

    report_info("TB", "All tests complete.");
    $display("--- pc_update Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
