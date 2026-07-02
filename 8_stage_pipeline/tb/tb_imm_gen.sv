`timescale 1ns / 1ps

module tb_imm_gen;
int tests_total;
int tests_passed;
int tests_failed;

logic [31:0] instruction;
logic [31:0] immediate;

imm_gen dut (.*);

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

task automatic drive(input logic [31:0] i_instr);
    instruction = i_instr;
    #1;
endtask

task automatic check(input logic [31:0] expected_imm);
    if (immediate === expected_imm) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Instr=%h, Expected Imm=%h, Actual Imm=%h", 
            instruction, expected_imm, immediate));
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
    report_info("TB", "Starting imm_gen tests.");

    drive(32'h00a00093); check(32'd10);
    drive(32'hfff00093); check(32'hffffffff);

    drive(32'h0020a223); check(32'h4);
    drive(32'hfe20ae23); check(32'hfffffffc);

    drive(32'h00208463); check(32'h8);
    drive(32'hfe208ee3); check(32'hfffffffc);

    drive(32'h123450b7); check(32'h12345000);

    drive(32'h004000ef); check(32'h4);

    report_info("TB", "All tests complete.");
    $display("--- imm_gen Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
