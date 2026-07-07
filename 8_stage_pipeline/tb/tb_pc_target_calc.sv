`timescale 1ns / 1ps

module tb_pc_target_calc;
int tests_total;
int tests_passed;
int tests_failed;

logic [31:0] pc;
logic [31:0] operand_a;
logic [31:0] operand_b;
logic branch;
logic jump;
logic [2:0] branch_type;
logic [31:0] imm;
logic [31:0] alu_result;
logic condition_met_in;
logic [31:0] branch_target_in;
logic predicted_taken_in;

logic pc_sel;
logic [31:0] pc_target;

pc_target_calc dut (.*);

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
    input logic [31:0] i_pc, input logic [31:0] i_op_a, input logic [31:0] i_op_b,
    input logic i_branch, input logic i_jump, input logic [2:0] i_br_type,
    input logic [31:0] i_imm, input logic [31:0] i_alu_res,
    input logic i_predicted_taken = 0
);
    pc = i_pc;
    operand_a = i_op_a;
    operand_b = i_op_b;
    branch = i_branch;
    jump = i_jump;
    branch_type = i_br_type;
    imm = i_imm;
    alu_result = i_alu_res;
    
    case (i_br_type)
        3'b000: condition_met_in = i_op_a == i_op_b;
        3'b001: condition_met_in = i_op_a != i_op_b;
        3'b100: condition_met_in = $signed(i_op_a) < $signed(i_op_b);
        3'b101: condition_met_in = $signed(i_op_a) >= $signed(i_op_b);
        3'b110: condition_met_in = i_op_a < i_op_b;
        3'b111: condition_met_in = i_op_a >= i_op_b;
        default: condition_met_in = 0;
    endcase
    branch_target_in = i_pc + i_imm;
    predicted_taken_in = i_predicted_taken;

    #1;
endtask

task automatic check(input logic exp_sel, input logic [31:0] exp_target);
    if (pc_sel === exp_sel && pc_target === exp_target) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: ExpSel=%b, ActSel=%b, ExpTarget=%h, ActTarget=%h, PredictedTaken=%b, CondMet=%b", 
            exp_sel, pc_sel, exp_target, pc_target, predicted_taken_in, condition_met_in));
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
    report_info("TB", "Starting pc_target_calc tests.");

    drive(32'h100, 32'h5, 32'h5, 1, 0, 3'b000, 32'h8, 0, 0); check(1, 32'h108); // branch taken, predicted not taken -> mispredict
    drive(32'h100, 32'h5, 32'h5, 1, 0, 3'b000, 32'h8, 0, 1); check(0, 32'h0);   // branch taken, predicted taken -> no mispredict
    drive(32'h100, 32'h5, 32'h6, 1, 0, 3'b000, 32'h8, 0, 0); check(0, 32'h0);   // branch not taken, predicted not taken -> no mispredict
    drive(32'h100, 32'h5, 32'h6, 1, 0, 3'b000, 32'h8, 0, 1); check(1, 32'h104); // branch not taken, predicted taken -> mispredict (PC+4)

    drive(32'h100, 0, 0, 0, 1, 0, 0, 32'h200, 0); check(1, 32'h200);

    drive(32'h100, 32'h5, 32'h5, 1, 1, 3'b000, 32'h8, 32'h200, 0); check(1, 32'h200);

    drive(32'h100, 32'h5, 32'h5, 1, 0, 3'b000, 32'hFFFFFFF8, 0, 0); check(1, 32'hF8);

    report_info("TB", "All tests complete.");
    $display("--- pc_target_calc Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule