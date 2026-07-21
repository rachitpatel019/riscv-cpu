# 8-Stage Pipeline CPU Technical Report

This document summarizes the timing, resource, performance, hazard, and efficiency metrics of the **8-Stage Pipeline RISC-V CPU** on an Intel MAX 10 FPGA (device `10M50DAF484C7G`).

---

## Executive Summary

The 8-Stage Pipeline RISC-V CPU is a high-performance, single-issue, in-order processor implementing the RV32I base integer instruction set. Designed specifically for FPGA deployment, the architecture divides the standard 5-stage RISC-V pipeline into 8 stages. This optimization reduces the combinational logic depth per stage, yielding a high maximum clock frequency ($F_{\text{max}}$) of **127.29 MHz** on the Intel MAX 10 FPGA.

Key metrics of the hardware and workload evaluation include:
*   **Clock Frequency ($F_{\text{max}}$):** 127.29 MHz
*   **Performance:** 84.78 MIPS (at 0.666 IPC / 1.5015 CPI)
*   **Power Consumption:** 169.75 mW total power (90.38 mW static, 79.37 mW dynamic)
*   **FPGA Logic Utilization:** 2,931 / 49,760 Logic Elements (6%)
*   **Memory Footprint:** 1,052,672 bits of block RAM (63% BRAM capacity)
*   **Branch Predictor Accuracy:** 84.65% (using a 1024-entry 2-bit BHT)
*   **RV32I Compliance:** Fully compliant with the RV32I base user-level instruction set (excluding privileged modes, CSRs, exceptions, and hardware multiply/divide).

---

## Design Goals

The core design objectives for this processor are:
1.  **Maximize Frequency:** Achieve a high operating frequency ($F_{\text{max}} > 100\text{ MHz}$) on low-cost FPGAs by splitting stages and calculating branch targets early.
2.  **Minimize FPGA resource utilization:** Keep Logic Element (LE) count low to preserve resources for other system components.
3.  **Infer BRAM everywhere:** Efficiently map both instruction memory, data memory, register file, and branch history table to block RAM cells (M9K blocks) rather than utilizing logic-based registers.
4.  **Maintain RV32I compatibility:** Target full compatibility with standard compiler toolchains generating RV32I binaries.
5.  **Evaluate realistic workloads:** Measure performance on a benchmark simulating realistic memory access, pointer-chasing, and branch patterns.

---

## Supported ISA

> Implements the complete RV32I base ISA.

*Refer to the Architecture Specification for detailed instruction tables, decoding, and control signals.*

---

## Workload Description

The CPU performance is evaluated against the bare-metal workload in [benchmark.c](../software/Benchmark/benchmark.c). The benchmark runs for 10 iterations of:
1.  **Dynamic Initialization:** Seeds and uses a software-implemented Xorshift32 PRNG (multiplication- and division-free) to populate memory arrays and list nodes.
2.  **Loop A (Array processing):** Performs mathematical transformation chains on array elements. It features a deep sequential dependency chain of back-to-back operations to test register forwarding and load-use stalls.
3.  **Loop B (Linked-list walk):** Walks a dynamically allocated linked list. This exercises pointer-chasing load-use hazards (loading `node->next` and checking pointer alignment) and conditional branching on pseudo-random values to challenge the branch predictor.
4.  **System Interaction:** Writes to the board's MMIO LEDs (`0x80000000`) to signal the start (`0x3FF`) and end (`0x000`) of the workload execution.

---

## Experimental Methodology

The benchmark software is compiled bare-metal using the RISC-V GCC toolchain with the following parameters:

*   **Compiler Version:** `riscv64-unknown-elf-gcc (14.2.0+19) 14.2.0`
*   **Optimization & Code Generation Flags:** `-march=rv32i -mabi=ilp32 -nostdlib -O3 -flto -fsched-pressure -fno-align-loops -fno-align-jumps -fno-align-functions -mtune=rocket`

