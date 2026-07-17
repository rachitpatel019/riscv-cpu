`timescale 1ns / 1ps

module tb_forwarding_unit;
int tests_total;
int tests_passed;
int tests_failed;

logic [4:0] IDRR_rs1;
logic [4:0] IDRR_rs2;
logic IDRR_uses_rs1;
logic IDRR_uses_rs2;

logic E1_reg_write;
logic E1_mem_read;
logic [4:0] E1_rd;
 
logic E2_reg_write;
logic E2_mem_read;
logic [4:0] E2_rd;
 
logic E3_reg_write;
logic [4:0] E3_rd;

logic [1:0] forward_a_sel;
logic [1:0] forward_b_sel;

forwarding_unit dut (.*);

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
    input logic [4:0] i_rs1, input logic [4:0] i_rs2,
    input logic i_uses_rs1, input logic i_uses_rs2,
    input logic i_e1_en, input logic i_e1_read, input logic [4:0] i_e1_rd,
    input logic i_e2_en, input logic i_e2_read, input logic [4:0] i_e2_rd,
    input logic i_e3_en, input logic [4:0] i_e3_rd
);
    IDRR_rs1 = i_rs1;
    IDRR_rs2 = i_rs2;
    IDRR_uses_rs1 = i_uses_rs1;
    IDRR_uses_rs2 = i_uses_rs2;
    E1_reg_write = i_e1_en;
    E1_mem_read = i_e1_read;
    E1_rd = i_e1_rd;
    E2_reg_write = i_e2_en;
    E2_mem_read = i_e2_read;
    E2_rd = i_e2_rd;
    E3_reg_write = i_e3_en;
    E3_rd = i_e3_rd;
    #1;
endtask

task automatic check(input logic [1:0] exp_a_sel, input logic [1:0] exp_b_sel);
    if (forward_a_sel === exp_a_sel && forward_b_sel === exp_b_sel) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: ExpA_sel=%b, ActA_sel=%b, ExpB_sel=%b, ActB_sel=%b",
            exp_a_sel, forward_a_sel, exp_b_sel, forward_b_sel));
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
    report_info("TB", "Starting forwarding_unit tests.");

    drive(5'd1, 5'd2, 1, 1, 1, 0, 5'd1, 0, 0, 5'd0, 0, 5'd0); check(2'b11, 2'b00);

    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 1, 0, 5'd1, 0, 5'd0); check(2'b01, 2'b00);

    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 0, 0, 5'd0, 1, 5'd1); check(2'b10, 2'b00);

    drive(5'd0, 5'd0, 1, 1, 1, 0, 5'd0, 1, 0, 5'd0, 0, 5'd0); check(2'b00, 2'b00);

    drive(5'd1, 5'd2, 0, 0, 1, 0, 5'd1, 0, 0, 5'd0, 0, 5'd0); check(2'b00, 2'b00);

    drive(5'd1, 5'd2, 1, 1, 1, 1, 5'd1, 0, 0, 5'd0, 0, 5'd0); check(2'b00, 2'b00);

    report_info("TB", "All tests complete.");
    $display("--- forwarding_unit Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
