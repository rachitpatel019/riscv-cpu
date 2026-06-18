`timescale 1ns / 1ps

module tb_regfile;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic clk = 0;
    logic [4:0] read_address1;
    logic [4:0] read_address2;
    logic [31:0] read_data1;
    logic [31:0] read_data2;
    logic [4:0] write_address;
    logic [31:0] write_data;
    logic write_enable;

    regfile dut (.*);

    always #5 clk = ~clk;

    task drive_write(input logic [4:0] addr, input logic [31:0] data, input logic en);
        @(negedge clk);
        write_address = addr;
        write_data = data;
        write_enable = en;
    endtask

    task drive_read(input logic [4:0] addr1, input logic [4:0] addr2);
        @(negedge clk);
        read_address1 = addr1;
        read_address2 = addr2;
    endtask

    task check_read(input logic [31:0] exp1, input logic [31:0] exp2);
        @(posedge clk); // Sampling edge
        @(posedge clk); // Data ready edge
        #1;
        if (read_data1 === exp1 && read_data2 === exp2) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Read1: Exp=%h, Act=%h, Read2: Exp=%h, Act=%h", 
                   $time, exp1, read_data1, exp2, read_data2);
        end
        tests_total++;
    endtask

    initial begin
        write_enable = 0;
        $display("--- Starting regfile Tests ---");

        // 1. Standard Write/Read
        drive_write(5'd1, 32'hAAAA_BBBB, 1);
        drive_write(5'd2, 32'hCCCC_DDDD, 1);
        drive_read(5'd1, 5'd2);
        check_read(32'hAAAA_BBBB, 32'hCCCC_DDDD);

        // 2. Hardwire R0
        drive_write(5'd0, 32'hFFFF_FFFF, 1);
        drive_read(5'd0, 5'd1);
        check_read(32'h0, 32'hAAAA_BBBB);

        // 3. Simple Write/Read Sequence
        drive_write(5'd3, 32'h1234_5678, 1);
        drive_read(5'd3, 5'd1);
        check_read(32'h1234_5678, 32'hAAAA_BBBB);

        // 4. Read-While-Write Conflict (Internal Forwarding)
        @(negedge clk);
        write_address = 5'd5;
        write_data = 32'hFEED_FACE;
        write_enable = 1;
        read_address1 = 5'd5;
        read_address2 = 5'd1;
        check_read(32'hFEED_FACE, 32'hAAAA_BBBB);

        $display("--- regfile Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