### Rationales for Optimization Flags
*   **`-O3`:** Enforces aggressive compiler optimization, including loop unrolling and function inlining, which maximizes processing performance.
*   **`-flto` (Link-Time Optimization):** Enables inter-procedural optimizations across all files, aggressively eliminating dead code and reducing subroutine call/jump overheads.
*   **`-fsched-pressure`:** Guides the instruction scheduler to avoid allocating registers beyond the hardware limit, preventing register spills to memory. This keeps load/store instructions minimal.
*   **`-fno-align-*` (Loops, Jumps, Functions):** Prevents the compiler from inserting NOP padding instructions to align jump/branch targets. This keeps the binary footprint small and saves clock cycles that would be wasted executing NOPs.
*   **`-mtune=rocket`:** Tunes the pipeline instruction scheduling to target standard single-issue in-order RISC-V designs.

---

## 1. Physical Synthesis & Power Metrics

These physical specifications represent the synthesized gate-level netlist of the hardware. They remain identical across all software workloads.

| Metric | Value | Reference |
| :--- | :--- | :--- |
| **Clock Frequency ($F_{\text{max}}$)** | **127.29 MHz** ($T_{\text{clk}} = 7.856\text{ ns}$) | Clock constraint in [cpu.sdc](../fpga/cpu.sdc) |
| **Logic Utilization** | **2,931 / 49,760 LEs** (6%) | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **Register Usage** | **1,303 registers** | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **BRAM Usage** | **1,052,672 bits** (63% capacity) | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **Static Power** | **90.38 mW** | [cpu.pow.rpt](../fpga/output_files/cpu.pow.rpt) |
| **Dynamic Power** | **79.37 mW** (69.15 mW Block + 10.22 mW Routing) | [cpu.pow.rpt](../fpga/output_files/cpu.pow.rpt) |
| **Total Power** | **169.75 mW** | [cpu.pow.rpt](../fpga/output_files/cpu.pow.rpt) |

### Design Version Comparison
The table below compares the active 8-Stage Pipeline processor against previous iterations of the RISC-V CPU design:

| Design Version | Clock Frequency ($F_{\text{max}}$) | Logic Elements (LEs) | Registers | IMEM Capacity | DMEM Capacity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Single Cycle** | ~48 MHz | 10,587 | 8,522 | 1 KiB (256 words) | 1 KiB (256 words) |
| **5-Stage Pipeline (LUT-based memory)** | ~92 MHz | 11,262 | 8,817 | 1 KiB (256 words) | 1 KiB (256 words) |
| **5-Stage Pipeline (BRAM-based memory)** | ~70 MHz | 1,828 | 393 | 1 KiB (256 words) | 1 KiB (256 words) |
| **8-Stage Pipeline (Active)** | **127.29 MHz** | **2,931** | **1,303** | **64 KiB (16,384 words)** | **64 KiB (16,384 words)** |

<div align="center" style="margin: 20px 0;">
<svg width="100%" height="240" viewBox="0 0 650 240" fill="none" xmlns="http://www.w3.org/2000/svg" style="background:#1e293b; border-radius:8px; border:1px solid #475569; font-family: sans-serif;">
<!-- Title -->
<text x="20" y="35" fill="#38bdf8" font-size="14" font-weight="bold">Maximum Operating Frequency (Fmax) Scaling</text>
<!-- Grid Lines -->
<line x1="220" y1="60" x2="220" y2="200" stroke="#475569" stroke-width="1" />
<line x1="345" y1="60" x2="345" y2="200" stroke="#334155" stroke-dasharray="4" />
<line x1="470" y1="60" x2="470" y2="200" stroke="#334155" stroke-dasharray="4" />
<line x1="595" y1="60" x2="595" y2="200" stroke="#334155" stroke-dasharray="4" />
<text x="220" y="215" fill="#94a3b8" font-size="10" text-anchor="middle">0 MHz</text>
<text x="345" y="215" fill="#94a3b8" font-size="10" text-anchor="middle">50 MHz</text>
<text x="470" y="215" fill="#94a3b8" font-size="10" text-anchor="middle">100 MHz</text>
<text x="595" y="215" fill="#94a3b8" font-size="10" text-anchor="middle">150 MHz</text>
<!-- Bar 1: Single Cycle -->
<text x="20" y="85" fill="#e2e8f0" font-size="12" font-weight="600">Single Cycle</text>
<rect x="220" y="72" width="120" height="20" rx="3" fill="#64748b" />
<text x="340" y="86" fill="#cbd5e1" font-size="11" font-weight="bold" dx="5">48 MHz</text>
<!-- Bar 2: 5-Stage (BRAM-based) -->
<text x="20" y="120" fill="#e2e8f0" font-size="12" font-weight="600">5-Stage (BRAM-based memory)</text>
<rect x="220" y="107" width="175" height="20" rx="3" fill="#475569" />
<text x="395" y="121" fill="#cbd5e1" font-size="11" font-weight="bold" dx="5">70 MHz</text>
<!-- Bar 3: 5-Stage (LUT-based) -->
<text x="20" y="155" fill="#e2e8f0" font-size="12" font-weight="600">5-Stage (LUT-based memory)</text>
<rect x="220" y="142" width="230" height="20" rx="3" fill="#0284c7" />
<text x="450" y="156" fill="#cbd5e1" font-size="11" font-weight="bold" dx="5">92 MHz</text>
<!-- Bar 4: 8-Stage (Active) -->
<text x="20" y="190" fill="#38bdf8" font-size="12" font-weight="bold">8-Stage (Active)</text>
<rect x="220" y="177" width="318.2" height="20" rx="3" fill="#38bdf8" />
<text x="538.2" y="191" fill="#38bdf8" font-size="11" font-weight="bold" dx="5">127.29 MHz</text>
</svg>
</div>

