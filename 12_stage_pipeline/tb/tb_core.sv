`timescale 1ns / 1ps

module tb_core;

    // Global Variables
    int cycle_count = 0;
    int cycles_run = 0;
    int errors_found = 0;
    localparam MAX_CYCLES = 500;

    // Clock & Reset
    logic clk = 0;
    logic reset = 1;

    always #5 clk = ~clk;

    // DUT Probes (White-Box Probing)
    wire [31:0] probe_fetch_pc = dut.F_pc;           // Stage 1
    wire [31:0] probe_alu_result = dut.E2_alu_result; // Stage 8
    wire probe_mem_read = dut.M1_mem_read;           // Stage 10
    wire [31:0] probe_wb_data = dut.W_write_data;     // Stage 12
    wire [4:0] probe_wb_reg = dut.W_rd;               // Stage 12
    wire probe_reg_write = dut.W_reg_write;           // Stage 12

    // The "Golden" Data Structure
    typedef struct {
        logic [31:0] expected_fetch_pc;
        logic [31:0] expected_alu_result;
        logic expected_mem_read;
        logic [31:0] expected_wb_data;
        logic [4:0] expected_wb_reg;
        logic expected_reg_write;
    } cycle_state_t;

    cycle_state_t expected_states [0:MAX_CYCLES];

    // DUT Instance
    core dut (
        .clk(clk),
        .reset(reset),
        .out_pc(),
        .out_writeback_data(),
        .out_reg_write(),
        .out_alu_result()
    );

    // Memory Initialization & Expected State Calculation
    initial begin
        // 1. Initialize all expected states
        for (int i = 0; i <= MAX_CYCLES; i++) begin
            expected_states[i] = '{
                expected_fetch_pc: i * 4, 
                expected_alu_result: 32'h0, 
                expected_mem_read: 1'b0, 
                expected_wb_data: 32'h0, 
                expected_wb_reg: 5'h0, 
                expected_reg_write: 1'b0
            };
        end

        // 2. Override specific values for known instructions
        
        // PC 0: addi x1, x0, 1 (Fetch C1, ALU C7, WB C11)
        expected_states[6].expected_alu_result = 32'h1;
        expected_states[10].expected_wb_data   = 32'h1;
        expected_states[10].expected_wb_reg    = 5'd1;
        expected_states[10].expected_reg_write = 1'b1;

        // PC 20 (0x14): addi x2, x0, 2 (Fetch C6, ALU C12, WB C16)
        expected_states[11].expected_alu_result = 32'h2;
        expected_states[15].expected_wb_data    = 32'h2;
        expected_states[15].expected_wb_reg     = 5'd2;
        expected_states[15].expected_reg_write  = 1'b1;

        // PC 40 (0x28): add x3, x1, x2 (Fetch C11, ALU C17, WB C21)
        expected_states[16].expected_alu_result = 32'h3;
        expected_states[20].expected_wb_data    = 32'h3;
        expected_states[20].expected_wb_reg     = 5'd3;
        expected_states[20].expected_reg_write = 1'b1;

        // Phase B: Forwarding Priority
        // PC 60 (0x3c): addi x4, x0, 4 (Fetch C16, ALU C22, WB C26)
        expected_states[21].expected_alu_result = 32'h4;
        expected_states[25].expected_wb_data    = 32'h4;
        expected_states[25].expected_wb_reg     = 5'd4;
        expected_states[25].expected_reg_write  = 1'b1;

        // PC 68 (0x44): add x5, x4, x4 (Fetch C18, ALU C24, WB C28)
        expected_states[23].expected_alu_result = 32'h8;
        expected_states[27].expected_wb_data    = 32'h8;
        expected_states[27].expected_wb_reg     = 5'd5;
        expected_states[27].expected_reg_write  = 1'b1;

        // PC 72 (0x48): addi x6, x0, 6 (Fetch C19, ALU C25, WB C29)
        expected_states[24].expected_alu_result = 32'h6;
        expected_states[28].expected_wb_data    = 32'h6;
        expected_states[28].expected_wb_reg     = 5'd6;
        expected_states[28].expected_reg_write  = 1'b1;

        // PC 84 (0x54): add x7, x6, x6 (Fetch C22, ALU C28, WB C32)
        expected_states[27].expected_alu_result = 32'hc;
        expected_states[31].expected_wb_data    = 32'hc;
        expected_states[31].expected_wb_reg     = 5'd7;
        expected_states[31].expected_reg_write  = 1'b1;

        // PC 88 (0x58): addi x8, x0, 8 (Fetch C23, ALU C29, WB C33)
        expected_states[28].expected_alu_result = 32'h8;
        expected_states[32].expected_wb_data    = 32'h8;
        expected_states[32].expected_wb_reg     = 5'd8;
        expected_states[32].expected_reg_write  = 1'b1;

        // PC 104 (0x68): add x9, x8, x8 (Fetch C27, ALU C33, WB C37)
        expected_states[32].expected_alu_result = 32'h10;
        expected_states[36].expected_wb_data    = 32'h10;
        expected_states[36].expected_wb_reg     = 5'd9;
        expected_states[36].expected_reg_write  = 1'b1;

        // PC 108 (0x6c): addi x10, x0, 10 (Fetch C28, ALU C34, WB C38)
        expected_states[33].expected_alu_result = 32'ha;
        expected_states[37].expected_wb_data    = 32'ha;
        expected_states[37].expected_wb_reg     = 5'd10;
        expected_states[37].expected_reg_write  = 1'b1;

        // PC 128 (0x80): add x11, x10, x10 (Fetch C33, ALU C39, WB C43)
        expected_states[38].expected_alu_result = 32'd20;
        expected_states[42].expected_wb_data    = 32'd20;
        expected_states[42].expected_wb_reg     = 5'd11;
        expected_states[42].expected_reg_write  = 1'b1;

        // Phase C: Load-Use
        // PC 156 (0x9c): lw x12, 0(x0) (Fetch C40, M1 C48, WB C50)
        
        // PC expectation handling for branches and end of program
        for (int i = 0; i <= MAX_CYCLES; i++) begin
            if (i < 43) 
                expected_states[i].expected_fetch_pc = i * 4;
            else
                expected_states[i].expected_fetch_pc = 32'hffffffff; // Sentinel value to disable check
        end



        // Reset sequence
        reset = 1;
        repeat (2) @(posedge clk);
        #1;
        reset = 0;

        // Wait for completion logic
        fork
            begin
                // Timeout
                repeat (MAX_CYCLES) @(posedge clk);
                $display("\n--- Simulation Timeout ---");
            end
            begin
                // Detect infinite loop (jal x0, 0) at PC 0xd4 (Program has 54 instructions total)
                wait (cycles_run > 150);
                forever begin
                    @(posedge clk);
                    if (dut.W_pc == 32'h000000d4 && dut.F_pc == 32'h000000d4) break;
                end
                $display("\n--- Program Completion Detected ---");
            end
        join_any

        // Final Summary
        $display("\n========================================");
        $display("Final Test Summary:");
        $display("  Cycles Run:   %0d", cycles_run);
        $display("  Errors Found: %0d", errors_found);
        if (errors_found == 0)
            $display("  [TEST PASSED]");
        else
            $display("  [TEST FAILED]");
        $display("========================================\n");
        $finish;
    end

    // The Scoreboard (Checker Logic)
    always @(negedge clk) begin
        if (!reset) begin
            // 1. Comparison logic
            // Check Fetch PC (skip if sentinel)
            if (expected_states[cycle_count].expected_fetch_pc !== 32'hffffffff) begin
                if (probe_fetch_pc !== expected_states[cycle_count].expected_fetch_pc) begin
                    $error("[%0t] Cycle %0d: Mismatch in Fetch PC! Expected: %h, Actual: %h", $time, cycle_count+1, expected_states[cycle_count].expected_fetch_pc, probe_fetch_pc);
                    errors_found++;
                end
            end
            
            // Check ALU Result (only if non-zero expected)
            if (expected_states[cycle_count].expected_alu_result !== 32'h0) begin
                if (probe_alu_result !== expected_states[cycle_count].expected_alu_result) begin
                    $error("[%0t] Cycle %0d: Mismatch in ALU Result! Expected: %h, Actual: %h", $time, cycle_count+1, expected_states[cycle_count].expected_alu_result, probe_alu_result);
                    errors_found++;
                end
            end

            // Check WB Data (already guarded by expected_reg_write)
            if (expected_states[cycle_count].expected_reg_write) begin
                if (probe_wb_data !== expected_states[cycle_count].expected_wb_data) begin
                    $error("[%0t] Cycle %0d: Mismatch in WB Data! Expected: %h, Actual: %h", $time, cycle_count+1, expected_states[cycle_count].expected_wb_data, probe_wb_data);
                    errors_found++;
                end
                if (probe_wb_reg !== expected_states[cycle_count].expected_wb_reg) begin
                    $error("[%0t] Cycle %0d: Mismatch in WB Reg! Expected: %h, Actual: %h", $time, cycle_count+1, expected_states[cycle_count].expected_wb_reg, probe_wb_reg);
                    errors_found++;
                end
                if (probe_reg_write !== expected_states[cycle_count].expected_reg_write) begin
                    $error("[%0t] Cycle %0d: Mismatch in Reg Write! Expected: %b, Actual: %b", $time, cycle_count+1, expected_states[cycle_count].expected_reg_write, probe_reg_write);
                    errors_found++;
                end
            end

            // 4. Increment cycle counters
            cycle_count++;
            cycles_run++;
        end
    end

endmodule
