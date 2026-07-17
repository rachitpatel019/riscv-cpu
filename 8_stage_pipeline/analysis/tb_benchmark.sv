`timescale 1ns / 1ps

module tb_benchmark;

localparam CLK_PERIOD = 10;
localparam MAX_CYCLES = 150000;

logic clk;
logic reset;

always #(CLK_PERIOD / 2) clk = ~clk;

// MMIO dummy signals
logic [1:0] tb_mmio_keys = 2'b11;
logic [9:0] tb_mmio_switches = 10'b0;
logic [9:0] tb_mmio_leds;
logic [23:0] tb_mmio_hex;

// Instantiate the CPU core
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

// Performance tracking variables
logic benchmark_active;
logic started;

always @(posedge clk) begin
    if (reset) begin
        benchmark_active <= 0;
        started <= 0;
    end else begin
        // Monitor writes to MMIO LEDs (0x80000000)
        if (dut.stage8_memory_system.mmio_inst.mem_write && 
            dut.stage8_memory_system.mmio_inst.write_address == 32'h80000000) begin
            if (dut.stage8_memory_system.mmio_inst.write_data[9:0] == 10'h3FF) begin
                benchmark_active <= 1;
                started <= 1;
            end else if (dut.stage8_memory_system.mmio_inst.write_data[9:0] == 10'h000) begin
                benchmark_active <= 0;
            end
        end
    end
end

// Track retired instructions
logic [31:0] last_retired_pc;
logic [31:0] inst_retired;
logic inst_retiring;

assign inst_retired = dut.stage2_imem.instruction_memory[dut.W_pc[31:2]];
assign inst_retiring = !reset && benchmark_active && (dut.W_pc != last_retired_pc) && (dut.W_pc != 32'b0);

always @(posedge clk) begin
    if (reset) begin
        last_retired_pc <= 32'b0;
    end else if (inst_retiring) begin
        last_retired_pc <= dut.W_pc;
    end
end

// Decode Retired Instruction Fields
logic [6:0] opcode;
logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;
logic uses_rs1;
logic uses_rs2;

assign opcode = inst_retired[6:0];
assign rd = inst_retired[11:7];
assign rs1 = inst_retired[19:15];
assign rs2 = inst_retired[24:20];

// Basic opcode classifications
logic is_alu;
logic is_load;
logic is_store;
logic is_branch;
logic is_jump;

assign is_alu    = (opcode == 7'b0110011) || (opcode == 7'b0010011) || (opcode == 7'b0110111) || (opcode == 7'b0010111);
assign is_load   = (opcode == 7'b0000011);
assign is_store  = (opcode == 7'b0100011);
assign is_branch = (opcode == 7'b1100011);
assign is_jump   = (opcode == 7'b1101111) || (opcode == 7'b1100111);

// Register usage classification
assign uses_rs1 = (opcode == 7'b0110011) || (opcode == 7'b0010011) || (opcode == 7'b0000011) || (opcode == 7'b0100011) || (opcode == 7'b1100011) || (opcode == 7'b1100111);
assign uses_rs2 = (opcode == 7'b0110011) || (opcode == 7'b0100011) || (opcode == 7'b1100011);

// Sliding history window for retired instructions (to detect dependencies)
typedef struct packed {
    logic valid;
    logic [4:0] rd;
    logic is_load;
    logic is_alu;
} inst_history_t;

inst_history_t history [0:3];

always @(posedge clk) begin
    if (reset) begin
        history[0] <= '{default: 0};
        history[1] <= '{default: 0};
        history[2] <= '{default: 0};
        history[3] <= '{default: 0};
    end else if (inst_retiring) begin
        history[0] <= '{valid: 1'b1, rd: rd, is_load: is_load, is_alu: is_alu};
        history[1] <= history[0];
        history[2] <= history[1];
        history[3] <= history[2];
    end
end

// Counters
longint cycle_count;
longint retired_count;
longint stall_cycles;

longint alu_count;
longint load_count;
longint store_count;
longint jump_count;
longint branch_count;

// Dependency counters
longint alu_b2b_stalls;
longint alu_1gap_stalls;
longint load_b2b_stalls;
longint load_1gap_stalls;
longint load_2gap_stalls;
longint load_3gap_stalls;

// Branch predictor statistics
longint branches_resolved;
longint branches_taken;
longint branches_not_taken;
longint branches_correct;
longint branches_mispredicted;

// Bubble tracking pipeline for direct measurement of control hazards
typedef enum logic [1:0] {
    BUBBLE_NONE,
    BUBBLE_STALL,
    BUBBLE_BRANCH,
    BUBBLE_JUMP
} bubble_t;

bubble_t pipe_D;
bubble_t pipe_RR;
bubble_t pipe_EX1;
bubble_t pipe_EX2;
bubble_t pipe_EX3;
bubble_t pipe_WB;

longint measured_branch_penalty_cycles;
longint measured_jump_penalty_cycles;

always @(posedge clk) begin
    if (reset) begin
        pipe_D   <= BUBBLE_NONE;
        pipe_RR  <= BUBBLE_NONE;
        pipe_EX1 <= BUBBLE_NONE;
        pipe_EX2 <= BUBBLE_NONE;
        pipe_EX3 <= BUBBLE_NONE;
        pipe_WB  <= BUBBLE_NONE;
        measured_branch_penalty_cycles <= 0;
        measured_jump_penalty_cycles <= 0;
    end else if (benchmark_active) begin
        logic stage7_branch_mispredict;
        logic stage7_jump;
        logic stage4_branch_taken;
        logic stage4_jump;

        stage7_branch_mispredict = dut.E3_branch && (dut.E3_condition_met != dut.E3_predict_taken);
        stage7_jump = dut.E3_jump;
        stage4_branch_taken = dut.IDRR_branch && dut.IDRR_predict_taken;
        stage4_jump = dut.IDRR_is_jal;

        // Shift Stage 7 to WB
        pipe_WB <= pipe_EX3;

        // Shift Stage 6 to EX3
        if (dut.flush) begin
            if (stage7_jump) pipe_EX3 <= BUBBLE_JUMP;
            else             pipe_EX3 <= BUBBLE_BRANCH;
        end else begin
            pipe_EX3 <= pipe_EX2;
        end

        // Shift Stage 5 to EX2
        if (dut.flush) begin
            if (stage7_jump) pipe_EX2 <= BUBBLE_JUMP;
            else             pipe_EX2 <= BUBBLE_BRANCH;
        end else begin
            pipe_EX2 <= pipe_EX1;
        end

        // Shift Stage 4 to EX1
        if (dut.flush) begin
            if (stage7_jump) pipe_EX1 <= BUBBLE_JUMP;
            else             pipe_EX1 <= BUBBLE_BRANCH;
        end else begin
            pipe_EX1 <= pipe_RR;
        end

        // Shift Stage 3 to RR
        if (dut.flush) begin
            if (stage7_jump) pipe_RR <= BUBBLE_JUMP;
            else             pipe_RR <= BUBBLE_BRANCH;
        end else if (dut.stage4_flush) begin
            if (stage4_jump) pipe_RR <= BUBBLE_JUMP;
            else             pipe_RR <= BUBBLE_BRANCH;
        end else if (dut.stall_frontend) begin
            pipe_RR <= BUBBLE_STALL;
        end else begin
            pipe_RR <= pipe_D;
        end

        // Shift Stage 2 to D
        if (dut.flush) begin
            if (stage7_jump) pipe_D <= BUBBLE_JUMP;
            else             pipe_D <= BUBBLE_BRANCH;
        end else if (dut.stage4_flush) begin
            if (stage4_jump) pipe_D <= BUBBLE_JUMP;
            else             pipe_D <= BUBBLE_BRANCH;
        end else if (dut.stall_frontend) begin
            pipe_D <= pipe_D; // Held on stall
        end else begin
            pipe_D <= BUBBLE_NONE;
        end

        // Accumulate penalty cycles at the Writeback stage
        if (pipe_WB == BUBBLE_BRANCH) begin
            measured_branch_penalty_cycles <= measured_branch_penalty_cycles + 1;
        end else if (pipe_WB == BUBBLE_JUMP) begin
            measured_jump_penalty_cycles <= measured_jump_penalty_cycles + 1;
        end
    end
end

always @(posedge clk) begin
    if (!reset && benchmark_active) begin
        cycle_count <= cycle_count + 1;

        if (dut.stall_frontend) begin
            stall_cycles <= stall_cycles + 1;
        end

        if (inst_retiring) begin
            retired_count <= retired_count + 1;

            if (is_alu)    alu_count   <= alu_count + 1;
            if (is_load)   load_count  <= load_count + 1;
            if (is_store)  store_count <= store_count + 1;
            if (is_jump)   jump_count  <= jump_count + 1;
            if (is_branch) branch_count<= branch_count + 1;

            // ALU Dependency Analysis (only if current instruction is ALU)
            if (is_alu) begin
                // Back-to-back ALU hazard (stall of 2 cycles)
                if (history[0].valid && history[0].is_alu && history[0].rd != 0 &&
                    ((uses_rs1 && rs1 == history[0].rd) || (uses_rs2 && rs2 == history[0].rd))) begin
                    alu_b2b_stalls <= alu_b2b_stalls + 1;
                end
                // 1-instruction gap ALU hazard (stall of 1 cycle)
                else if (history[1].valid && history[1].is_alu && history[1].rd != 0 &&
                         ((uses_rs1 && rs1 == history[1].rd) || (uses_rs2 && rs2 == history[1].rd))) begin
                    alu_1gap_stalls <= alu_1gap_stalls + 1;
                end
            end

            // Load-Use Dependency Analysis
            if (uses_rs1 || uses_rs2) begin
                // Back-to-back Load-Use hazard (stall of 4 cycles)
                if (history[0].valid && history[0].is_load && history[0].rd != 0 &&
                    ((uses_rs1 && rs1 == history[0].rd) || (uses_rs2 && rs2 == history[0].rd))) begin
                    load_b2b_stalls <= load_b2b_stalls + 1;
                end
                // 1-instruction gap Load-Use hazard (stall of 3 cycles)
                else if (history[1].valid && history[1].is_load && history[1].rd != 0 &&
                         ((uses_rs1 && rs1 == history[1].rd) || (uses_rs2 && rs2 == history[1].rd))) begin
                    load_1gap_stalls <= load_1gap_stalls + 1;
                end
                // 2-instruction gap Load-Use hazard (stall of 2 cycles)
                else if (history[2].valid && history[2].is_load && history[2].rd != 0 &&
                         ((uses_rs1 && rs1 == history[2].rd) || (uses_rs2 && rs2 == history[2].rd))) begin
                    load_2gap_stalls <= load_2gap_stalls + 1;
                end
                // 3-instruction gap Load-Use hazard (stall of 1 cycle)
                else if (history[3].valid && history[3].is_load && history[3].rd != 0 &&
                         ((uses_rs1 && rs1 == history[3].rd) || (uses_rs2 && rs2 == history[3].rd))) begin
                    load_3gap_stalls <= load_3gap_stalls + 1;
                end
            end
        end

        // Branch predictor performance (monitored at stage 7 EX3/MEM)
        if (!dut.stall_frontend && dut.E3_branch) begin
            branches_resolved <= branches_resolved + 1;
            if (dut.E3_condition_met) branches_taken <= branches_taken + 1;
            else branches_not_taken <= branches_not_taken + 1;

            if (dut.E3_condition_met == dut.E3_predict_taken) begin
                branches_correct <= branches_correct + 1;
            end else begin
                branches_mispredicted <= branches_mispredicted + 1;
            end
        end
    end
end

// Simulation control
initial begin
    clk = 0;
    reset = 1;
    #100;
    reset = 0;
end

// Watchdog
initial begin
    #(CLK_PERIOD * MAX_CYCLES);
    $display("[TB ERROR] Simulation timeout!");
    $finish;
end

// Termination and Report
always @(posedge clk) begin
    if (started && !benchmark_active) begin
        $display("\n==================================================");
        $display("BENCHMARK EXECUTION COMPLETED");
        $display("==================================================");
        $display("Total Execution Cycles: %0d", cycle_count);
        $display("Total Retired Instructions: %0d", retired_count);
        $display("Overall CPI: %f", real'(cycle_count) / real'(retired_count));
        $display("Overall IPC: %f", real'(retired_count) / real'(cycle_count));
        $display("Total Stall Cycles: %0d (%f%% of total cycles)", stall_cycles, (real'(stall_cycles)/real'(cycle_count))*100.0);
        $display("--------------------------------------------------");
        $display("Instruction Mix:");
        $display("  ALU:          %0d (%f%%)", alu_count, (real'(alu_count)/real'(retired_count))*100.0);
        $display("  Loads:        %0d (%f%%)", load_count, (real'(load_count)/real'(retired_count))*100.0);
        $display("  Stores:       %0d (%f%%)", store_count, (real'(store_count)/real'(retired_count))*100.0);
        $display("  Jumps:        %0d (%f%%)", jump_count, (real'(jump_count)/real'(retired_count))*100.0);
        $display("  Branches:     %0d (%f%%)", branch_count, (real'(branch_count)/real'(retired_count))*100.0);
        $display("--------------------------------------------------");
        $display("Data Hazard Dependency Stalls:");
        $display("  ALU Back-to-Back (2 cycles):      %0d", alu_b2b_stalls);
        $display("  ALU 1-Instruction Gap (1 cycle):  %0d", alu_1gap_stalls);
        $display("  Load Back-to-Back (4 cycles):     %0d", load_b2b_stalls);
        $display("  Load 1-Instruction Gap (3 cycles): %0d", load_1gap_stalls);
        $display("  Load 2-Instruction Gap (2 cycles): %0d", load_2gap_stalls);
        $display("  Load 3-Instruction Gap (1 cycle):  %0d", load_3gap_stalls);
        $display("--------------------------------------------------");
        $display("Branch Predictor Metrics:");
        $display("  Branches Resolved:      %0d", branches_resolved);
        $display("  Branches Taken:         %0d (%f%%)", branches_taken, (real'(branches_taken)/real'(branches_resolved))*100.0);
        $display("  Branches Not Taken:     %0d (%f%%)", branches_not_taken, (real'(branches_not_taken)/real'(branches_resolved))*100.0);
        $display("  Predictor Correct:      %0d (%f%% accuracy)", branches_correct, (real'(branches_correct)/real'(branches_resolved))*100.0);
        $display("  Predictor Mispredicted: %0d (%f%% error)", branches_mispredicted, (real'(branches_mispredicted)/real'(branches_resolved))*100.0);
        if (branches_resolved > 0) begin
            $display("  Measured Average Branch Penalty: %f cycles", real'(measured_branch_penalty_cycles) / real'(branches_resolved));
        end else begin
            $display("  Measured Average Branch Penalty: 0.000000 cycles");
        end
        $display("  Measured Total Branch Penalty:   %0d cycles", measured_branch_penalty_cycles);
        $display("  Measured Total Jump Penalty:     %0d cycles", measured_jump_penalty_cycles);
        $display("==================================================");
        $finish;
    end
end

endmodule
