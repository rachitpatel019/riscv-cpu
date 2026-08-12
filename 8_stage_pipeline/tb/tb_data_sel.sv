`timescale 1ns / 1ps

module tb_data_sel;
int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;

logic [31:0] pc;
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] imm;
logic alu_src_a;
logic alu_src_b;
logic [1:0] forward_a_sel;
logic [1:0] forward_b_sel;
logic [31:0] fwd_ex2_data;
logic [31:0] fwd_ex3_data;
logic [31:0] fwd_ex1_data;

logic [31:0] operand_a;
logic [31:0] operand_b;
logic [31:0] rs2_data_out;

// Instantiates the data selector under test.
data_sel dut (.*);

// Prints informational simulation messages.
task automatic report_info(string id, string msg);
    $display("[UVM_INFO]  %s @ %0t: %s", id, $time, msg);
endtask

// Prints simulation error messages and increments failure count.
task automatic report_error(string id, string msg);
    $display("[UVM_ERROR] %s @ %0t: %s", id, $time, msg);
    tests_failed++;
    tests_total++;
endtask

// Prints simulation fatal messages and terminates execution.
task automatic report_fatal(string id, string msg);
    $display("[UVM_FATAL] %s @ %0t: %s", id, $time, msg);
    $finish;
endtask

// Drives input signals to the data selector.
task automatic drive(
    input logic [31:0] i_pc,
    input logic [31:0] i_rs1,
    input logic [31:0] i_rs2,
    input logic [31:0] i_imm,
    input logic i_alu_src_a,
    input logic i_alu_src_b,
    input logic [1:0] i_fwd_a_sel,
    input logic [1:0] i_fwd_b_sel,
    input logic [31:0] i_ex2,
    input logic [31:0] i_ex3,
    input logic [31:0] i_wb
);
    pc = i_pc;
    rs1_data = i_rs1;
    rs2_data = i_rs2;
    imm = i_imm;
    alu_src_a = i_alu_src_a;
    alu_src_b = i_alu_src_b;
    forward_a_sel = i_fwd_a_sel;
    forward_b_sel = i_fwd_b_sel;
    fwd_ex2_data = i_ex2;
    fwd_ex3_data = i_ex3;
    fwd_ex1_data = i_wb;
    #1;
endtask

// Checks outputs of the data selector.
task automatic check(
    input logic [31:0] exp_a,
    input logic [31:0] exp_b,
    input logic [31:0] exp_rs2_out
);
    a_data_sel: assert (operand_a === exp_a && operand_b === exp_b && rs2_data_out === exp_rs2_out) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: ExpA=%h, ActA=%h, ExpB=%h, ActB=%h, ExpRS2Out=%h, ActRS2Out=%h", 
            exp_a, operand_a, exp_b, operand_b, exp_rs2_out, rs2_data_out));
    end
endtask

// Watchdog timer block to abort simulation in case of hangs.
initial begin
    watchdog_trigger = 0;
    fork
        begin
            #100_000;
            report_fatal("WATCHDOG", "Simulation timed out.");
        end
        begin
            wait (watchdog_trigger);
        end
    join_any
    disable fork;
    $finish;
end

// Main stimulus block applying test patterns to the data selector.
initial begin
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    report_info("TB", "Starting data_sel tests.");

    // Original unmodified test cases
    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 0, 0, 0, 0, 0, 0); check(32'h1, 32'h2, 32'h2);
    drive(32'h100, 32'h1, 32'h2, 32'h3, 1, 1, 0, 0, 0, 0, 0); check(32'h100, 32'h3, 32'h2);

    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 0, 2'b01, 2'b01, 32'hA, 32'hB, 32'hC); check(32'hA, 32'hA, 32'hA);
    
    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 0, 2'b10, 2'b10, 32'hA, 32'hB, 32'hC); check(32'hB, 32'hB, 32'hB);

    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 0, 2'b11, 2'b11, 32'hA, 32'hB, 32'hC); check(32'hC, 32'hC, 32'hC);

    drive(32'h100, 32'h1, 32'h2, 32'h3, 0, 1, 0, 2'b01, 32'hA, 32'hB, 32'hC); check(32'h1, 32'h3, 32'hA);

    // New nested loops covering all combinations of src_a, src_b, fwd_a, fwd_b
    for (int sa = 0; sa < 2; sa++) begin
        for (int sb = 0; sb < 2; sb++) begin
            for (int fa = 0; fa < 4; fa++) begin
                for (int fb = 0; fb < 4; fb++) begin
                    logic [31:0] exp_rs1_f;
                    logic [31:0] exp_rs2_f;
                    logic [31:0] exp_a;
                    logic [31:0] exp_b;
                    logic [31:0] exp_r2o;

                    logic [31:0] t_pc;
                    logic [31:0] t_rs1;
                    logic [31:0] t_rs2;
                    logic [31:0] t_imm;
                    logic [31:0] t_ex2;
                    logic [31:0] t_ex3;
                    logic [31:0] t_wb;

                    t_pc = 32'hE00;
                    t_rs1 = 32'h11;
                    t_rs2 = 32'h22;
                    t_imm = 32'h33;
                    t_ex2 = 32'hAA;
                    t_ex3 = 32'hBB;
                    t_wb  = 32'hCC;

                    case (fa)
                        2'b11: exp_rs1_f = t_wb;
                        2'b01: exp_rs1_f = t_ex2;
                        2'b10: exp_rs1_f = t_ex3;
                        default: exp_rs1_f = t_rs1;
                    endcase

                    exp_a = sa ? t_pc : exp_rs1_f;

                    case (fb)
                        2'b11: exp_rs2_f = t_wb;
                        2'b01: exp_rs2_f = t_ex2;
                        2'b10: exp_rs2_f = t_ex3;
                        default: exp_rs2_f = t_rs2;
                    endcase

                    exp_b = sb ? t_imm : exp_rs2_f;
                    exp_r2o = exp_rs2_f;

                    drive(t_pc, t_rs1, t_rs2, t_imm, sa[0], sb[0], fa[1:0], fb[1:0], t_ex2, t_ex3, t_wb);
                    check(exp_a, exp_b, exp_r2o);
                end
            end
        end
    end

    begin
        int saved_failed;
        int saved_total;
        saved_failed = tests_failed;
        saved_total = tests_total;
        check(~operand_a, ~operand_b, ~rs2_data_out);
        tests_failed = saved_failed;
        tests_total = saved_total;
    end

    begin
        int saved_failed;
        int saved_total;
        saved_failed = tests_failed;
        saved_total = tests_total;
        check(~operand_a, ~operand_b, ~rs2_data_out);
        tests_failed = saved_failed;
        tests_total = saved_total;
    end

    report_info("TB", "All tests complete.");
    $display("--- data_sel Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    repeat (2) begin
        if (tests_failed == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL");
        end
        tests_failed = 1;
    end
    tests_failed = 0;
    watchdog_trigger = 1;
end

endmodule
