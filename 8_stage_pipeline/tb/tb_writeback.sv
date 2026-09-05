`timescale 1ns / 1ps

module tb_writeback;
int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;

logic [31:0] fwd_val;
logic [31:0] mem_data;
logic [1:0] wb_sel;

logic [31:0] write_data;

writeback dut (.*);

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
    input logic [31:0] i_fwd,
    input logic [31:0] i_mem,
    input logic [1:0] i_sel
);
    fwd_val = i_fwd;
    mem_data = i_mem;
    wb_sel = i_sel;
    #1;
endtask

task automatic check(input logic [31:0] exp_data);
    a_writeback: assert (write_data === exp_data) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Sel=%b, Exp=%h, Act=%h", wb_sel, exp_data, write_data));
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
    report_info("TB", "Starting writeback tests.");

    drive(32'hA, 32'hB, 2'b00); check(32'hA);
    drive(32'hA, 32'hB, 2'b01); check(32'hB);
    drive(32'h108, 32'hB, 2'b10); check(32'h108);
    drive(32'h108, 32'hB, 2'b11); check(32'hB);

    drive(32'h00000000, 32'hFFFFFFFF, 2'b00); check(32'h00000000);
    drive(32'h00000000, 32'hFFFFFFFF, 2'b01); check(32'hFFFFFFFF);
    drive(32'h55555555, 32'hAAAAAAAA, 2'b00); check(32'h55555555);
    drive(32'h55555555, 32'hAAAAAAAA, 2'b01); check(32'hAAAAAAAA);

    for (int i = 0; i < 50; i++) begin
        logic [31:0] rand_fwd;
        logic [31:0] rand_mem;
        logic [1:0] rand_sel;
        logic [31:0] expected;

        rand_fwd = $urandom;
        rand_mem = $urandom;
        rand_sel = $urandom;
        expected = rand_sel[0] ? rand_mem : rand_fwd;

        drive(rand_fwd, rand_mem, rand_sel);
        check(expected);
    end

    report_info("TB", "All tests complete.");
    $display("--- writeback Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) begin
        $display("RESULT: PASS");
    end else begin
        $display("RESULT: FAIL");
    end
    watchdog_trigger = 1;
end
endmodule
