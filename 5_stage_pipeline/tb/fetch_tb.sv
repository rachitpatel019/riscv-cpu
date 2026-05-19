`timescale 1ns / 1ps

module fetch_tb;

    // Port Signals
    logic clk;
    logic reset;
    logic stall;
    logic pc_sel;
    logic [31:0] pc_target;
    logic [31:0] pc;
    logic [31:0] instruction;

    // Instantiate DUT
    fetch dut (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .pc_sel(pc_sel),
        .pc_target(pc_target),
        .pc(pc),
        .instruction(instruction)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test Variables
    int tests_passed = 0;
    int total_tests = 0;

    // Task for checking results
    task check_result(input [31:0] expected_pc, input string msg);
        total_tests++;
        if (pc === expected_pc) begin
            $display("[PASS] %s: PC = 0x%h", msg, pc);
            tests_passed++;
        end else begin
            $display("[FAIL] %s: Expected PC = 0x%h, Got PC = 0x%h", msg, expected_pc, pc);
        end
    endtask

    initial begin
        // Create a dummy program.hex for testing
        // For simulation, we can also just force the memory if needed, 
        // but let's assume program.hex has something predictable or just test PC logic.
        
        $display("Starting Fetch Stage Testbench...");

        // --- RESET ---
        reset = 1;
        stall = 0;
        pc_sel = 0;
        pc_target = 32'h0000_1000;
        @(posedge clk);
        #1;
        reset = 0;
        check_result(32'h0000_0000, "Reset PC");

        // --- NORMAL INCREMENT ---
        @(posedge clk);
        #1;
        check_result(32'h0000_0004, "Increment PC 1");
        
        @(posedge clk);
        #1;
        check_result(32'h0000_0008, "Increment PC 2");

        // --- STALL ---
        stall = 1;
        @(posedge clk);
        #1;
        check_result(32'h0000_0008, "Stall PC");
        
        stall = 0;
        @(posedge clk);
        #1;
        check_result(32'h0000_000C, "Resume PC");

        // --- PC SELECT (BRANCH/JUMP) ---
        pc_sel = 1;
        pc_target = 32'h0000_0100;
        @(posedge clk);
        #1;
        check_result(32'h0000_0100, "Branch PC");
        
        pc_sel = 0;
        @(posedge clk);
        #1;
        check_result(32'h0000_0104, "Increment from branch");

        // --- STALL & PC SELECT (Stall should be ignored during PC select usually, but let's see) ---
        // In most designs, pc_sel from EX has priority over ID stall.
        // Actually, in this design, pc_update.sv logic:
        // assign next_address = pc_sel ? pc_target : (stall ? current_address : current_address + 4);
        stall = 1;
        pc_sel = 1;
        pc_target = 32'h0000_0200;
        @(posedge clk);
        #1;
        check_result(32'h0000_0200, "PC Select with Stall");
        
        stall = 1;
        pc_sel = 0;
        @(posedge clk);
        #1;
        check_result(32'h0000_0200, "Stall after PC Select");

        // Generate Summary
        $display("\nFetch Stage Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

endmodule
