`timescale 1ns / 1ps

module tb_data_mem;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic clk = 0;
    logic stall;
    logic mem_read;
    logic mem_write;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [1:0] mem_size;
    logic mem_unsigned;
    logic [31:0] read_data;

    data_mem dut (.*);

    always #5 clk = ~clk;

    task drive_data_mem(
        input logic i_stall, input logic i_read, input logic i_write,
        input logic [31:0] i_addr, input logic [31:0] i_wdata,
        input logic [1:0] i_size, input logic i_uns
    );
        @(negedge clk);
        stall = i_stall; mem_read = i_read; mem_write = i_write;
        address = i_addr; write_data = i_wdata;
        mem_size = i_size; mem_unsigned = i_uns;
    endtask

    task check_data_mem(input logic [31:0] exp_data);
        @(posedge clk);
        #1;
        if (read_data === exp_data) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Addr=%h, Size=%b, Unsigned=%b, Exp=%h, Act=%h", 
                   $time, address, mem_size, mem_unsigned, exp_data, read_data);
        end
        tests_total++;
    endtask

    initial begin
        stall = 0; mem_read = 0; mem_write = 0;
        $display("--- Starting data_mem Tests ---");

        // 1. Word Access
        drive_data_mem(0, 0, 1, 32'h0, 32'hDEADBEEF, 2'b10, 0); 
        drive_data_mem(0, 1, 0, 32'h0, 0, 2'b10, 0);           
        check_data_mem(32'hDEADBEEF);

        // 2. Halfword Alignment
        drive_data_mem(0, 1, 0, 32'h0, 0, 2'b01, 1);           
        check_data_mem(32'hBEEF);
        drive_data_mem(0, 1, 0, 32'h2, 0, 2'b01, 1);           
        check_data_mem(32'hDEAD);

        // 3. Byte Alignment
        drive_data_mem(0, 1, 0, 32'h0, 0, 2'b00, 1);           
        check_data_mem(32'hEF);
        drive_data_mem(0, 1, 0, 32'h1, 0, 2'b00, 1);           
        check_data_mem(32'hBE);

        // 4. Sign Extension
        drive_data_mem(0, 0, 1, 32'h4, 32'h00000080, 2'b10, 0); 
        drive_data_mem(0, 1, 0, 32'h4, 0, 2'b00, 0);           
        check_data_mem(32'hFFFFFF80);

        // 5. Stall Behavior
        drive_data_mem(1, 1, 0, 32'h0, 0, 2'b10, 0);           
        check_data_mem(32'hFFFFFF80); 

        $display("--- data_mem Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
