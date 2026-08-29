`timescale 1ns / 1ps

module tb_core;
int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;
int core_timeout_cycles;

int cycle_count;
int cycles_run;
int errors_found;

localparam MAX_CYCLES = 500;
localparam CLK_PERIOD = 10;

logic clk;
logic reset;

always #(CLK_PERIOD / 2) clk = ~clk;

wire [31:0] probe_fetch_pc = dut.F_pc;
wire [31:0] probe_alu_result = dut.E2_alu_result;
wire probe_mem_read = dut.E3_mem_read;
wire [31:0] probe_wb_data = dut.W_write_data;
wire [4:0] probe_wb_reg = dut.W_rd;
wire probe_reg_write = dut.W_reg_write;

typedef struct {
    logic [31:0] expected_fetch_pc;
    logic [31:0] expected_alu_result;
    logic expected_mem_read;
    logic [31:0] expected_wb_data;
    logic [4:0] expected_wb_reg;
    logic expected_reg_write;
} cycle_state_t;

cycle_state_t expected_states [0:MAX_CYCLES];

logic [1:0] tb_mmio_keys = 2'b11;
logic [9:0] tb_mmio_switches = 10'b1010101010;
logic [9:0] tb_mmio_leds;
logic [23:0] tb_mmio_hex;

core dut (
    .clk(clk),
    .reset(reset),
    .mmio_keys(tb_mmio_keys),
    .mmio_switches(tb_mmio_switches),
    .mmio_leds(tb_mmio_leds),
    .mmio_hex(tb_mmio_hex),
    .out_pc(),
    .out_writeback_data(),
    .out_reg_write(),
    .out_alu_result()
);

task automatic report_info(string id, string msg);
    $display("[UVM_INFO]  %s @ %0t: %s", id, $time, msg);
endtask

task automatic report_error(string id, string msg);
    $display("[UVM_ERROR] %s @ %0t: %s", id, $time, msg);
    tests_failed++;
    tests_total++;
endtask

task automatic report_fatal(string id, string msg);
    $display("[UVM_FATAL] %s @ %0t: %s", id, $time, msg);
    $finish;
endtask

task automatic reset_dut();
    reset = 1;
    repeat (2) @(posedge clk);
    #1;
    reset = 0;
endtask

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

initial begin
    clk = 0;
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    cycle_count = 0;
    cycles_run = 0;
    errors_found = 0;
    report_info("TB", "Starting core tests.");

    for (int i = 0; i <= MAX_CYCLES; i++) begin
        expected_states[i] = '{
            expected_fetch_pc: i * 4,
            expected_alu_result: 32'h0,
            expected_mem_read: 1'b0,
            expected_wb_data: 32'h0,
            expected_wb_reg: 5'h0,
            expected_reg_write: 1'b0
        };
    end

    expected_states[5].expected_alu_result = 32'h1;
    expected_states[7].expected_wb_data = 32'h1;
    expected_states[7].expected_wb_reg = 5'd1;
    expected_states[7].expected_reg_write = 1'b1;

    expected_states[10].expected_alu_result = 32'h2;
    expected_states[12].expected_wb_data = 32'h2;
    expected_states[12].expected_wb_reg = 5'd2;
    expected_states[12].expected_reg_write = 1'b1;

    expected_states[15].expected_alu_result = 32'h3;
    expected_states[17].expected_wb_data = 32'h3;
    expected_states[17].expected_wb_reg = 5'd3;
    expected_states[17].expected_reg_write = 1'b1;

    for (int i = 0; i <= MAX_CYCLES; i++) begin
        if (i < 43)
            expected_states[i].expected_fetch_pc = i * 4;
        else
            expected_states[i].expected_fetch_pc = 32'hffffffff;
    end

    for (int run = 0; run < 2; run++) begin
        if (run == 0) begin
            core_timeout_cycles = 5;
        end else begin
            core_timeout_cycles = MAX_CYCLES;
        end
        cycle_count = 0;
        cycles_run = 0;
        reset_dut();

        fork
            begin
                repeat (core_timeout_cycles) @(posedge clk);
                report_info("TB", $sformatf("Simulation Timeout (PC at end: %h)", dut.W_pc));
            end
            begin
                wait (cycles_run > 50);
                forever begin
                    @(posedge clk);
                    if (dut.W_pc == 32'h000000fc) break; 
                end
                report_info("TB", $sformatf("Program Completion Detected (PC: %h)", dut.W_pc));
            end
        join_any
        disable fork;
    end

    tests_passed = (errors_found == 0) ? 1 : 0;
    tests_failed = errors_found;
    tests_total = tests_passed + tests_failed;

    report_info("TB", "All tests complete.");
    $display("--- core Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) begin
        $display("RESULT: PASS");
    end else begin
        $display("RESULT: FAIL");
    end
    watchdog_trigger = 1;
end

always @(negedge clk) begin
    a_core_clk_valid: assert (!$isunknown(clk))
        else begin
            report_error("CLK_CHECK", "Clock is unknown!");
            errors_found++;
        end

    if (!reset) begin
        if (cycle_count == 0) begin
            a_reset_pc: assert (dut.F_pc == 32'b0)
                else begin
                    report_error("RESET_CHECK", $sformatf("PC is not 0 after reset: %h", dut.F_pc));
                    errors_found++;
                end
        end

        // Program-independent processor state assertions
        a_F_pc_aligned: assert (dut.F_pc[1:0] == 2'b00)
            else begin
                report_error("PC_CHECK", $sformatf("Fetch PC is not 4-byte aligned: %h", dut.F_pc));
                errors_found++;
            end

        a_D_pc_aligned: assert (dut.D_pc[1:0] == 2'b00)
            else begin
                report_error("PC_CHECK", $sformatf("Decode PC is not 4-byte aligned: %h", dut.D_pc));
                errors_found++;
            end

        a_E1_pc_aligned: assert (dut.E1_pc[1:0] == 2'b00)
            else begin
                report_error("PC_CHECK", $sformatf("EX1 PC is not 4-byte aligned: %h", dut.E1_pc));
                errors_found++;
            end

        a_E2_pc_aligned: assert (dut.E2_pc[1:0] == 2'b00)
            else begin
                report_error("PC_CHECK", $sformatf("EX2 PC is not 4-byte aligned: %h", dut.E2_pc));
                errors_found++;
            end

        a_E3_pc_aligned: assert (dut.E3_pc[1:0] == 2'b00)
            else begin
                report_error("PC_CHECK", $sformatf("EX3 PC is not 4-byte aligned: %h", dut.E3_pc));
                errors_found++;
            end

        a_W_pc_aligned: assert (dut.W_pc[1:0] == 2'b00)
            else begin
                report_error("PC_CHECK", $sformatf("Writeback PC is not 4-byte aligned: %h", dut.W_pc));
                errors_found++;
            end

        a_reg_x0_zero_a: assert (dut.stage4_regfile.registers_a[0] == 32'b0)
            else begin
                report_error("REG_CHECK", "Register File A x0 is not zero!");
                errors_found++;
            end

        a_reg_x0_zero_b: assert (dut.stage4_regfile.registers_b[0] == 32'b0)
            else begin
                report_error("REG_CHECK", "Register File B x0 is not zero!");
                errors_found++;
            end

        a_F_pc_range: assert (dut.F_pc < 16384 * 4)
            else begin
                report_error("PC_CHECK", $sformatf("Fetch PC is out of range: %h", dut.F_pc));
                errors_found++;
            end

        a_dmem_read_addr: assert (!dut.stage8_memory_system.dmem_read || (dut.stage8_memory_system.read_address < 65536))
            else begin
                report_error("MEM_CHECK", $sformatf("Data memory read address out of bounds: %h", dut.stage8_memory_system.read_address));
                errors_found++;
            end

        a_dmem_write_addr: assert (!dut.stage8_memory_system.dmem_write || (dut.stage8_memory_system.write_address < 65536))
            else begin
                report_error("MEM_CHECK", $sformatf("Data memory write address out of bounds: %h", dut.stage8_memory_system.write_address));
                errors_found++;
            end

        // Hazard Stall check: stall_frontend must be active if a load-use hazard occurs
        a_stall_rr_load_use: assert (
            !(dut.hazard_unit.RR_reg_write && dut.hazard_unit.RR_mem_read && (dut.hazard_unit.RR_rd != 5'b0) && 
              ((dut.hazard_unit.RR_rd == dut.D_rs1 && dut.D_uses_rs1) || (dut.hazard_unit.RR_rd == dut.D_rs2 && dut.D_uses_rs2))) 
            || dut.stall_frontend
        ) else begin
            report_error("HAZARD_CHECK", "Frontend failed to stall on Reg-Read load-use hazard!");
            errors_found++;
        end

        a_stall_ex1_load_use: assert (
            !(dut.hazard_unit.E1_reg_write && dut.hazard_unit.E1_mem_read && (dut.hazard_unit.E1_rd != 5'b0) && 
              ((dut.hazard_unit.E1_rd == dut.D_rs1 && dut.D_uses_rs1) || (dut.hazard_unit.E1_rd == dut.D_rs2 && dut.D_uses_rs2))) 
            || dut.stall_frontend
        ) else begin
            report_error("HAZARD_CHECK", "Frontend failed to stall on EX1 load-use hazard!");
            errors_found++;
        end

        // Forwarding unit checks: verify correct select lines for Operand A
        a_forward_a_ex1: assert (
            !(dut.fwd_unit.IDRR_uses_rs1 && (dut.fwd_unit.IDRR_rs1 != 5'b0) && 
              dut.fwd_unit.E1_reg_write && !dut.fwd_unit.E1_mem_read && (dut.fwd_unit.E1_rd == dut.fwd_unit.IDRR_rs1))
            || (dut.IDRR_forward_a_sel == 2'b11)
        ) else begin
            report_error("FORWARD_CHECK", "Forwarding unit failed to select EX1 data for Operand A!");
            errors_found++;
        end

        a_forward_a_ex2: assert (
            !(dut.fwd_unit.IDRR_uses_rs1 && (dut.fwd_unit.IDRR_rs1 != 5'b0) && 
              !(dut.fwd_unit.E1_reg_write && !dut.fwd_unit.E1_mem_read && (dut.fwd_unit.E1_rd == dut.fwd_unit.IDRR_rs1)) &&
              dut.fwd_unit.E2_reg_write && !dut.fwd_unit.E2_mem_read && (dut.fwd_unit.E2_rd == dut.fwd_unit.IDRR_rs1))
            || (dut.IDRR_forward_a_sel == 2'b01)
        ) else begin
            report_error("FORWARD_CHECK", "Forwarding unit failed to select EX2 data for Operand A!");
            errors_found++;
        end

        a_forward_a_ex3: assert (
            !(dut.fwd_unit.IDRR_uses_rs1 && (dut.fwd_unit.IDRR_rs1 != 5'b0) && 
              !(dut.fwd_unit.E1_reg_write && !dut.fwd_unit.E1_mem_read && (dut.fwd_unit.E1_rd == dut.fwd_unit.IDRR_rs1)) &&
              !(dut.fwd_unit.E2_reg_write && !dut.fwd_unit.E2_mem_read && (dut.fwd_unit.E2_rd == dut.fwd_unit.IDRR_rs1)) &&
              dut.fwd_unit.E3_reg_write && (dut.fwd_unit.E3_rd == dut.fwd_unit.IDRR_rs1))
            || (dut.IDRR_forward_a_sel == 2'b10)
        ) else begin
            report_error("FORWARD_CHECK", "Forwarding unit failed to select EX3 data for Operand A!");
            errors_found++;
        end

        // Forwarding unit checks: verify correct select lines for Operand B
        a_forward_b_ex1: assert (
            !(dut.fwd_unit.IDRR_uses_rs2 && (dut.fwd_unit.IDRR_rs2 != 5'b0) && 
              dut.fwd_unit.E1_reg_write && !dut.fwd_unit.E1_mem_read && (dut.fwd_unit.E1_rd == dut.fwd_unit.IDRR_rs2))
            || (dut.IDRR_forward_b_sel == 2'b11)
        ) else begin
            report_error("FORWARD_CHECK", "Forwarding unit failed to select EX1 data for Operand B!");
            errors_found++;
        end

        a_forward_b_ex2: assert (
            !(dut.fwd_unit.IDRR_uses_rs2 && (dut.fwd_unit.IDRR_rs2 != 5'b0) && 
              !(dut.fwd_unit.E1_reg_write && !dut.fwd_unit.E1_mem_read && (dut.fwd_unit.E1_rd == dut.fwd_unit.IDRR_rs2)) &&
              dut.fwd_unit.E2_reg_write && !dut.fwd_unit.E2_mem_read && (dut.fwd_unit.E2_rd == dut.fwd_unit.IDRR_rs2))
            || (dut.IDRR_forward_b_sel == 2'b01)
        ) else begin
            report_error("FORWARD_CHECK", "Forwarding unit failed to select EX2 data for Operand B!");
            errors_found++;
        end

        a_forward_b_ex3: assert (
            !(dut.fwd_unit.IDRR_uses_rs2 && (dut.fwd_unit.IDRR_rs2 != 5'b0) && 
              !(dut.fwd_unit.E1_reg_write && !dut.fwd_unit.E1_mem_read && (dut.fwd_unit.E1_rd == dut.fwd_unit.IDRR_rs2)) &&
              !(dut.fwd_unit.E2_reg_write && !dut.fwd_unit.E2_mem_read && (dut.fwd_unit.E2_rd == dut.fwd_unit.IDRR_rs2)) &&
              dut.fwd_unit.E3_reg_write && (dut.fwd_unit.E3_rd == dut.fwd_unit.IDRR_rs2))
            || (dut.IDRR_forward_b_sel == 2'b10)
        ) else begin
            report_error("FORWARD_CHECK", "Forwarding unit failed to select EX3 data for Operand B!");
            errors_found++;
        end

        // Decoded signals checks for standard R-Type instructions
        a_r_type_decode: assert (
            $isunknown(dut.D_instruction[6:0]) ||
            (dut.D_instruction[6:0] != 7'b0110011) ||
            (dut.D_uses_rs1 && dut.D_uses_rs2 && !dut.D_alu_src_a && !dut.D_alu_src_b && dut.D_reg_write)
        ) else begin
            report_error("DECODE_CHECK", $sformatf("R-Type instruction decoded with incorrect control signals: opcode=%b", dut.D_instruction[6:0]));
            errors_found++;
        end
    end

    if (!reset) begin
        cycle_count++;
        cycles_run++;
    end
end
endmodule
