`timescale 1ns / 1ps

module tb_branch_eval;
int tests_total;
int tests_passed;
int tests_failed;

logic [31:0] pc;
logic [31:0] imm;
logic [31:0] operand_a;
logic [31:0] operand_b;
logic [2:0] branch_type;

logic condition_met;
logic [31:0] branch_target;

branch_eval dut (.*);

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

task automatic drive(
    input logic [31:0] i_pc,
    input logic [31:0] i_imm,
    input logic [31:0] i_op_a,
    input logic [31:0] i_op_b,
    input logic [2:0]  i_br_type
);
    pc = i_pc;
    imm = i_imm;
    operand_a = i_op_a;
    operand_b = i_op_b;
    branch_type = i_br_type;
    #1;
endtask

task automatic check(
    input logic exp_cond,
    input logic [31:0] exp_target
);
    if (condition_met === exp_cond && branch_target === exp_target) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Type=%b, ExpCond=%b, ActCond=%b, ExpTarget=%h, ActTarget=%h", 
            branch_type, exp_cond, condition_met, exp_target, branch_target));
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
    report_info("TB", "Starting branch_eval tests.");

    drive(32'h100, 32'h8, 32'h5, 32'h5, 3'b000); check(1, 32'h108);
    drive(32'h100, 32'h8, 32'h5, 32'h6, 3'b000); check(0, 32'h108);

    drive(32'h100, 32'h8, 32'h5, 32'h6, 3'b001); check(1, 32'h108);
    drive(32'h100, 32'h8, 32'h5, 32'h5, 3'b001); check(0, 32'h108);

    drive(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b100); check(1, 32'h108);
    drive(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b100); check(0, 32'h108);

    drive(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b101); check(1, 32'h108);
    drive(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b101); check(0, 32'h108);

    drive(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b110); check(1, 32'h108);
    drive(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b110); check(0, 32'h108);

    drive(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b111); check(1, 32'h108);
    drive(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b111); check(0, 32'h108);

    drive(32'h100, 32'hFFFFFFF8, 32'h0, 32'h0, 3'b000); check(1, 32'hF8);

    report_info("TB", "All tests complete.");
    $display("--- branch_eval Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
