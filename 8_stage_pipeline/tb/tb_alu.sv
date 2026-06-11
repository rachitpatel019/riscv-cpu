`timescale 1ns / 1ps

module tb_alu;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [31:0] A;
    logic [31:0] B;
    logic [3:0] control;
    logic [31:0] result;

    alu dut (.*);

    import alu_package::*;

    task drive_alu(input logic [31:0] i_a, input logic [31:0] i_b, input logic [3:0] i_ctrl);
        A = i_a; B = i_b; control = i_ctrl;
        #1;
    endtask

    task check_alu(input logic [31:0] exp_res);
        if (result === exp_res) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, A=%h, B=%h, Ctrl=%b, Exp=%h, Act=%h", 
                   $time, A, B, control, exp_res, result);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting alu Tests ---");

        // 1. Arithmetic
        drive_alu(32'h1, 32'h2, ALU_ADD); check_alu(32'h3);
        drive_alu(32'h5, 32'h3, ALU_SUB); check_alu(32'h2);
        drive_alu(32'h7FFFFFFF, 32'h1, ALU_ADD); check_alu(32'h80000000); 

        // 2. Logical
        drive_alu(32'hFFFF0000, 32'h0000FFFF, ALU_AND); check_alu(32'h0);
        drive_alu(32'hAAAA5555, 32'h5555AAAA, ALU_OR);  check_alu(32'hFFFFFFFF);

        // 3. Comparisons
        drive_alu(32'hFFFFFFFF, 32'h00000001, ALU_SLT);  check_alu(32'h1);  
        drive_alu(32'hFFFFFFFF, 32'h00000001, ALU_SLTU); check_alu(32'h0);  

        // 4. Shifts
        drive_alu(32'h1, 32'h4, ALU_SLL); check_alu(32'h10);
        drive_alu(32'h80000000, 32'h1, ALU_SRA); check_alu(32'hC0000000);
        drive_alu(32'h80000000, 32'h1, ALU_SRL); check_alu(32'h40000000);

        // Randomized Loop 
        repeat(100) begin
            logic [31:0] ra, rb;
            ra = $urandom; rb = $urandom;
            drive_alu(ra, rb, ALU_ADD);
            check_alu(ra + rb);
        end

        $display("--- alu Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
