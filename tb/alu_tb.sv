// TODO: enumerize control signals

`timescale 10ns/10ns

module alu_tb;
    logic [31:0] A;
    logic [31:0] B;
    logic [3:0]  control;
    logic [31:0] result;

    alu dut (.*);

    int test_count = 0;
    int fail_count = 0;

    task run_test(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [3:0] ctrl,
        input logic [31:0] expected
    );
    begin
        A = a;
        B = b;
        control = ctrl;
        #1;

        test_count++;
        if (result !== expected) begin
            fail_count++;
            $display("FAIL: A=%h B=%h CTRL=%b | Expected=%h Got=%h", a, b, ctrl, expected, result);
        end
        else
            $display("[%0t] PASS: A=%h B=%h CTRL=%b Result=%h", $time, a, b, ctrl, result);
    end
    endtask

    initial
        begin
            #1;
            run_test(10, 5, 4'b0000, 15);
            run_test(10, 3, 4'b0001, 7);
            $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
            $finish;
        end
endmodule