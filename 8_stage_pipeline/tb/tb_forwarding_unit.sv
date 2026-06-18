`timescale 1ns / 1ps

module tb_forwarding_unit;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [4:0]  IDRR_rs1;
    logic [4:0]  IDRR_rs2;
    logic        IDRR_uses_rs1;
    logic        IDRR_uses_rs2;

    logic        E2_reg_write;
    logic        E2_mem_read;
    logic [4:0]  E2_rd;

    logic        E3_reg_write;
    logic [4:0]  E3_rd;

    logic [1:0]  forward_a_sel;
    logic [1:0]  forward_b_sel;

    forwarding_unit dut (.*);

    task drive_fwd(
        input logic [4:0] i_rs1, input logic [4:0] i_rs2,
        input logic i_uses_rs1, input logic i_uses_rs2,
        input logic i_e2_en, input logic i_e2_read, input logic [4:0] i_e2_rd,
        input logic i_e3_en, input logic [4:0] i_e3_rd
    );
        IDRR_rs1 = i_rs1; IDRR_rs2 = i_rs2;
        IDRR_uses_rs1 = i_uses_rs1; IDRR_uses_rs2 = i_uses_rs2;
        E2_reg_write = i_e2_en; E2_mem_read = i_e2_read; E2_rd = i_e2_rd;
        E3_reg_write = i_e3_en; E3_rd = i_e3_rd;
        #1;
    endtask

    task check_fwd(input logic [1:0] exp_a_sel, input logic [1:0] exp_b_sel);
        if (forward_a_sel === exp_a_sel && forward_b_sel === exp_b_sel) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, ExpA_sel=%b, ActA_sel=%b, ExpB_sel=%b, ActB_sel=%b",
                   $time, exp_a_sel, forward_a_sel, exp_b_sel, forward_b_sel);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting forwarding_unit Tests (8-Stage Balanced Optimized Phase 1) ---");

        // 1. Priority 1 (E2 -> S7)
        // IDRR_uses_rs1=1, E2 matches RS1 -> forward_a_sel=2'b01
        drive_fwd(5'd1, 5'd2, 1, 1, 1, 0, 5'd1, 0, 5'd0); check_fwd(2'b01, 2'b00);

        // 2. WB Stage Forwarding (E3 -> S8)
        // IDRR_uses_rs1=1, E3 matches RS1 -> forward_a_sel=2'b10
        drive_fwd(5'd1, 5'd2, 1, 1, 0, 0, 0, 1, 5'd1); check_fwd(2'b10, 2'b00);

        // 3. R0 Exemption
        drive_fwd(5'd0, 5'd0, 1, 1, 1, 0, 5'd0, 0, 0); check_fwd(2'b00, 2'b00);

        // 4. Uses RS1/RS2 Filter
        drive_fwd(5'd1, 5'd2, 0, 0, 1, 0, 5'd1, 0, 0); check_fwd(2'b00, 2'b00);

        // 5. Mem Read Blocking (Load-Use) - Should NOT forward if Mem Read in E2
        drive_fwd(5'd1, 5'd2, 1, 1, 1, 1, 5'd1, 0, 0); check_fwd(2'b00, 2'b00);

        $display("--- forwarding_unit Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
