`timescale 1ns / 1ps

module tb_hazard_detection_unit;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [4:0] D_rs1;
    logic [4:0] D_rs2;
    logic D_uses_rs2;
    logic M1_mem_read;
    logic [4:0] M1_rd;
    logic M_reg_write;
    logic [1:0] M_wb_sel;
    logic [4:0] M_rd;
    logic stall;

    hazard_detection_unit dut (.*);

    task drive_hazard(
        input logic [4:0] i_rs1, input logic [4:0] i_rs2, input logic i_uses_rs2,
        input logic i_m1_read, input logic [4:0] i_m1_rd,
        input logic i_m_write, input logic [1:0] i_m_sel, input logic [4:0] i_m_rd
    );
        D_rs1 = i_rs1; D_rs2 = i_rs2; D_uses_rs2 = i_uses_rs2;
        M1_mem_read = i_m1_read; M1_rd = i_m1_rd;
        M_reg_write = i_m_write; M_wb_sel = i_m_sel; M_rd = i_m_rd;
        #1;
    endtask

    task check_hazard(input logic exp_stall);
        if (stall === exp_stall) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, ExpStall=%b, ActStall=%b", $time, exp_stall, stall);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting hazard_detection_unit Tests ---");

        // 1. No Hazard
        drive_hazard(5'd1, 5'd2, 1, 0, 0, 0, 0, 0); check_hazard(0);

        // 2. Stage 10 Load-Use Hazard
        drive_hazard(5'd1, 5'd2, 1, 1, 5'd1, 0, 0, 0); check_hazard(1);
        drive_hazard(5'd1, 5'd2, 1, 1, 5'd2, 0, 0, 0); check_hazard(1);

        // 3. Stage 11 Load-Use Hazard
        drive_hazard(5'd1, 5'd2, 1, 0, 0, 1, 2'b01, 5'd1); check_hazard(1);

        // 4. Uses RS2 Filter
        drive_hazard(5'd1, 5'd2, 0, 1, 5'd2, 0, 0, 0); check_hazard(0);

        // 5. R0 Exemption
        drive_hazard(5'd0, 5'd0, 1, 1, 5'd0, 0, 0, 0); check_hazard(0);

        $display("--- hazard_detection_unit Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
