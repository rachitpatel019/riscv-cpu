`timescale 1ns / 1ps

module memory_tb;
    import decoder_package::*;

    // Port Signals
    logic clk;
    logic reset;
    logic [31:0] alu_result;
    logic [31:0] rs2_data;
    logic mem_read;
    logic mem_write;
    logic [1:0] mem_size;
    logic mem_unsigned;
    logic [4:0] rs1, rs2, rd;
    logic reg_write;
    logic is_atomic;
    logic [4:0] amo_op;

    logic [31:0] read_data;
    logic [31:0] alu_result_output;
    logic [4:0] rs1_out, rs2_out, rd_out;
    logic reg_write_out;

    // Instantiate DUT
    memory dut (
        .clk(clk),
        .reset(reset),
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
        .is_atomic(is_atomic),
        .amo_op(amo_op),
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
        reset = 1;
        alu_result = 32'h0000_0000;
        rs2_data = 32'h0000_0000;
        mem_read = 0;
        mem_write = 0;
        mem_size = 2'b10; // Word
        mem_unsigned = 0;
        rs1 = 0; rs2 = 0; rd = 0; reg_write = 0;
        is_atomic = 0;
        amo_op = 0;

        @(posedge clk);
        #1 reset = 0;

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

        // --- Test Atomic: LR.W (Load Reserved) ---
        @(posedge clk);
        alu_result = 32'h0000_0010;
        mem_read = 1;
        is_atomic = 1;
        amo_op = AMO_LR;
        @(posedge clk);
        #1;
        check_data(32'h1234_5678, "LR.W Read");
        
        // --- Test Atomic: SC.W Success ---
        @(posedge clk);
        alu_result = 32'h0000_0010;
        rs2_data = 32'h8765_4321;
        mem_write = 1;
        is_atomic = 1;
        amo_op = AMO_SC;
        #1; // Check code before posedge clk that clears reservation
        check_data(32'h0000_0000, "SC.W Success Code");
        
        @(posedge clk);
        
        // Verify memory was updated
        mem_write = 0;
        is_atomic = 0;
        mem_read = 1;
        @(posedge clk);
        #1;
        check_data(32'h8765_4321, "SC.W Memory Verify");

        // --- Test Atomic: SC.W Failure (No LR) ---
        @(posedge clk);
        alu_result = 32'h0000_0010;
        rs2_data = 32'hFFFF_FFFF;
        mem_write = 1;
        is_atomic = 1;
        amo_op = AMO_SC;
        @(posedge clk);
        #1;
        check_data(32'h0000_0001, "SC.W Failure Code");

        // Verify memory was NOT updated
        mem_write = 0;
        is_atomic = 0;
        mem_read = 1;
        @(posedge clk);
        #1;
        check_data(32'h8765_4321, "SC.W Failure Memory Verify");

        // --- Test Atomic: AMOADD.W ---
        // Memory[0x10] is 0x8765_4321
        // Add 0x1111_1111
        @(posedge clk);
        alu_result = 32'h0000_0010;
        rs2_data = 32'h1111_1111;
        mem_read = 1;
        mem_write = 1;
        is_atomic = 1;
        amo_op = AMO_ADD;
        #1; // Check before posedge clk that updates memory
        check_data(32'h8765_4321, "AMOADD.W Read Data"); // Returns original value

        @(posedge clk);
        #1;
        // Verify memory update (0x8765_4321 + 0x1111_1111 = 0x9876_5432)
        mem_read = 1;
        mem_write = 0;
        is_atomic = 0;
        @(posedge clk);
        #1;
        check_data(32'h9876_5432, "AMOADD.W Memory Verify");

        // Generate Summary
        $display("\nMemory Stage Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

endmodule
