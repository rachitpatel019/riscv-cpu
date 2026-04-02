`timescale 1ns/1ps

module cpu_tb;

    // DUT Signals
    logic clk;
    logic reset;

    // Instantiate Top-Level CPU
    cpu dut (.*);

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test tracking
    int test_count = 0;
    int fail_count = 0;

    // Tasks for checking internal architecture state
    task check_reg(input int reg_num, input logic [31:0] expected);
    begin
        test_count++;
        // Using hierarchical paths to peek inside the CPU's register file
        if (dut.decode_inst.rf.registers[reg_num] !== expected) begin
            $display("[%0t] FAIL: x%0d | Expected: %0d, Got: %0d", 
                     $time, reg_num, expected, dut.decode_inst.rf.registers[reg_num]);
            fail_count++;
        end else begin
            $display("[%0t] PASS: x%0d == %0d", $time, reg_num, expected);
        end
    end
    endtask

    task check_mem(input int word_addr, input logic [31:0] expected);
    begin
        test_count++;
        // Using hierarchical paths to peek inside the CPU's data memory
        if (dut.memory_inst.dmem.memory[word_addr] !== expected) begin
            $display("[%0t] FAIL: Mem[%0d] | Expected: %0d, Got: %0d", 
                     $time, word_addr, expected, dut.memory_inst.dmem.memory[word_addr]);
            fail_count++;
        end else begin
            $display("[%0t] PASS: Mem[%0d] == %0d", $time, word_addr, expected);
        end
    end
    endtask

    // Main Test Sequence
    initial begin
        $display("Starting Top-Level CPU Integration Test...\n");

        // 1. RESET PHASE
        reset = 1;
        repeat(2) @(posedge clk);
        reset = 0;

        // 2. EXECUTION PHASE
        // Based on fetch_tb.sv, your program.hex contains:
        // PC=0:  addi x1, x0, 10    (00a00093)
        // PC=4:  addi x2, x0, 20    (01400113)
        // PC=8:  add x3, x1, x2     (002081b3) -> x3 should become 30
        // PC=12: sw x3, 0(x0)       (00302023) -> mem[0] should become 30
        // PC=16: lw x4, 0(x0)       (00002203) -> x4 should become 30
        
        // Wait 6 clock cycles to ensure all 5 instructions complete 
        // (plus one buffer cycle for the last writeback).
        repeat(6) @(posedge clk); 

        // 3. VERIFICATION PHASE
        $display("--- Verifying Final Architecture State ---");
        
        // Check if the registers hold the correct arithmetic results
        check_reg(1, 32'd10);
        check_reg(2, 32'd20);
        check_reg(3, 32'd30);
        
        // Check if the Store Word (sw) successfully wrote to data memory
        check_mem(0, 32'd30);

        // Check if the Load Word (lw) successfully read that data back into a new register
        check_reg(4, 32'd30);

        // 4. REPORT PHASE
        $display("\n========================");
        $display("Tests Run   : %0d", test_count);
        $display("Failures    : %0d", fail_count);
        $display("========================");

        $finish;
    end

endmodule