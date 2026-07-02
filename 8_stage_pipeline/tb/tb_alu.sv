`timescale 1ns / 1ps

module tb_alu;
int tests_total;
int tests_passed;
int tests_failed;

logic [31:0] A;
logic [31:0] B;
logic [3:0] control;

logic [31:0] result;

alu dut (.*);

import alu_package::*;

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

task automatic drive(input logic [31:0] i_a, input logic [31:0] i_b, input logic [3:0] i_ctrl);
    A = i_a;
    B = i_b;
    control = i_ctrl;
    #1;
endtask

task automatic check(input logic [31:0] exp_res);
    if (result === exp_res) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: A=%h, B=%h, Ctrl=%b, Exp=%h, Act=%h", 
            A, B, control, exp_res, result));
    end
endtask

initial begin
    #100_000;
    report_fatal("WATCHDOG", "Simulation timed out.");
end

initial begin
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    report_info("TB", "Starting alu tests.");

    drive(32'h1, 32'h2, ALU_ADD); check(32'h3);
    drive(32'h5, 32'h3, ALU_SUB); check(32'h2);
    drive(32'h7FFFFFFF, 32'h1, ALU_ADD); check(32'h80000000); 

    drive(32'hFFFF0000, 32'h0000FFFF, ALU_AND); check(32'h0);
    drive(32'hAAAA5555, 32'h5555AAAA, ALU_OR); check(32'hFFFFFFFF);

    drive(32'hFFFFFFFF, 32'h00000001, ALU_SLT); check(32'h1);  
    drive(32'hFFFFFFFF, 32'h00000001, ALU_SLTU); check(32'h0);  

    drive(32'h1, 32'h4, ALU_SLL); check(32'h10);
    drive(32'h80000000, 32'h1, ALU_SRA); check(32'hC0000000);
    drive(32'h80000000, 32'h1, ALU_SRL); check(32'h40000000);

    repeat(100) begin
        logic [31:0] ra;
        logic [31:0] rb;
        ra = $urandom;
        rb = $urandom;
        drive(ra, rb, ALU_ADD);
        check(ra + rb);
    end

    report_info("TB", "All tests complete.");
    $display("--- alu Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
