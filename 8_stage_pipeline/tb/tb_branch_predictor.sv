`timescale 1ns / 1ps

/*
Testbench for the branch predictor wrapper module.
Verifies branch target calculation, saturating counter updates, and prediction evaluation.
*/

module tb_branch_predictor;
int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;

logic clk;
logic reset;

logic [31:0] D_pc;
logic stall_frontend;

logic [31:0] IDRR_pc;
logic [31:0] IDRR_immediate;
logic IDRR_branch;

logic [31:0] E3_pc;
logic E3_branch;
logic [1:0] E3_counter_val;
logic E3_condition_met;

logic [31:0] IDRR_branch_target;
logic IDRR_predict_taken;
logic [1:0] IDRR_counter_val;
logic [1:0] E3_next_counter;

branch_predictor dut (.*);

// Clock generation
always #5 clk = ~clk;

// Task to print informational messages
task automatic report_info(string id, string msg);
    $display("[UVM_INFO]  %s @ %0t: %s", id, $time, msg);
endtask

// Task to print error messages and track failures
task automatic report_error(string id, string msg);
    $display("[UVM_ERROR] %s @ %0t: %s", id, $time, msg);
    tests_failed++;
    tests_total++;
endtask

// Task to handle watchdog timeout
task automatic report_fatal(string id, string msg);
    $display("[UVM_FATAL] %s @ %0t: %s", id, $time, msg);
    $finish;
endtask

// Watchdog timer
initial begin
    watchdog_trigger = 0;
    fork
        begin
            #100_000;
            report_fatal("WATCHDOG", "Simulation timed out.");
        end
        begin
            wait (watchdog_trigger);
        end
    join_any
    disable fork;
    $finish;
end

// Main test execution sequence
initial begin
    clk = 0;
    reset = 1;
    stall_frontend = 0;
    D_pc = 32'h0;
    IDRR_pc = 32'h100;
    IDRR_immediate = 32'h20;
    IDRR_branch = 1;
    E3_pc = 32'h0;
    E3_branch = 0;
    E3_counter_val = 2'b01;
    E3_condition_met = 0;
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;

    #10;
    reset = 0;
    report_info("TB", "Starting branch_predictor tests.");

    // Test Case 1: Branch target calculation
    #1;
    a_target_calc: assert (IDRR_branch_target === 32'h120) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("Target calc failure: Exp 32'h120, Act 32'h%h", IDRR_branch_target));
    end

    // Test Case 2: Counter saturating increment when branch taken
    E3_counter_val = 2'b10;
    E3_condition_met = 1;
    #1;
    a_next_counter_inc: assert (E3_next_counter === 2'b11) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("Next counter inc failure: Exp 2'b11, Act %b", E3_next_counter));
    end

    // Test Case 3: Counter saturating cap at 2'b11
    E3_counter_val = 2'b11;
    E3_condition_met = 1;
    #1;
    a_next_counter_sat_max: assert (E3_next_counter === 2'b11) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("Next counter sat max failure: Exp 2'b11, Act %b", E3_next_counter));
    end

    // Test Case 4: Counter saturating decrement when branch not taken
    E3_counter_val = 2'b10;
    E3_condition_met = 0;
    #1;
    a_next_counter_dec: assert (E3_next_counter === 2'b01) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("Next counter dec failure: Exp 2'b01, Act %b", E3_next_counter));
    end

    report_info("TB", "All tests complete.");
    $display("--- branch_predictor Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) begin
        $display("RESULT: PASS");
    end else begin
        $display("RESULT: FAIL");
    end
    watchdog_trigger = 1;
end
endmodule
