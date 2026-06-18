`timescale 1ns / 1ps

module tb_writeback;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [31:0] pc;
    logic [31:0] alu_result;
    logic [31:0] mem_data;
    logic [1:0] wb_sel;
    logic [31:0] write_data;

    writeback dut (.*);

    task drive_wb(input logic [31:0] i_pc, input logic [31:0] i_alu, input logic [31:0] i_mem, input logic [1:0] i_sel);
        pc = i_pc; alu_result = i_alu; mem_data = i_mem; wb_sel = i_sel;
        #1;
    endtask

    task check_wb(input logic [31:0] exp_data);
        if (write_data === exp_data) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Sel=%b, Exp=%h, Act=%h", 
                   $time, wb_sel, exp_data, write_data);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting writeback Tests (Optimized 2-to-1) ---");

        // 00 -> ALU (or pre-muxed PC+4)
        drive_wb(32'h100, 32'hA, 32'hB, 2'b00); check_wb(32'hA);
        // 01 -> Mem
        drive_wb(32'h100, 32'hA, 32'hB, 2'b01); check_wb(32'hB);
        // 10 -> ALU (or pre-muxed PC+4) - In optimized, bit 0 is the key
        drive_wb(32'h104, 32'h108, 32'hB, 2'b10); check_wb(32'h108);
        // 11 -> Mem
        drive_wb(32'h104, 32'h108, 32'hB, 2'b11); check_wb(32'hB); 

        $display("--- writeback Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
