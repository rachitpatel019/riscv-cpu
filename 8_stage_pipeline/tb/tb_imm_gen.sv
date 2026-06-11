`timescale 1ns / 1ps

module tb_imm_gen;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [31:0] instruction;
    logic [31:0] immediate;

    imm_gen dut (.*);

    task drive_imm_gen(input logic [31:0] i_instr);
        instruction = i_instr;
        #1;
    endtask

    task check_imm_gen(input logic [31:0] expected_imm);
        if (immediate === expected_imm) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Instr=%h, Expected Imm=%h, Actual Imm=%h", 
                   $time, instruction, expected_imm, immediate);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting imm_gen Tests ---");

        // I-Type (ADDI x1, x0, 10) -> 00a00093
        drive_imm_gen(32'h00a00093); check_imm_gen(32'd10);
        // I-Type Negative (ADDI x1, x0, -1) -> fff00093
        drive_imm_gen(32'hfff00093); check_imm_gen(32'hffffffff);

        // S-Type (SW x2, 4(x1)) -> 0020a223
        // imm[11:5] = 0000001, imm[4:0] = 00100 -> imm = 32'h4
        drive_imm_gen(32'h0020a223); check_imm_gen(32'h4);
        // S-Type Negative (SW x2, -4(x1)) -> fe20ae23
        drive_imm_gen(32'hfe20ae23); check_imm_gen(32'hfffffffc);

        // B-Type (BEQ x1, x2, 8) -> 00208463
        drive_imm_gen(32'h00208463); check_imm_gen(32'h8);
        // B-Type Negative (BEQ x1, x2, -4) -> fe208ee3
        drive_imm_gen(32'hfe208ee3); check_imm_gen(32'hfffffffc);

        // U-Type (LUI x1, 0x12345) -> 123450b7
        drive_imm_gen(32'h123450b7); check_imm_gen(32'h12345000);

        // J-Type (JAL x1, 4) -> 004000ef
        drive_imm_gen(32'h004000ef); check_imm_gen(32'h4);

        $display("--- imm_gen Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
