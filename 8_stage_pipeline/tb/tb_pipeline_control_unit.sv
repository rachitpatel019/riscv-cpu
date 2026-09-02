`timescale 1ns / 1ps

/*
Testbench for the pipeline control unit.
Verifies data hazard stalls, global pipeline flushes, and early branch/JAL redirects.
*/

module tb_pipeline_control_unit;
int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;

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

logic E3_pc_sel;
logic IDRR_jump;
logic IDRR_uses_rs1;
logic IDRR_predict_taken;

logic stall;
logic flush;
logic stage4_pc_sel;
logic stage4_flush;

pipeline_control_unit dut (.*);

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

// Helper task to drive stimuli to the pipeline control unit
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
    input logic [4:0] i_e1_rd,
    input logic i_e3_pc_sel,
    input logic i_idrr_jump,
    input logic i_idrr_uses_rs1,
    input logic i_idrr_predict_taken
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
    E3_pc_sel = i_e3_pc_sel;
    IDRR_jump = i_idrr_jump;
    IDRR_uses_rs1 = i_idrr_uses_rs1;
    IDRR_predict_taken = i_idrr_predict_taken;
    #1;
endtask

// Verifies control outputs against expected values
task automatic check(
    input logic exp_stall,
    input logic exp_flush,
    input logic exp_s4_pc_sel,
    input logic exp_s4_flush
);
    a_pipeline_control: assert (stall === exp_stall && flush === exp_flush && stage4_pc_sel === exp_s4_pc_sel && stage4_flush === exp_s4_flush) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Stall=%b (Exp %b), Flush=%b (Exp %b), S4_PCSel=%b (Exp %b), S4_Flush=%b (Exp %b)",
                     stall, exp_stall, flush, exp_flush, stage4_pc_sel, exp_s4_pc_sel, stage4_flush, exp_s4_flush));
    end
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
    report_info("TB", "Starting pipeline_control_unit tests.");

    // Test Case 1: Idle state
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 0, 0, 5'd0, 0, 0, 0, 0); check(0, 0, 0, 0);

    // Test Case 2: RR Stage Load-Use hazard (stall)
    drive(5'd1, 5'd2, 1, 1, 1, 1, 5'd1, 0, 0, 5'd0, 0, 0, 0, 0); check(1, 0, 0, 0);

    // Test Case 3: E1 Stage Load-Use hazard (stall)
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 1, 1, 5'd2, 0, 0, 0, 0); check(1, 0, 0, 0);

    // Test Case 4: Misprediction flush in E3
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 0, 0, 5'd0, 1, 0, 0, 0); check(0, 1, 0, 0);

    // Test Case 5: Unconditional JAL in Stage 4 (early redirect & flush)
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 0, 0, 5'd0, 0, 1, 0, 0); check(0, 0, 1, 1);

    // Test Case 6: JALR in Stage 4 (uses_rs1 = 1 -> no early redirect)
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 0, 0, 5'd0, 0, 1, 1, 0); check(0, 0, 0, 0);

    // Test Case 7: Predicted taken branch in Stage 4 (early redirect & flush)
    drive(5'd1, 5'd2, 1, 1, 0, 0, 5'd0, 0, 0, 5'd0, 0, 0, 0, 1); check(0, 0, 1, 1);

    // Test Case 8: Combined load-use stall, mispredict flush, and early redirect
    drive(5'd1, 5'd2, 1, 1, 1, 1, 5'd1, 0, 0, 5'd0, 1, 0, 0, 1); check(1, 1, 1, 1);

    report_info("TB", "All tests complete.");
    $display("--- pipeline_control_unit Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) begin
        $display("RESULT: PASS");
    end else begin
        $display("RESULT: FAIL");
    end
    watchdog_trigger = 1;
end
endmodule
