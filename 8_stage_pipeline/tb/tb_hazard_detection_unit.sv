`timescale 1ns / 1ps

module tb_hazard_detection_unit;
int tests_total;
int tests_passed;
int tests_failed;

logic [4:0] D_rs1;
logic [4:0] D_rs2;
logic D_uses_rs1;
logic D_uses_rs2;

logic RR_reg_write;
logic [4:0] RR_rd;

logic E1_reg_write;
logic [4:0] E1_rd;

logic E2_mem_read;
logic [4:0] E2_rd;

logic E3_mem_read;
logic [4:0] E3_rd;

logic stall;

hazard_detection_unit dut (.*);

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
    input logic i_rr_en, input logic [4:0] i_rr_rd,
    input logic i_e1_en, input logic [4:0] i_e1_rd,
    input logic i_e2_read, input logic [4:0] i_e2_rd,
    input logic i_e3_read, input logic [4:0] i_e3_rd
);
    D_rs1 = i_rs1;
    D_rs2 = i_rs2;
    D_uses_rs1 = i_uses_rs1;
    D_uses_rs2 = i_uses_rs2;
    RR_reg_write = i_rr_en;
    RR_rd = i_rr_rd;
    E1_reg_write = i_e1_en;
    E1_rd = i_e1_rd;
    E2_mem_read = i_e2_read;
    E2_rd = i_e2_rd;
    E3_mem_read = i_e3_read;
    E3_rd = i_e3_rd;
    #1;
endtask

task automatic check(input logic exp_stall);
    if (stall === exp_stall) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: ExpStall=%b, ActStall=%b", exp_stall, stall));
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
    report_info("TB", "Starting hazard_detection_unit tests.");

    drive(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0); check(0);

    drive(5'd1, 5'd2, 1, 1, 1, 5'd1, 0, 0, 0, 0, 0, 0); check(1);
    drive(5'd1, 5'd2, 1, 1, 1, 5'd2, 0, 0, 0, 0, 0, 0); check(1);

    drive(5'd1, 5'd2, 1, 1, 0, 0, 1, 5'd1, 0, 0, 0, 0); check(1);

    drive(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 1, 5'd2, 0, 0); check(1);
    
    drive(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 0, 0, 1, 5'd1); check(1);

    drive(5'd1, 5'd2, 1, 0, 1, 5'd2, 0, 0, 0, 0, 0, 0); check(0);

    drive(5'd1, 5'd2, 0, 1, 1, 5'd1, 0, 0, 0, 0, 0, 0); check(0);

    drive(5'd0, 5'd0, 1, 1, 1, 5'd0, 0, 0, 0, 0, 0, 0); check(0);

    report_info("TB", "All tests complete.");
    $display("--- hazard_detection_unit Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
