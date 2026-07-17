# 8-Stage Pipeline CPU Metrics Dashboard

This document summarizes the timing, resource, performance, hazard, and efficiency metrics of the **8-Stage Pipeline RISC-V CPU** on an Intel MAX 10 FPGA (device `10M50DAF484C7G`).

---

## 1. Physical Synthesis & Power Metrics

| Metric | Value | Reference |
| :--- | :--- | :--- |
| **Clock Frequency ($F_{\text{max}}$)** | **125.0 MHz** ($T_{\text{clk}} = 8.000\text{ ns}$) | PLL instance in [top.sv](../fpga/top.sv#L31-L36) |
| **Logic Utilization** | **2,903 / 49,760 LEs** (6%) | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **Register Usage** | **1,408 registers** | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **BRAM Usage** | **1,052,672 bits** (63% capacity) | [cpu.fit.summary](../fpga/output_files/cpu.fit.summary) |
| **Static Power** | **97.44 mW** | [cpu.pow.summary](../fpga/output_files/cpu.pow.summary) |
| **Dynamic Power** | **275.39 mW** (266.44 mW Core + 8.96 mW I/O) | [cpu.pow.summary](../fpga/output_files/cpu.pow.summary) |
| **Total Power** | **372.83 mW** | [cpu.pow.summary](../fpga/output_files/cpu.pow.summary) |

---

## 2. Simulation & Workload Performance

The performance below was evaluated on the [Benchmark](../software/Benchmark/benchmark.c) workload using the simulation environment in [tb_benchmark.sv](tb_benchmark.sv).

### Performance Metrics
| Metric | Value | Reference / Formula |
| :--- | :--- | :--- |
| **Total Execution Cycles** | **85,992 cycles** | [tb_benchmark.sv](tb_benchmark.sv) |
| **Instructions Retired** | **41,752 instructions** | [tb_benchmark.sv](tb_benchmark.sv) |
| **CPI (Cycles Per Instruction)** | **2.0596** | $\text{Total Cycles} / \text{Instructions Retired}$ |
| **IPC (Instructions Per Cycle)** | **0.4855** | $1 / \text{CPI}$ |
| **MIPS (Millions of Inst/Sec)** | **60.69 MIPS** | $125.0\text{ MHz} \times \text{IPC}$ |

### Retired Instruction Mix
*   **ALU Operations:** 18,227 (43.66%)
*   **Loads:** 14,279 (34.20%)
*   **Stores:** 6,593 (15.79%)
*   **Branches:** 2,080 (4.98%)
*   **Jumps:** 573 (1.37%)

---

## 3. Hazard & Control Analysis

All metrics below are measured by [tb_benchmark.sv](tb_benchmark.sv)

### Hazard Metrics Table
| Metric | Value | Reference / Formula |
| :--- | :--- | :--- |
| **Branch Predictor Accuracy** | **85.33%** | 1,774 correct out of 2,079 resolved branches |
| **Average Branch Penalty** | **2.131 cycles** | $4,430\text{ penalty cycles} / 2,079\text{ branches}$ |
| **Total Flush Cycles** | **5,768 cycles** | Branch-related: 4,430 cycles, Jump-related: 1,338 cycles |
| **Total Stall Cycles** | **36,572 cycles** (42.53%) | [hazard_detection_unit.sv](../rtl/core/hazard_control/hazard_detection_unit.sv) |

### Branch Cycles Breakdown by Category
*   **Correctly Predicted Not-Taken Branches (0-cycle penalty):** 322 branches resolved (0 penalty cycles).
*   **Correctly Predicted Taken Branches (2-cycle penalty):** 1,452 branches resolved (2,904 penalty cycles).
*   **Mispredicted Branches (5-cycle penalty):** 305 branches resolved (1,525 penalty cycles).
*   *Note:* The remaining 1 cycle in the total 4,430 branch penalty cycles represents a transient simulation overlap with a hazard stall.

### Stall Cycles Breakdown by Dependency
*   **ALU Back-to-Back (1-cycle stall):** 6,335 cycles ($6,335\text{ hazards} \times 1$)
*   **ALU 1-Instruction Gap (0-cycle stall):** 0 cycles ($1,472\text{ hazards} \times 0$)
*   **Load Back-to-Back (2-cycle stall):** 23,866 cycles ($11,933\text{ hazards} \times 2$)
*   **Load 1-Instruction Gap (1-cycle stall):** 5,033 cycles ($5,033\text{ hazards} \times 1$)
*   **Unclassified Stalls (Store/Branch/Jump/MMIO dependencies):** 1,338 cycles
*   *Note:* Load 2-Instruction and 3-Instruction Gap dependencies result in **0-cycle stalls** due to forwarding.

---

## 4. Efficiency Metrics

| Metric | Value | Reference / Formula |
| :--- | :--- | :--- |
| **Energy Per Instruction (EPI)** | **6.143 nJ/instruction** | $(\text{Total Power} \times \text{Execution Time}) / \text{Instructions Retired}$ |
| **Performance Per Watt** | **1.6279 × 10⁸ instructions/Joule** | $\text{Instructions Retired} / \text{Total Energy}$ |
| **MIPS/Watt** | **162.78 MIPS/W** | $\text{MIPS} / \text{Total Power (W)}$ |
| **Area Efficiency** | **20.91 KIPS/LE** | $60.69\text{ MIPS} / 2,903\text{ LEs}$ (or $1.672 \times 10^{-4}\text{ IPC/LE}$) |
