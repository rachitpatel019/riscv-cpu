`timescale 1ns / 1ps

module tb_decode;
int tests_total;
int tests_passed;
int tests_failed;

logic [31:0] pc;
logic [31:0] instruction;

logic [31:0] immediate;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic [31:0] pc_out;
logic uses_rs1;
logic uses_rs2;
logic [3:0] alu_op;
logic alu_src_a;
logic alu_src_b;
logic reg_write;
logic mem_read;
logic mem_write;
logic [1:0] mem_size;
logic mem_unsigned;
logic [1:0] wb_sel;
logic branch;
logic jump;
logic [2:0] branch_type;

decode dut (.*);

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

task automatic drive(input logic [31:0] i_pc, input logic [31:0] i_instr);
    pc = i_pc;
    instruction = i_instr;
    #1;
endtask

task automatic check(
    input logic [4:0] i_rs1, input logic [4:0] i_rs2, input logic [4:0] i_rd,
    input logic [31:0] i_pc_out, input logic [31:0] i_imm
);
    if (rs1 === i_rs1 && rs2 === i_rs2 && rd === i_rd && 
        pc_out === i_pc_out && immediate === i_imm) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: rs1=%d, rs2=%d, rd=%d, pc_out=%h, imm=%h", 
            rs1, rs2, rd, pc_out, immediate));
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
    report_info("TB", "Starting decode tests.");

    drive(32'h100, 32'h002081b3); check(5'd1, 5'd2, 5'd3, 32'h100, 32'h0);
    drive(32'h200, 32'h00a00293); check(5'd0, 5'd10, 5'd5, 32'h200, 32'd10);

    report_info("TB", "All tests complete.");
    $display("--- decode Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