---

## 2. Timing & Critical Path Analysis

The propagation delays across the pipeline stage boundaries are evaluated via post-place-and-route static timing analysis. The automated script [timing_analysis.tcl](../fpga/timing_analysis.tcl) parses these boundary registers in the design database.

### Per-Stage Propagation Delays
| Stage | Stage Name | Data Delay | Note / Description |
| :--- | :--- | :--- | :--- |
| **Stage 1** | Fetch Logic | 6.759 ns | Includes branch feedback path from Stage 7 |
| **Stage 2** | I-Mem Read | 5.679 ns | BRAM synchronous read latency dominates |
| **Stage 3** | Decode & Hazard | 6.965 ns | Decode combinational logic plus hazard detection |
| **Stage 4** | Register Read | 5.033 ns | Forwarding unit combinational logic |
| **Stage 5** | EX1 (Op Sel) | 5.329 ns | Operand selection mux chain |
| **Stage 6** | **EX2 (ALU)** | **7.146 ns** | **Critical stage: longest combinational delay** |
| **Stage 7** | EX3 & MEM Addr | 5.062 ns | PC target calculation and memory address |
| **Stage 8** | WB Logic | 5.573 ns | Write-back mux to register file write port |

### Critical Path Analysis
*   **Worst setup path slack:** **0.066 ns** (Data delay of **7.681 ns**).
*   **Critical Path Destination:** EX1_EX2 pipeline register (`core:cpu_core|EX1_EX2:stage5_ex1_ex2_reg|operand_a_out[17]`).
*   **Interpretation:** While Stage 6 (EX2 / ALU) has the longest combinational stage delay (7.146 ns), the tightest physical setup paths terminate at the Stage 5 to Stage 6 boundary registers (`operand_a_out[17]`). The design meets the 127.29 MHz clock constraint with a positive slack margin of **0.066 ns**.

---

## 3. Simulation & Workload Performance

The performance below was evaluated on the [benchmark.c](../software/Benchmark/benchmark.c) workload using the simulation environment in [tb_benchmark.sv](../benchmark/tb_benchmark.sv).

### Performance Metrics
| Metric | Value | Reference / Formula |
| :--- | :--- | :--- |
| **Total Execution Cycles** | **24,273 cycles** | [tb_benchmark.sv](../benchmark/tb_benchmark.sv) |
| **Instructions Retired** | **16,166 instructions** | [tb_benchmark.sv](../benchmark/tb_benchmark.sv) |
| **CPI (Cycles Per Instruction)** | **1.5015** | $\text{Total Cycles} / \text{Instructions Retired}$ |
| **IPC (Instructions Per Cycle)** | **0.6660** | $1 / \text{CPI}$ |
| **MIPS (Millions of Inst/Sec)** | **84.78 MIPS** | $127.29\text{ MHz} \times \text{IPC}$ |
| **Code Size (Words)** | **111 words** | Compiled binary footprint |

### Instruction Mix
| Instruction Class | Count | Percentage |
| :--- | :--- | :--- |
| **ALU** | 11,325 | 70.05% |
| **Loads** | 1,994 | 12.33% |
| **Stores** | 844 | 5.22% |
| **Branches** | 1,993 | 12.33% |
| **Jumps** | 10 | 0.06% |
| **Total** | **16,166** | **100.00%** |

