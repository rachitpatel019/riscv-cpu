`timescale 1ns/1ps

module regfile_tb;

// Stimulus
logic clk;
// Read
logic [4:0] read_address1; // 5 bits to represent registers 0-31
logic [4:0] read_address2; // 5 bits to represent registers 0-31
logic [31:0] read_data1; // 32 bit register size
logic [31:0] read_data2; // 32 bit register size

// Write
logic [4:0] write_address; // 5 bits to represent registers 0-31
logic [31:0] write_data; // 32 bit register size
logic write_enable; // update registers only when needed

// Initialize stimulus
initial begin
    read_address1 = 0;
    read_address2 = 0;
    write_address = 0;
    write_data = 0;
    write_enable = 0;
end

regfile dut (.*);

// Clock generator
initial clk = 0;
always #5 clk = ~clk;

int test_count = 0;
int fail_count = 0;

task read_test(
    // Ports
    input logic [4:0] readAddress1, // 5 bits to represent registers 0-31
    input logic [4:0] readAddress2, // 5 bits to represent registers 0-31
    input logic [31:0] expectedData1, // expected register value
    input logic [31:0] expectedData2 // expected register value
);
begin
    // Connect stimulus to port
    read_address1 = readAddress1;
    read_address2 = readAddress2;

    #1;
    test_count++;

    // PASS/FAIL logic
    if (read_data1 !== expectedData1) begin
        fail_count++;
        $display("[%0t] FAIL | Expected=%h Got=%h", $time, expectedData1, read_data1);
    end
    if (read_data2 !== expectedData2) begin
        fail_count++;
        $display("[%0t] FAIL | Expected=%h Got=%h", $time, expectedData2, read_data2);
    end
    if ((read_data1 === expectedData1) && (read_data2 === expectedData2))
        $display("[%0t] PASS", $time);
end
endtask

task write_test(
    // Ports
    input logic [4:0] writeAddress, // 5 bits to represent registers 0-31
    input logic [31:0] writeData, // 32 bit register size
    input logic writeEnable // update registers only when needed
);
begin
    // Connect Stimulus to port
    write_address = writeAddress;
    write_data = writeData;
    write_enable = writeEnable;

    @(posedge clk);
    test_count++;

    read_address1 = writeAddress;
    #1;

    // PASS/FAIL logic
    if (read_data1 !== writeData) begin
        if ((writeEnable && (writeAddress  !== 5'b0))) begin
            fail_count++;
            $display("[%0t] FAIL | Expected=%h Got=%h", $time, writeData, read_data1);
        end
        else begin
            $display("[%0t] PASS", $time);
        end
    end
    else begin
        $display("[%0t] PASS", $time);
    end

    write_enable = 1'b0;
end
endtask

// Test cases
initial
    begin
        @(posedge clk);

        // Initial reads
        read_test(5'd0, 5'd1, 32'd0, 32'd0); 
        read_test(5'd5, 5'd7, 32'd0, 32'd0);

        // Basic write
        write_test(5'd1, 32'd56, 1'b1); 
        read_test(5'd1, 5'd0, 32'd56, 32'd0);

        // Multiple writes
        write_test(5'd2, 32'd100, 1'b1); 
        write_test(5'd3, 32'd200, 1'b1);
        read_test(5'd2, 5'd3, 32'd100, 32'd200);

        // Overwrite register
        write_test(5'd4, 32'd10, 1'b1);
        write_test(5'd4, 32'd20, 1'b1);
        read_test(5'd4, 5'd0, 32'd20, 32'd0);

        // Two reads
        write_test(5'd6, 32'd11, 1'b1); 
        write_test(5'd7, 32'd22, 1'b1);
        read_test(5'd6, 5'd7, 32'd11, 32'd22);

        // Write disabled
        write_test(5'd8, 32'd55, 1'b0);
        read_test(5'd8, 5'd0, 32'd0, 32'd0);

        // Writing to register 0
        write_test(5'd0, 32'd999, 1'b1);
        read_test(5'd0, 5'd1, 32'd0, 32'd56);

        // Same register read
        write_test(5'd9, 32'd77, 1'b1); 
        read_test(5'd9, 5'd9, 32'd77, 32'd77);

        // Max register index
        write_test(5'd31, 32'd1234, 1'b1);
        read_test(5'd31, 5'd0, 32'd1234, 32'd0);

        // Testing report
        $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
        $finish;
    end
    
endmodule