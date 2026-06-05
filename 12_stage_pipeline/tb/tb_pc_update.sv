`timescale 1ns / 1ps

module tb_pc_update;
    // Global Counters
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    // Clock & Reset
    logic clk = 0;
    logic reset;
    logic stall;
    logic flush;
    logic pc_sel;
    logic [31:0] pc_target;
    logic [31:0] pc;

    // DUT instantiation
    pc_update dut (.*);

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus Task
    task drive_pc_update(
        input logic i_reset,
        input logic i_stall,
        input logic i_flush,
        input logic i_pc_sel,
        input logic [31:0] i_pc_target
    );
        @(negedge clk);
        reset = i_reset;
        stall = i_stall;
        flush = i_flush;
        pc_sel = i_pc_sel;
        pc_target = i_pc_target;
    endtask

    // Checking Task
    task check_pc_update(
        input logic [31:0] expected_pc
    );
        @(posedge clk);
        #1;
        if (pc === expected_pc) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Expected=%h, Actual=%h, Inputs: reset=%b, stall=%b, flush=%b, pc_sel=%b, pc_target=%h", 
                   $time, expected_pc, pc, reset, stall, flush, pc_sel, pc_target);
        end
        tests_total++;
    endtask

    // Initial block
    initial begin
        // Reset sequence
        reset = 1; stall = 0; flush = 0; pc_sel = 0; pc_target = 0;
        repeat(2) @(negedge clk);
        reset = 0;
        
        $display("--- Starting pc_update Tests ---");

        // 1. Reset/Flush Priority
        drive_pc_update(1, 0, 0, 1, 32'h100); check_pc_update(32'h0);
        // Note: Flush in this CPU doesn't reset PC, it flushes the pipeline.
        // PC should follow pc_target if pc_sel is high during a flush (branch).
        drive_pc_update(0, 0, 1, 1, 32'h200); check_pc_update(32'h200);

        // 2. Normal Execution
        drive_pc_update(0, 0, 0, 0, 0); check_pc_update(32'h204);
        drive_pc_update(0, 0, 0, 0, 0); check_pc_update(32'h208);

        // 3. Stall Behavior
        drive_pc_update(0, 1, 0, 0, 0); check_pc_update(32'h208);
        drive_pc_update(0, 1, 0, 1, 32'h300); check_pc_update(32'h208); // Stall priority over pc_sel

        // 4. Branch/Jump Taken
        drive_pc_update(0, 0, 0, 1, 32'h400); check_pc_update(32'h400);
        drive_pc_update(0, 0, 0, 0, 0); check_pc_update(32'h404);

        // 5. Unaligned Target
        drive_pc_update(0, 0, 0, 1, 32'h00000002); check_pc_update(32'h00000002);

        // Completion Summary
        $display("--- pc_update Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule