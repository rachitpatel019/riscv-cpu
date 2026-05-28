`timescale 1ns / 1ps

module core_tb;

    // Port Signals
    logic clk;
    logic reset;
    logic [31:0] out_pc;
    logic [31:0] out_writeback_data;
    logic        out_reg_write;
    logic [31:0] out_alu_result;

    // Instantiate DUT
    core dut (
        .clk(clk),
        .reset(reset),
        .out_pc(out_pc),
        .out_writeback_data(out_writeback_data),
        .out_reg_write(out_reg_write),
        .out_alu_result(out_alu_result)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test Variables
    int tests_passed = 0;
    int total_tests = 0;

    // Task for checking a register value
    task check_reg(input int reg_idx, input [31:0] expected, input string msg);
        total_tests++;
        if (dut.decode_inst.rf.registers1[reg_idx] === expected) begin
            $display("[PASS] %s: x%0d = 0x%h", msg, reg_idx, expected);
            tests_passed++;
        end else begin
            $display("[FAIL] %s: Expected x%0d = 0x%h, Got 0x%h", msg, reg_idx, expected, dut.decode_inst.rf.registers1[reg_idx]);
        end
    endtask

    initial begin
        $display("Starting Integrated Core Testbench...");

        // --- RESET ---
        reset = 1;
        @(posedge clk);
        #1;
        reset = 0;
        
        // Wait for program to execute
        // The pipeline is now 8-stages deep with synchronous IMEM, Regfile, and DMEM.
        // We need to give it more cycles to drain.
        repeat (50) @(posedge clk);

        $display("\nChecking Final Register State:");
        check_reg(1, 32'd10, "x1 (addi)");
        check_reg(2, 32'd20, "x2 (addi)");
        check_reg(3, 32'd30, "x3 (add with forwarding)");
        check_reg(4, 32'd30, "x4 (lw)");
        check_reg(5, 32'd40, "x5 (add with load-use stall)");
        check_reg(6, 32'd1,  "x6 (branch target execution)");

        // Check if memory was written
        total_tests++;
        if (dut.memory_inst.dmem.memory[0] === 32'd30) begin
            $display("[PASS] Memory[0] = 32");
            tests_passed++;
        end else begin
            $display("[FAIL] Memory[0] mismatch. Got 0x%h", dut.memory_inst.dmem.memory[0]);
        end

        // Generate Summary
        $display("\nIntegrated Core Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time: %0t | PC: 0x%h | Instr: 0x%h | WB_Data: 0x%h | WB_Reg: x%0d | Stall: %b | Flush: %b", 
                 $time, dut.F_pc, dut.D_instruction, dut.W_write_data, dut.W_rd, dut.stall, dut.flush);
    end

endmodule
