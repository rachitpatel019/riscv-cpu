`timescale 1ns / 1ps

/*
Testbench for the hazard detection unit.
Verifies stall generation logic for raw data hazards.
*/

module tb_hazard_detection_unit;
int tests_total;
int tests_passed;
int tests_failed;

logic [4:0] D_rs1;
logic [4:0] D_rs2;
logic D_uses_rs1;
logic D_uses_rs2;

logic RR_reg_write;
logic RR_mem_read;
logic [4:0] RR_rd;

logic E1_reg_write;
logic E1_mem_read;
logic [4:0] E1_rd;

logic stall;

hazard_detection_unit dut (.*);

// Task to print informational messages.
task automatic report_info(string id, string msg);
    $display("[UVM_INFO]  %s @ %0t: %s", id, $time, msg);
endtask

// Task to print error messages and track failures.
task automatic report_error(string id, string msg);
    $display("[UVM_ERROR] %s @ %0t: %s", id, $time, msg);
    tests_failed++;
    tests_total++;
endtask

// Task to handle watchdog timeout.
task automatic report_fatal(string id, string msg);
    $display("[UVM_FATAL] %s @ %0t: %s", id, $time, msg);
    $finish;
endtask

// Helper task to drive stimuli to the hazard detection unit.
task automatic drive(
    input logic [4:0] i_rs1,
    input logic [4:0] i_rs2,
    input logic i_uses_rs1,
    input logic i_uses_rs2,
    input logic i_rr_write,
    input logic i_rr_read,
    input logic [4:0] i_rr_rd,
    input logic i_e1_write,
    input logic i_e1_read,
    input logic [4:0] i_e1_rd
);
    D_rs1 = i_rs1;
    D_rs2 = i_rs2;
    D_uses_rs1 = i_uses_rs1;
    D_uses_rs2 = i_uses_rs2;
    RR_reg_write = i_rr_write;
    RR_mem_read = i_rr_read;
    RR_rd = i_rr_rd;
    E1_reg_write = i_e1_write;
    E1_mem_read = i_e1_read;
    E1_rd = i_e1_rd;
    #1;
endtask

// Verifies if the output stall match the expected stall value.
task automatic check(input logic exp_stall);
    if (stall === exp_stall) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: ExpStall=%b, ActStall=%b", exp_stall, stall));
    end
endtask

// Watchdog timer.
initial begin
    #100_000;
    report_fatal("WATCHDOG", "Simulation timed out.");
end

// Main test execution sequence.
initial begin
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    report_info("TB", "Starting hazard_detection_unit tests.");

    // Test Case 1: No dependency (no stall)
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 0, 0, 5'd0); check(0);

    // Test Case 2: Adjacent ALU dependency (producer in RR / Stage 4) - no stall (forwarded)
    drive(5'd1, 5'd2, 1, 1, 1, 0, 5'd1, 0, 0, 5'd0); check(0);
    drive(5'd1, 5'd2, 1, 1, 1, 0, 5'd2, 0, 0, 5'd0); check(0);

    // Test Case 3: Adjacent LOAD dependency (producer in RR / Stage 4) - stalls for 2 cycles
    drive(5'd1, 5'd2, 1, 1, 1, 1, 5'd1, 0, 0, 5'd0); check(1);
    drive(5'd1, 5'd2, 1, 1, 1, 1, 5'd2, 0, 0, 5'd0); check(1);

    // Test Case 4: ALU dependency separated by 1 instruction (producer in EX1 / Stage 5) - no stall (forwarded)
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 1, 0, 5'd1); check(0);
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 1, 0, 5'd2); check(0);

    // Test Case 5: LOAD dependency separated by 1 instruction (producer in EX1 / Stage 5) - stalls for 1 cycle
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 1, 1, 5'd1); check(1);
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 1, 1, 5'd2); check(1);

    // Test Case 6: Dependency on register 0 (never stalls)
    drive(5'd0, 5'd0, 1, 1, 1, 0, 5'd0, 0, 0, 5'd0); check(0);

    // Test Case 7: Unused register dependency (no stall)
    drive(5'd1, 5'd2, 0, 1, 1, 0, 5'd1, 0, 0, 5'd0); check(0);
    drive(5'd1, 5'd2, 1, 0, 1, 0, 5'd2, 0, 0, 5'd0); check(0);

    report_info("TB", "All tests complete.");
    $display("--- hazard_detection_unit Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
