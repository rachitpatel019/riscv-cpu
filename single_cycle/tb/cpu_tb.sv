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

    // Task for checking internal architecture state
    task check_reg(input int reg_num, input logic [31:0] expected);
    begin
        test_count++;
        if (dut.decode_inst.rf.registers[reg_num] !== expected) begin
            $display("[%0t] FAIL: x%0d | Expected: %0d, Got: %0d", 
                     $time, reg_num, $signed(expected), $signed(dut.decode_inst.rf.registers[reg_num]));
            fail_count++;
        end else begin
            $display("[%0t] PASS: x%0d == %0d", $time, reg_num, $signed(expected));
        end
    end
    endtask

    // Main Test Sequence
    initial begin
        $display("\nStarting RV32I Integration Test...\n");

        // 1. RESET PHASE
        reset = 1;
        repeat(2) @(posedge clk);
        reset = 0;

        // 2. EXECUTION PHASE
        // Wait 20 clock cycles to allow the 17-instruction program to fully finish.
        repeat(20) @(posedge clk); 

        // 3. VERIFICATION PHASE
        $display("\n--- Verifying Architecture State ---");
        
        // Math and U-Type Checks
        check_reg(1, 32'd4096); // LUI
        check_reg(2, 32'd4100); // AUIPC
        check_reg(3, 32'd15);   // ADDI
        check_reg(4, 32'd30);   // ADD
        check_reg(5, 32'd15);   // SUB
        
        // Memory Word Checks
        check_reg(6, 32'd30);   // SW / LW
        
        // Memory Sub-Word Checks
        check_reg(7, -32'd5);   // Target stored byte
        check_reg(8, -32'd5);   // LB (Sign-Extended 0xFFFFFFFB)
        check_reg(9, 32'd251);  // LBU (Zero-Extended 0x000000FB)
        
        // Control Flow Exclusivity Check
        // If x10 is 99, a branch/jump failed and the CPU executed a trap instruction!
        check_reg(10, 32'd0);   
        
        // Linking Target Checks
        check_reg(11, 32'd56);  // JAL Return Address
        check_reg(12, 32'd64);  // JALR Return Address
        
        // Final Execution Check
        check_reg(13, 32'd1);   // Reached end of program safely

        // 4. REPORT PHASE
        $display("\n========================");
        $display("Tests Run   : %0d", test_count);
        $display("Failures    : %0d", fail_count);
        
        if (fail_count == 0)
            $display("STATUS      : RV32I DATAPATH VERIFIED");
        else
            $display("STATUS      : DEBUGGING REQUIRED");
            
        $display("========================\n");

        $finish;
    end

endmodule