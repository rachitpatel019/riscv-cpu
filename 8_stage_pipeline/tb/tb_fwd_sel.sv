`timescale 1ns / 1ps

/*
Testbench for the fwd_sel operand multiplexer module.
Verifies selection between link PC and ALU result for forwarding.
*/

module tb_fwd_sel;
int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;

logic [1:0] wb_sel;
logic [31:0] pc_plus_4;
logic [31:0] alu_result;

logic [31:0] fwd_val;

fwd_sel dut (.*);

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
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    report_info("TB", "Starting fwd_sel tests.");

    pc_plus_4 = 32'h0000_0104;
    alu_result = 32'h0000_ABCD;

    // Test Case 1: Select ALU result (wb_sel == 2'b00)
    wb_sel = 2'b00;
    #1;
    a_select_alu_00: assert (fwd_val === 32'h0000_ABCD) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("Select ALU 00 failure: Exp 32'h0000_ABCD, Act 32'h%h", fwd_val));
    end

    // Test Case 2: Select Link PC (wb_sel == 2'b10)
    wb_sel = 2'b10;
    #1;
    a_select_pc_10: assert (fwd_val === 32'h0000_0104) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("Select Link PC 10 failure: Exp 32'h0000_0104, Act 32'h%h", fwd_val));
    end

    // Test Case 3: Select ALU result (wb_sel == 2'b01 memory load)
    wb_sel = 2'b01;
    #1;
    a_select_alu_01: assert (fwd_val === 32'h0000_ABCD) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("Select ALU 01 failure: Exp 32'h0000_ABCD, Act 32'h%h", fwd_val));
    end

    report_info("TB", "All tests complete.");
    $display("--- fwd_sel Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) begin
        $display("RESULT: PASS");
    end else begin
        $display("RESULT: FAIL");
    end
    watchdog_trigger = 1;
end
endmodule