### CPI Breakdown

| Component | Cycles | CPI Contribution | Note / Description |
| :--- | :--- | :--- | :--- |
| **Ideal Execution** | 16,166 | 1.0000 | Baseline single-cycle retirement |
| **Load-Use Stalls** | 2,660 | 0.1645 | Frontend stalls on back-to-back load dependencies |
| **Branch Penalties** | 5,517 | 0.3413 | Flushes from correct-taken and mispredicted branches |
| **Jump Penalties** | 30 | 0.0019 | Unconditional jump control flushes |
| **Stall-Flush Overlap** | -100 | -0.0062 | Cycles where a data stall and a redirect flush occurred in the same cycle |
| **Total Measured** | **24,273** | **1.5015** | Overall CPI matching simulation metrics |

$$\text{CPI} = 1.0000 \text (Ideal) + 0.1645 \text (Stalls) + 0.3413 \text (Branch Penalties) + 0.0019 \text (Jump Penalties) - 0.0062 \text (Stall-Flush Overlap)$$

<div align="center" style="margin: 20px 0;">
<svg width="100%" height="180" viewBox="0 0 600 180" fill="none" xmlns="http://www.w3.org/2000/svg" style="background:#1e293b; border-radius:8px; border:1px solid #475569; font-family: sans-serif;">
<!-- Title -->
<text x="20" y="30" fill="#38bdf8" font-size="14" font-weight="bold">CPI Contribution Breakdown (Total: 24,273 Cycles)</text>
<!-- Stacked Bar -->
<rect x="50" y="55" width="332" height="30" rx="3" fill="#38bdf8" />
<rect x="384" y="55" width="113" height="30" rx="3" fill="#fb923c" />
<rect x="499" y="55" width="51" height="30" rx="3" fill="#ef4444" />
<rect x="552" y="55" width="2" height="30" rx="1" fill="#c084fc" />
<!-- Legend / Labels -->
<!-- Ideal -->
<rect x="50" y="105" width="12" height="12" rx="2" fill="#38bdf8" />
<text x="70" y="115" fill="#e2e8f0" font-size="11">Ideal Execution: 16,166 cycles (66.6%)</text>
<!-- Branch Penalties -->
<rect x="50" y="130" width="12" height="12" rx="2" fill="#fb923c" />
<text x="70" y="140" fill="#e2e8f0" font-size="11">Branch Penalties: 5,517 cycles (22.7%)</text>
<!-- Load-Use Stalls -->
<rect x="340" y="105" width="12" height="12" rx="2" fill="#ef4444" />
<text x="360" y="115" fill="#e2e8f0" font-size="11">Load-Use Stalls: 2,660 cycles (11.0%)</text>
<!-- Jump Penalties -->
<rect x="340" y="130" width="12" height="12" rx="2" fill="#c084fc" />
<text x="360" y="140" fill="#e2e8f0" font-size="11">Jump Penalties: 30 cycles (0.1%)</text>
</svg>
</div>

---

## 4. Hazard & Control Analysis

All metrics below are measured by [tb_benchmark.sv](../benchmark/tb_benchmark.sv) in simulation.

### Hazard Metrics Table
| Metric | Value | Reference / Notes |
| :--- | :--- | :--- |
| **Branch Predictor Accuracy** | **84.65%** | 1,687 correct / 1,993 resolved branches |
| **Average Branch Penalty** | **2.768 cycles** | $5,517\text{ penalty cycles} / 1,993\text{ branches}$ |
| **Total Flush Cycles** | **5,547 cycles** | Branch: 5,517, Jump: 30 |
| **Total Stall Cycles** | **2,660 cycles** (10.96%) | Only Load-Use hazards trigger stalls |
| **Load-Use Stalls** | **2,660 cycles** | From back-to-back loads and 1-instruction load gaps |

### Branch Cycles Breakdown by Category
*   **Correctly Predicted Not-Taken Branches (0-cycle penalty):** **460 branches resolved** (0 penalty cycles).
*   **Correctly Predicted Taken Branches (3-cycle penalty):** **1,227 branches resolved** (3,681 penalty cycles).
*   **Mispredicted Branches (6-cycle penalty):** **306 branches resolved** (1,836 penalty cycles).

