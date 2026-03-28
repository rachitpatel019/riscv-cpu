`timescale 1ns/1ps

module fetch_tb;

// DUT Signals
logic clk;
logic reset;
logic [31:0] pc;
logic [31:0] instruction;

fetch dut (.*);

// Clock generator
initial clk = 0;
always #5 clk = ~clk;

int test_count = 0;
int fail_count = 0;

task test_fetch(
    input logic Reset,
    input logic [31:0] expectedPC,
    input logic [31:0] expectedInstr
);
begin
    // Connect stimulus to port
    reset = Reset;
    @(posedge clk);

    if (pc === expectedPC) begin
        test_count++;
        $display("[%0t] PASS PC: %d", $time, pc);
    end
    else begin
        test_count++;
        fail_count++;
        $display("[%0t] FAIL PC Got: %d | Expected: %d", $time, pc, expectedPC);
    end

    if (instruction === expectedInstr) begin
        test_count++;
        $display("[%0t] PASS Instruction: %h", $time, instruction);
    end
    else begin
        test_count++;
        fail_count++;
        $display("[%0t] FAIL Instruction: Got: %h | Expected: %h", $time, instruction, expectedInstr);
    end
end    
endtask

initial begin
    test_fetch(1'b1, 32'bx, 32'bx);
    test_fetch(1'b0, 32'd0, 32'h00500093);
    test_fetch(1'b0, 32'd4, 32'h00108133);
    test_fetch(1'b0, 32'd8, 32'h00202023);
    test_fetch(1'b0, 32'd12, 32'h0);
    test_fetch(1'b0, 32'd16, 32'h0);
    test_fetch(1'b1, 32'd20, 32'h0);
    test_fetch(1'b0, 32'd0, 32'h00500093);
    test_fetch(1'b0, 32'd4, 32'h00108133);
    test_fetch(1'b1, 32'd8, 32'h00202023);
    test_fetch(1'b0, 32'd0, 32'h00500093);
    test_fetch(1'b1, 32'd4, 32'h00108133);
    test_fetch(1'b1, 32'd0, 32'h00500093);
    test_fetch(1'b1, 32'd0, 32'h00500093);
    test_fetch(1'b0, 32'd0, 32'h00500093);
    test_fetch(1'b1, 32'd4, 32'h00108133);
    test_fetch(1'b0, 32'd0, 32'h00500093);

    // Testing report
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    $finish;
end

endmodule