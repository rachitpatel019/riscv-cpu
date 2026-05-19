`timescale 1ns / 1ps

module memory_tb;

    // Port Signals
    logic clk;
    logic [31:0] alu_result;
    logic [31:0] rs2_data;
    logic mem_read;
    logic mem_write;
    logic [1:0] mem_size;
    logic mem_unsigned;
    logic [4:0] rs1, rs2, rd;
    logic reg_write;

    logic [31:0] read_data;
    logic [31:0] alu_result_output;
    logic [4:0] rs1_out, rs2_out, rd_out;
    logic reg_write_out;

    // Instantiate DUT
    memory dut (
        .clk(clk),
        .alu_result(alu_result),
        .rs2_data(rs2_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .mem_unsigned(mem_unsigned),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .reg_write(reg_write),
        .read_data(read_data),
        .alu_result_output(alu_result_output),
        .rs1_out(rs1_out),
        .rs2_out(rs2_out),
        .rd_out(rd_out),
        .reg_write_out(reg_write_out)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test Variables
    int tests_passed = 0;
    int total_tests = 0;

    // Task for checking results
    task check_data(input [31:0] expected, input string msg);
        total_tests++;
        if (read_data === expected) begin
            $display("[PASS] %s: Data = 0x%h", msg, read_data);
            tests_passed++;
        end else begin
            $display("[FAIL] %s: Expected 0x%h, Got 0x%h", msg, expected, read_data);
        end
    endtask

    initial begin
        $display("Starting Memory Stage Testbench...");

        // Initialize
        alu_result = 32'h0000_0000;
        rs2_data = 32'h0000_0000;
        mem_read = 0;
        mem_write = 0;
        mem_size = 2'b10; // Word
        mem_unsigned = 0;
        rs1 = 0; rs2 = 0; rd = 0; reg_write = 0;

        // --- Test Word Store & Load ---
        @(posedge clk);
        alu_result = 32'h0000_0010;
        rs2_data = 32'h1234_5678;
        mem_write = 1;
        @(posedge clk);
        mem_write = 0;
        mem_read = 1;
        #1;
        check_data(32'h1234_5678, "Word Store/Load");

        // --- Test Byte Store & Load ---
        @(posedge clk);
        alu_result = 32'h0000_0020;
        rs2_data = 32'h0000_00AB;
        mem_write = 1;
        mem_size = 2'b00; // Byte
        @(posedge clk);
        mem_write = 0;
        mem_read = 1;
        mem_unsigned = 1;
        #1;
        check_data(32'h0000_00AB, "Byte Store/Load (unsigned)");

        // --- Test Halfword Store & Load ---
        @(posedge clk);
        alu_result = 32'h0000_0030;
        rs2_data = 32'h0000_CDEF;
        mem_write = 1;
        mem_size = 2'b01; // Half
        @(posedge clk);
        mem_write = 0;
        mem_read = 1;
        mem_unsigned = 1;
        #1;
        check_data(32'h0000_CDEF, "Half Store/Load (unsigned)");

        // --- Test Signed Byte Load ---
        @(posedge clk);
        alu_result = 32'h0000_0040;
        rs2_data = 32'h0000_0080; // Negative if byte
        mem_write = 1;
        mem_size = 2'b00;
        @(posedge clk);
        mem_write = 0;
        mem_read = 1;
        mem_unsigned = 0;
        #1;
        check_data(32'hFFFF_FF80, "Signed Byte Load");

        // Generate Summary
        $display("\nMemory Stage Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

endmodule
