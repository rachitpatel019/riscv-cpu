`timescale 1ns / 1ps

module fetch_tb;

    // Port Signals
    logic clk;
    logic reset;
    logic stall;
    logic pc_sel;
    logic [31:0] pc_target;
    
    // Instruction Memory Interface
    logic [31:0] imem_addr;
    logic [31:0] imem_instruction;

    logic [31:0] pc;
    logic [31:0] instruction;

    // Mock Instruction Memory
    logic [31:0] mock_imem [0:255];
    assign imem_instruction = mock_imem[imem_addr[31:2]];

    // Instantiate DUT
    fetch dut (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .pc_sel(pc_sel),
        .pc_target(pc_target),
        .imem_addr(imem_addr),
        .imem_instruction(imem_instruction),
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
        // Initialize mock memory
        for (int i = 0; i < 256; i++) mock_imem[i] = i * 4;
        
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

        // --- STALL & PC SELECT ---
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
