`timescale 1ns/1ps

module fetch_tb;

logic clk;
logic reset;
logic [31:0] pc;
logic [31:0] instruction;

fetch dut (.*);

initial clk = 0;
always #5 clk = ~clk;

int test_count = 0;
int fail_count = 0;

// -----------------------------
// TASK
// -----------------------------
task test_fetch(
    input logic [31:0] expectedPC,
    input logic [31:0] expectedInstr
);
begin
    #1; // wait 1ns to let combinational logic settle in the CURRENT cycle

    if (pc !== expectedPC) begin
        fail_count++;
        $display("[%0t] FAIL PC: Got %0d | Expected %0d", $time, pc, expectedPC);
    end else begin
        $display("[%0t] PASS PC: %0d", $time, pc);
    end
    test_count++;

    if (instruction !== expectedInstr) begin
        fail_count++;
        $display("[%0t] FAIL Instruction: Got %h | Expected %h",
                 $time, instruction, expectedInstr);
    end else begin
        $display("[%0t] PASS Instruction: %h", $time, instruction);
    end
    test_count++;
    
    @(posedge clk); // NOW move to the next clock cycle for the next test
end
endtask

// -----------------------------
// MAIN
// -----------------------------
initial begin

    // -------------------------
    // RESET PHASE
    // -------------------------
    reset = 1;
    repeat (2) @(posedge clk);

    reset = 0;

    // REMOVED the extra repeat(2) delay here. The PC initialized to 0 during the reset. 
    // If we wait extra clocks while reset=0, the PC will continuously advance.

    // -------------------------
    // TEST PROGRAM (ALIGNED)
    // -------------------------
    test_fetch(32'd0,  32'h00a00093);
    test_fetch(32'd4,  32'h01400113);
    test_fetch(32'd8,  32'h002081b3);
    test_fetch(32'd12, 32'h00302023);
    test_fetch(32'd16, 32'h00002203);
    test_fetch(32'd20, 32'h00000000);

    // -------------------------
    // REPORT
    // -------------------------
    $display("\n========================");
    $display("Tests Run   : %0d", test_count);
    $display("Failures    : %0d", fail_count);
    $display("========================");

    $finish;
end

endmodule