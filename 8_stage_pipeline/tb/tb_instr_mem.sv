`timescale 1ns / 1ps

module tb_instr_mem;
int tests_total;
int tests_passed;
int tests_failed;

localparam CLK_PERIOD = 10;

logic clk;
logic reset;
logic stall;
logic flush;
logic [31:0] pc;
logic [31:0] pc_out;
logic [31:0] instruction;

instr_mem dut (.*);

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
    @(negedge clk);
    @(negedge clk);
    reset = 0;
    @(negedge clk);
endtask

task automatic drive(
    input logic i_stall,
    input logic i_flush,
    input logic [31:0] i_pc
);
    @(negedge clk);
    stall = i_stall;
    flush = i_flush;
    pc = i_pc;
endtask

task automatic check(
    input logic [31:0] expected_pc,
    input logic [31:0] expected_instr
);
    @(posedge clk);
    #1;
    if (pc_out === expected_pc && instruction === expected_instr) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Expected PC=%h, Actual PC=%h, Expected Instr=%h, Actual Instr=%h", 
            expected_pc, pc_out, expected_instr, instruction));
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
    stall = 0;
    flush = 0;
    pc = 0;
    report_info("TB", "Starting instr_mem tests.");

    reset_dut();

    drive(0, 0, 32'h0); check(32'h0, 32'h00100093);
    drive(0, 0, 32'h4); check(32'h4, 32'h00000013);
    drive(0, 0, 32'h8); check(32'h8, 32'h00000013);

    drive(1, 0, 32'hC); check(32'h8, 32'h00000013);
    drive(1, 0, 32'h10); check(32'h8, 32'h00000013);

    drive(0, 0, 32'hC); check(32'hC, 32'h00000013);

    drive(0, 1, 32'h10); check(32'h0, 32'h00000013);

    report_info("TB", "All tests complete.");
    $display("--- instr_mem Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule