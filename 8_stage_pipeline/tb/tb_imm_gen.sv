`timescale 1ns / 1ps

module tb_imm_gen;
int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;

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
    a_imm_gen: assert (immediate === expected_imm) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Instr=%h, Expected Imm=%h, Actual Imm=%h", 
            instruction, expected_imm, immediate));
    end
endtask

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

    // New additional test cases to improve coverage
    drive(32'h00832283); check(32'd8);         // OP_I_LOAD (positive)
    drive(32'hffc45383); check(-32'd4);         // OP_I_LOAD (negative)
    drive(32'h01048467); check(32'd16);         // OP_I_JALR
    drive(32'h54321317); check(32'h54321000);   // OP_U_AUIPC
    drive(32'hffdfff6f); check(-32'd4);         // OP_J (negative)
    drive(32'h002081b3); check(32'b0);          // default fallback (OP_R)

    report_info("TB", "All tests complete.");
    $display("--- imm_gen Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) begin
        $display("RESULT: PASS");
    end else begin
        $display("RESULT: FAIL");
    end
    watchdog_trigger = 1;
end
endmodule
