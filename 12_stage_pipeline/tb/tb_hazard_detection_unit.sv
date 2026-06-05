`timescale 1ns / 1ps

module tb_hazard_detection_unit;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [4:0] D_rs1;
    logic [4:0] D_rs2;
    logic D_uses_rs1;
    logic D_uses_rs2;
    
    logic IDRR_mem_read;
    logic [4:0] IDRR_rd;
    
    logic RR_mem_read;
    logic [4:0] RR_rd;
    
    logic E1_mem_read;
    logic [4:0] E1_rd;
    
    logic stall;

    hazard_detection_unit dut (.*);

    task drive_hazard(
        input logic [4:0] i_rs1, input logic [4:0] i_rs2, 
        input logic i_uses_rs1, input logic i_uses_rs2,
        input logic i_idrr_read, input logic [4:0] i_idrr_rd,
        input logic i_rr_read,   input logic [4:0] i_rr_rd,
        input logic i_e1_read,   input logic [4:0] i_e1_rd
    );
        D_rs1 = i_rs1; D_rs2 = i_rs2; 
        D_uses_rs1 = i_uses_rs1; D_uses_rs2 = i_uses_rs2;
        IDRR_mem_read = i_idrr_read; IDRR_rd = i_idrr_rd;
        RR_mem_read = i_rr_read; RR_rd = i_rr_rd;
        E1_mem_read = i_e1_read; E1_rd = i_e1_rd;
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
        drive_hazard(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 0, 0); check_hazard(0);

        // 2. Stage 5 Load-Use Hazard
        drive_hazard(5'd1, 5'd2, 1, 1, 1, 5'd1, 0, 0, 0, 0); check_hazard(1);
        drive_hazard(5'd1, 5'd2, 1, 1, 1, 5'd2, 0, 0, 0, 0); check_hazard(1);

        // 3. Stage 6 Load-Use Hazard
        drive_hazard(5'd1, 5'd2, 1, 1, 0, 0, 1, 5'd1, 0, 0); check_hazard(1);

        // 4. Stage 7 Load-Use Hazard
        drive_hazard(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 1, 5'd2); check_hazard(1);

        // 5. Uses RS2 Filter
        drive_hazard(5'd1, 5'd2, 1, 0, 1, 5'd2, 0, 0, 0, 0); check_hazard(0);

        // 6. Uses RS1 Filter (NEW OPTIMIZATION TEST)
        drive_hazard(5'd1, 5'd2, 0, 1, 1, 5'd1, 0, 0, 0, 0); check_hazard(0);

        // 7. R0 Exemption
        drive_hazard(5'd0, 5'd0, 1, 1, 1, 5'd0, 0, 0, 0, 0); check_hazard(0);

        $display("--- hazard_detection_unit Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