### Forwarding Effectiveness Summary
The data forwarding network is highly effective at bypassing data hazards, resolving **9,413 hazard instances** and saving a total of **17,210 clock cycles** during workload execution:
*   **ALU dependencies:** Both back-to-back ALU instructions (**3,327 instances**) and ALU instructions with a 1-instruction gap (**975 instances**) were fully bypassed with **0 stall cycles**, saving **7,629 cycles** in total.
*   **Load-use dependencies:** Load instructions followed by dependent ALU instructions had their penalties reduced by forwarding, saving **8,940 cycles** across **4,470 instances**.
*   **Register File collision:** Read-during-write conflicts were bypassed in the register file (**641 instances**), saving **641 cycles**.

*Refer to the Architecture Specification for the logic descriptions of these forwarding paths.*

### Branch Predictor Evaluation
The prediction accuracy of various predictor implementations was evaluated over the 1,993 branches (1,331 Taken, 662 Not Taken) resolved during the benchmark run:

| Predictor Type | Prediction Logic | Accuracy | Evaluation / Description |
| :--- | :--- | :--- | :--- |
| **Always Not-Taken** | Static prediction of `0` | **33.22%** | Poor baseline. Heavily penalized by loop back-edges, which are almost always taken. |
| **Always Taken** | Static prediction of `1` | **66.78%** | Better performance than always not-taken due to loop back-edge dominance. |
| **Static (BTFNT)** | Backwards Taken, Forwards Not-Taken | **~82.80%** | Highly effective for standard loops. Correctly predicts backward loop back-edges as taken, and forward conditional branches inside Loop B as not-taken. |
| **BHT (Active Hardware)** | 2-bit saturating counter | **84.65%** | **Best performance.** Dynamically tracks historical branch outcomes, adapting to loop entries/exits and patterns within the pseudo-random data streams. |

---

## 5. Efficiency Metrics

| Metric | Value | Formula |
| :--- | :--- | :--- |
| **Energy Per Instruction (EPI)** | **2.039 nJ/instruction** | $(\text{Total Power} \times \text{Execution Time}) / \text{Instructions Retired}$ |
| **Performance Per Watt** | **4.9043 × 10⁸ inst/J** | $\text{Instructions Retired} / \text{Total Energy}$ |
| **MIPS/Watt** | **499.44 MIPS/W** | $\text{MIPS} / \text{Total Power (W)}$ |
| **Area Efficiency** | **28.93 KIPS/LE** | $\text{MIPS} / \text{Logic Elements}$ (with 2,931 LEs) |

---

## 6. Verification

The CPU design has undergone rigorous validation using three distinct testing tiers to ensure architectural correctness and physical robustness:

1.  **Functional Unit & Integration Testbenches:**
    The design includes 19 dedicated functional testbenches in the [tb/](../tb/) directory to validate the logic of individual sub-modules and core integrations. These unit-level verification tests cover:
    *   *Unit-level blocks:* ALU, BHT, Branch Eval, Control Unit, Data Selector, Decoder, Forwarding Unit, Hazard Detection Unit, Immediate Generator, Instruction Memory, Data Memory, PC Update, PC Target Calculator, Regfile, and Writeback logic.
    *   *Core Integration:* [tb_core.sv](../tb/tb_core.sv) and [tb_top.sv](../tb/tb_top.sv) verify register writeback loops and memory interfacing.
    *   *Regression Runner:* The PowerShell script [run_all.ps1](../sim/scripts/run_all.ps1) automates compiling and running all unit testbenches sequentially in ModelSim/QuestaSim and prints a PASS/FAIL summary table.

2.  **Co-Simulated Differential Testing against Spike:**
    The processor's execution correctness is verified instruction-by-instruction using a differential testing co-simulation harness against the golden reference **Spike ISA Simulator**. This validation applies to two distinct workloads:
    *   **RISC-V Architectural Compliance Tests:** Executes the standard `riscv-arch-test` suite (containing 39 compliance assembly tests under [differential_testing/ISA/tests/](../differential_testing/ISA/tests/)) verifying all RV32I instructions. The orchestrator [isa_diff_test.py](../differential_testing/ISA/isa_diff_test.py) compiles each test, runs it on both Spike and the RTL simulator (via [run_diff.do](../differential_testing/ISA/run_diff.do)), and compares execution traces (retired PC, writeback register ID, and register write data) for every single instruction commit.
    *   **Complex C Benchmark Program:** Verifies the CPU under realistic execution flows via [benchmark_diff_test.py](../differential_testing/Benchmark_Test/benchmark_diff_test.py), comparing retired register states against Spike across over 34,000 instruction trace commits to catch transient hazard and forwarding bugs.

