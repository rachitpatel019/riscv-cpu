`timescale 1ns / 1ps

module core_tb;

    // Port Signals
    logic clk;
    logic reset;

    // Instantiate DUT
    core dut (
        .clk(clk),
        .reset(reset)
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
        if (dut.decode_inst.rf.registers[reg_idx] === expected) begin
            $display("[PASS] %s: x%0d = 0x%h", msg, reg_idx, expected);
            tests_passed++;
        end else begin
            $display("[FAIL] %s: Expected x%0d = 0x%h, Got 0x%h", msg, reg_idx, expected, dut.decode_inst.rf.registers[reg_idx]);
        end
    endtask

    initial begin
        $display("Starting Integrated Core Testbench...");

        // --- RESET ---
        reset = 1;
        @(posedge clk);
        #1;
        reset = 0;
        
        // Give it enough cycles to complete the extended program
        repeat (50) @(posedge clk);

        $display("\nChecking Final Register State:");
        check_reg(1, 32'd10, "x1 (addi)");
        check_reg(2, 32'd20, "x2 (addi)");
        check_reg(3, 32'd30, "x3 (add with forwarding)");
        check_reg(4, 32'd30, "x4 (lw)");
        check_reg(5, 32'd40, "x5 (add with load-use stall)");
        check_reg(6, 32'd1,  "x6 (branch target execution)");

        // AMO tests
        check_reg(7, 32'd30, "x7 (amoadd read val)");
        check_reg(8, 32'd40, "x8 (amoswap read val)");
        check_reg(9, 32'd20, "x9 (lr success read val)");
        check_reg(10, 32'd0, "x10 (sc success code)");
        check_reg(11, 32'd10, "x11 (lr second read val)");
        check_reg(12, 32'd0, "x12 (sc second success code)");
        check_reg(13, 32'd1, "x13 (sc fail code)");

        // Check if memory was written correctly by the final SC
        total_tests++;
        if (dut.memory_inst.dmem.memory[0] === 32'd20) begin
            $display("[PASS] Memory[0] = 20");
            tests_passed++;
        end else begin
            $display("[FAIL] Memory[0] mismatch. Expected 20, Got 0x%h", dut.memory_inst.dmem.memory[0]);
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
