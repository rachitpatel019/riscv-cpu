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

    // Data Memory Interface
    logic [31:0] dmem_addr;
    logic [31:0] dmem_write_data;
    logic        dmem_mem_read;
    logic        dmem_mem_write;
    logic [1:0]  dmem_size;
    logic        dmem_unsigned;
    logic [31:0] dmem_read_data;
    logic        dmem_is_lr;
    logic        dmem_is_sc;
    logic        dmem_sc_success;

    logic [31:0] read_data;
    logic [31:0] alu_result_output;
    logic [4:0] rs1_out, rs2_out, rd_out;
    logic reg_write_out;
    logic stall;

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

        .dmem_addr(dmem_addr),
        .dmem_write_data(dmem_write_data),
        .dmem_mem_read(dmem_mem_read),
        .dmem_mem_write(dmem_mem_write),
        .dmem_size(dmem_size),
        .dmem_unsigned(dmem_unsigned),
        .dmem_read_data(dmem_read_data),
        .dmem_is_lr(dmem_is_lr),
        .dmem_is_sc(dmem_is_sc),
        .dmem_sc_success(dmem_sc_success),

        .read_data(read_data),
        .alu_result_output(alu_result_output),
        .rs1_out(rs1_out),
        .rs2_out(rs2_out),
        .rd_out(rd_out),
        .reg_write_out(reg_write_out)
    );

    // Instantiate Data Memory
    data_mem dmem (
        .clk(clk),
        .stall(stall),
        .mem_read(dmem_mem_read),
        .mem_write(dmem_mem_write & (!dmem_is_sc | dmem_sc_success)),
        .address(dmem_addr),
        .write_data(dmem_write_data),
        .mem_size(dmem_size),
        .mem_unsigned(dmem_unsigned),
        .read_data(dmem_read_data)
    );

    // Mock Reservation Station for LR/SC
    logic res_valid;
    logic [31:0] res_addr;
    always_ff @(posedge clk) begin
        if (reset) begin
            res_valid <= 0;
        end else if (dmem_is_lr) begin
            res_valid <= 1;
            res_addr <= dmem_addr;
        end else if (dmem_is_sc) begin
            res_valid <= 0;
        end
    end
    assign dmem_sc_success = dmem_is_sc && res_valid && (res_addr == dmem_addr);

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
        stall = 0;
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
        @(posedge clk); // Wait for memory read
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
        #1;
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

        // Generate Summary
        $display("\nMemory Stage Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

endmodule