3.  **Physical FPGA Board Validation:**
    The compiled CPU design has been physically programmed and validated on the **Intel MAX 10 FPGA (10M50DAF484C7G)** using the Terasic DE10-Lite development board:
    *   *Compilation & Programming:* The project compile flow is orchestrated via [compile.tcl](../fpga/compile.tcl) and programmed dynamically over JTAG using [program.ps1](../fpga/program.ps1).
    *   *MMIO Interface Verification:* Hardware ports (configured in [top.sv](../fpga/top.sv) and mapped via [mmio.sv](../rtl/core/7_ex3_mem/mmio.sv)) route physical DE10-Lite peripherals. Correct execution of C software programs (like [mmio_test.c](../software/MMIO_Test/mmio_test.c)) is confirmed by reading Slide Switches (`SW[9:0]`) and Pushbuttons (`KEY[1:0]`), and verifying computed values displayed on the Board LEDs (`LEDR[9:0]`) and six 7-segment hex displays (`HEX0`-`HEX5`).

---

## 7. Hardware & Benchmark Limitations

### 7.1 Hardware Limitations
The following features are unsupported in the hardware:
*   **M Extension:** No hardware multiply/divide. Compiler-inserted software emulation libraries (e.g., GCC runtime helper functions) handle multiplication and division operations.
*   **CSRs:** Control and Status Registers are not implemented.
*   **Interrupts and Exceptions:** The processor operates exclusively in user-mode and lacks exception handlers, trap vector registers, and interrupt lines.
*   **Virtual Memory:** Lacks MMU support. All memory accesses are direct physical addresses.
*   **Caches:** No Level 1 instruction or data caches are present. The design relies on the single-cycle access latency of FPGA on-chip BRAM.

### 7.2 Benchmark Workload Limitations
The performance metrics reported in this document are subject to several compiler and workload constraints:
1.  **Omission of Arithmetic Emulation Latency:** The software benchmark is structured around Xorshift32 PRNG and matrix transformations that avoid multiplications (`*`) and divisions (`/`). Consequently, the results do not capture the execution time and CPI overhead introduced by the software emulation helper library ([helper.h](../software/helper.h)).
2.  **No Cache Miss Penalties:** The benchmark runs entirely within the 64 KiB dual-ported synchronous on-chip BRAM. Therefore, the measurements do not simulate memory pipeline stalls caused by Level 1/Level 2 cache misses, block fills, or high-latency external memory accesses (e.g., DDR3).
3.  **Absence of Real-time Async I/O:** The I/O footprint is limited to simple LED MMIO register writes. The design does not process serial communication protocols (such as UART or SPI) or register real-time asynchronous hardware interrupts, leaving CPU interrupt latencies unmeasured.
4.  **No OS Multithreading or Context Switching:** The benchmark executes on bare metal without scheduling layers. As such, it does not capture context-switch overheads, page-fault penalties, or task synchronization behaviors typical in operating system workloads.

---

## 8. Future Work

The following enhancements could improve performance, scalability, and capabilities:
1.  **Branch Target Buffer (BTB):** Implement a BTB to store branch target addresses alongside taken predictions, enabling 0-cycle prediction redirects during the Fetch stage and reducing the taken-branch penalty to 0.
2.  **Return Address Stack (RAS):** Implement a dedicated RAS to predict the target address of function returns (`jalr x0, 0(x1)`), preventing flushes on subroutine returns.
3.  **Instruction & Data Caches:** Implement caches to support external DRAM access (e.g., DDR3 on FPGA boards) with high latency, enabling execution of much larger programs.
4.  **RV32M Extension:** Add a hardware multiplier and divider module in the ALU pipelines to eliminate software emulation overhead for multiplication and division.
5.  **Advanced Branch Predictor:** Transition from the simple BHT to global history predictors (e.g., gshare) to better capture complex conditional execution flows.
6.  **Out-of-Order Execution / Superscalar:** Redesign the pipeline to support dual-issue or out-of-order execution to bypass remaining data-dependency stalls.
