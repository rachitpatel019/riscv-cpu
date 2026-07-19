# 8-Stage Pipeline CPU Metrics Dashboard

This document summarizes the timing, resource, performance, hazard, and efficiency metrics of the **8-Stage Pipeline RISC-V CPU** on an Intel MAX 10 FPGA (device `10M50DAF484C7G`) for the fully optimized workload (`-O3 -flto -fsched-pressure -fno-align-* -mtune=rocket`).

---

## 1. Physical Synthesis & Power Metrics

These physical specifications represent the synthesized gate-level netlist of the hardware. They remain identical across all software workloads.

| Metric | Value | Reference |
| :--- | :--- | :--- |
| **Clock Frequency ($F_{\text{max}}$)** | **127.29 MHz** ($T_{\text{clk}} = 7.856\text{ ns}$) | Clock constraint in [cpu.sdc](../fpga/cpu.sdc) |
| **Logic Utilization** | **2,931 / 49,760 LEs** (6%) | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **Register Usage** | **1,303 registers** | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **BRAM Usage** | **1,052,672 bits** (63% capacity) | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **Static Power** | **90.38 mW** | [cpu.pow.summary](../fpga/output_files/cpu.pow.summary) |
| **Dynamic Power** | **103.03 mW** (94.07 mW Core + 8.96 mW I/O) | [cpu.pow.summary](../fpga/output_files/cpu.pow.summary) |
| **Total Power** | **193.40 mW** | [cpu.pow.summary](../fpga/output_files/cpu.pow.summary) |

---

## 2. Simulation & Workload Performance

The performance below was evaluated on the [Benchmark](../software/Benchmark/benchmark.c) workload using the simulation environment in [tb_benchmark.sv](tb_benchmark.sv).

### Performance Metrics
| Metric | Value | Reference / Formula |
| :--- | :--- | :--- |
| **Total Execution Cycles** | **24,273 cycles** | [tb_benchmark.sv](tb_benchmark.sv) |
| **Instructions Retired** | **16,166 instructions** | [tb_benchmark.sv](tb_benchmark.sv) |
| **CPI (Cycles Per Instruction)** | **1.5015** | $\text{Total Cycles} / \text{Instructions Retired}$ |
| **IPC (Instructions Per Cycle)** | **0.6660** | $1 / \text{CPI}$ |
| **MIPS (Millions of Inst/Sec)** | **84.78 MIPS** | $127.29\text{ MHz} \times \text{IPC}$ |
| **Code Size (Words)** | **111 words** | Compiled binary footprint |

*Note on Execution Metrics:* The core loops in the benchmark use `volatile` qualifiers to simulate a realistic data processing load. Consequently, GCC is constrained to emit memory access operations exactly as written.

---

## 3. Hazard & Control Analysis

All metrics below are measured by [tb_benchmark.sv](tb_benchmark.sv) in simulation.

### Hazard Metrics Table
| Metric | Value | Reference / Notes |
| :--- | :--- | :--- |
| **Branch Predictor Accuracy** | **84.65%** | 1,687 correct / 1,993 resolved branches |
| **Average Branch Penalty** | **1.999 cycles** | $3,984\text{ penalty cycles} / 1,993\text{ branches}$ |
| **Total Flush Cycles** | **4,004 cycles** | Branch: 3,984, Jump: 20 |
| **Total Stall Cycles** | **2,660 cycles** (10.96%) | [hazard_detection_unit.sv](../rtl/core/hazard_control/hazard_detection_unit.sv) |

### Branch Cycles Breakdown by Category
*   **Correctly Predicted Not-Taken Branches (0-cycle penalty)**: **460 branches resolved** (0 penalty cycles).
*   **Correctly Predicted Taken Branches (2-cycle penalty)**: **1,227 branches resolved** (2,454 penalty cycles).
*   **Mispredicted Branches (5-cycle penalty)**: **306 branches resolved** (1,530 penalty cycles).

### Stall Cycles Breakdown by Dependency
*   **ALU Back-to-Back (0-cycle stall)**: 0 cycles (3,327 hazards bypassed by forwarding).
*   **ALU 1-Instruction Gap (0-cycle stall)**: 0 cycles (975 hazards bypassed by forwarding).
*   **Load Back-to-Back (2-cycle stall)**: 1,280 cycles (640 hazards).
*   **Load 1-Instruction Gap (1-cycle stall)**: 1,920 cycles (1,920 hazards).
*   **Load 2-Instruction & 3-Instruction Gaps (0-cycle stall)**: 0 cycles (1,910 and 641 hazards bypassed by forwarding).
*   *Note*: The instruction scheduler successfully reordered dependencies to separate loads and uses, keeping total measured hardware stalls to only **2,660 cycles** (which is lower than the raw hazard math because independent instructions compiled in between hid the stalls).

---

## 4. Efficiency Metrics

| Metric | Value | Reference / Formula |
| :--- | :--- | :--- |
| **Energy Per Instruction (EPI)** | **2.323 nJ/instruction** | $(\text{Total Power} \times \text{Execution Time}) / \text{Instructions Retired}$ |
| **Performance Per Watt** | **4.3045 × 10⁸ inst/J** | $\text{Instructions Retired} / \text{Total Energy}$ |
| **MIPS/Watt** | **438.37 MIPS/W** | $\text{MIPS} / \text{Total Power (W)}$ |
| **Area Efficiency** | **28.93 KIPS/LE** | $\text{MIPS} / \text{Logic Elements}$ (with 2,931 LEs) |
