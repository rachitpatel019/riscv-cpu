`timescale 1ns / 1ps

module writeback_tb;

    // Port Signals
    logic [31:0] pc;
    logic [31:0] alu_result;
    logic [31:0] mem_data;
    logic [1:0] wb_sel;
    logic [31:0] write_data;

    // Instantiate DUT
    writeback dut (
        .pc(pc),
        .alu_result(alu_result),
        .mem_data(mem_data),
        .wb_sel(wb_sel),
        .write_data(write_data)
    );

    // Test Variables
    int tests_passed = 0;
    int total_tests = 0;

    // Task for checking results
    task check_wb(input [31:0] expected, input string msg);
        total_tests++;
        if (write_data === expected) begin
            $display("[PASS] %s: Write Data = 0x%h", msg, write_data);
            tests_passed++;
        end else begin
            $display("[FAIL] %s: Expected 0x%h, Got 0x%h", msg, expected, write_data);
        end
    endtask

    initial begin
        $display("Starting Writeback Stage Testbench...");
        $display("Architecture: 8-stage pipeline (Writeback module remains combinational)");

        // Initialize
        pc = 32'h0000_1000;
        alu_result = 32'hAAAA_AAAA;
        mem_data = 32'hBCDE_F012;

        // --- Test ALU Result Selection ---
        wb_sel = 2'b00;
        #1;
        check_wb(32'hAAAA_AAAA, "Select ALU Result");

        // --- Test Memory Data Selection ---
        wb_sel = 2'b01;
        #1;
        check_wb(32'hBCDE_F012, "Select Memory Data");

        // --- Test PC+4 Selection ---
        wb_sel = 2'b10;
        #1;
        check_wb(32'h0000_1004, "Select PC+4");

        // --- Test Default Case ---
        wb_sel = 2'b11;
        #1;
        check_wb(32'hAAAA_AAAA, "Select Default (ALU)");

        // Generate Summary
        $display("\nWriteback Stage Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

endmodule
