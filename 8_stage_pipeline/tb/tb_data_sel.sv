`timescale 1ns / 1ps

module tb_data_sel;
int tests_total;
int tests_passed;
int tests_failed;

logic [31:0] pc;
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] imm;
logic alu_src_a;
logic alu_src_b;
logic [1:0] forward_a_sel;
logic [1:0] forward_b_sel;
logic [31:0] fwd_ex2_data;
logic [31:0] fwd_ex3_data;
logic [31:0] fwd_wb_data;

logic [31:0] operand_a;
logic [31:0] operand_b;
logic [31:0] rs2_data_out;

data_sel dut (.*);

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
    input logic [31:0] i_pc, input logic [31:0] i_rs1, input logic [31:0] i_rs2, input logic [31:0] i_imm,
    input logic i_alu_src_a, input logic i_alu_src_b,
    input logic [1:0] i_fwd_a_sel, input logic [1:0] i_fwd_b_sel,
    input logic [31:0] i_ex2, input logic [31:0] i_ex3, input logic [31:0] i_wb
);
    pc = i_pc;
    rs1_data = i_rs1;
    rs2_data = i_rs2;
    imm = i_imm;
    alu_src_a = i_alu_src_a;
    alu_src_b = i_alu_src_b;
    forward_a_sel = i_fwd_a_sel;
    forward_b_sel = i_fwd_b_sel;
    fwd_ex2_data = i_ex2;
    fwd_ex3_data = i_ex3;
    fwd_wb_data = i_wb;
    #1;
endtask

task automatic check(input logic [31:0] exp_a, input logic [31:0] exp_b, input logic [31:0] exp_rs2_out);
    if (operand_a === exp_a && operand_b === exp_b && rs2_data_out === exp_rs2_out) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: ExpA=%h, ActA=%h, ExpB=%h, ActB=%h, ExpRS2Out=%h, ActRS2Out=%h", 
            exp_a, operand_a, exp_b, operand_b, exp_rs2_out, rs2_data_out));
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
    report_info("TB", "Starting data_sel tests.");

    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 0, 0, 0, 0, 0, 0); check(32'h1, 32'h2, 32'h2);
    drive(32'h100, 32'h1, 32'h2, 32'h3, 1, 1, 0, 0, 0, 0, 0); check(32'h100, 32'h3, 32'h2);

    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 0, 2'b01, 2'b01, 32'hA, 32'hB, 32'hC); check(32'hA, 32'hA, 32'hA);
    
    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 0, 2'b10, 2'b10, 32'hA, 32'hB, 32'hC); check(32'hB, 32'hB, 32'hB);

    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 1, 0, 2'b01, 32'hA, 32'hB, 32'hC); check(32'h1, 32'h3, 32'hA);

    report_info("TB", "All tests complete.");
    $display("--- data_sel Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
