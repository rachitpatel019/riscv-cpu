# Pipelined RISC-V (RV32I) CPU

This repository contains a SystemVerilog implementation of a 32-bit RISC-V processor conforming to the **RV32I Base Integer Instruction Set**. The primary active design is a high-performance, balanced **8-Stage Pipeline CPU** optimized for execution on Intel/Altera FPGAs. 

A detailed architectural specification of the active design is available in [architecture.html](8_stage_pipeline/docs/architecture.html).

---

## Repository Structure

*   [8_stage_pipeline/](8_stage_pipeline) — Main active processor design.
    *   [rtl/core/](8_stage_pipeline/rtl/core) — SystemVerilog pipeline stages, hazard control, and top-level [core.sv](8_stage_pipeline/rtl/core/core.sv).
    *   [tb/](8_stage_pipeline/tb) — Unit testbenches for individual modules.
    *   [sim/](8_stage_pipeline/sim) — Simulation setup, including ModelSim DO scripts and the PowerShell regression runner [run_all.ps1](8_stage_pipeline/sim/scripts/run_all.ps1).
    *   [fpga/](8_stage_pipeline/fpga) — Quartus synthesis project files, [top.sv](8_stage_pipeline/fpga/top.sv) module, compilation scripts ([compile.tcl](8_stage_pipeline/fpga/compile.tcl)), and JTAG programming script ([program.ps1](8_stage_pipeline/fpga/program.ps1)).
    *   [software/](8_stage_pipeline/software) — Custom C-based test programs with compilation scripts targeting the processor via the RISC-V GNU Toolchain.
    *   [differential_testing/](8_stage_pipeline/differential_testing) — Co-simulation verification suite comparing RTL execution traces against the Spike ISA simulator.
*   [Archive/](Archive) — Historical processor design iterations:
    *   [single_cycle/](Archive/single_cycle) — Baseline Single-Cycle design.
    *   [5_stage_pipeline/](Archive/5_stage_pipeline) — Baseline 5-Stage Pipeline design.
*   [cpu_benchmarks.md](cpu_benchmarks.md) — Comparative synthesis metrics (Fmax, logic elements, registers) across various design versions.

---

## 8-Stage Pipeline Architecture Spec

To maximize clock frequency ($F_{max}$) on FPGA targets, the pipeline divides classic processor stages into a balanced 8-stage configuration, reducing the critical paths (such as memory read latency and branch addition).

### Pipeline Stages
1.  **Fetch (F):** PC update logic. Includes a **Branch History Table (BHT)** for dynamic taken/not-taken branch prediction.
2.  **Instruction Memory (IM):** Synchronous instruction memory read (introducing a 1-cycle latency).
3.  **Decode (D):** Instruction decode, immediate extraction, control signal generation, and hazard detection.
4.  **Register Read (RR):** Synchronous register file read (1-cycle latency) and early **Branch Target Calculation** (PC + Immediate).
5.  **Execute 1 (EX1):** Forwarding multiplexing and operand operand selection.
6.  **Execute 2 (EX2):** ALU execution and branch condition verification.
7.  **Execute 3 / Memory (EX3/MEM):** Branch resolution, dynamic predictor feedback, memory read/write access.
8.  **Writeback (WB):** Writeback data multiplexing and register file write.

### Key Features
*   **Harvard Architecture:** Separated synchronous instruction and data memories.
*   **Hazard Resolution:** A combination of stalling (via the hazard detection unit) and bypass data-forwarding (via the forwarding unit) resolves pipeline dependencies.
*   **Early Branch Adder:** Target calculation is computed in Stage 4 (RR) instead of Stage 6 (EX2) to shorten the critical path.
*   **Dynamic Branch Prediction:** A Stage 1 Branch History Table (BHT) minimizes the taken-branch penalty to 3 cycles when correctly predicted (otherwise, a mispredicted branch or unconditional jump flushes the preceding 6 stages).

---

## Memory-Mapped I/O (MMIO)

The CPU includes an MMIO interface designed for the **DE10-Lite FPGA Board**, defined in [mmio.sv](8_stage_pipeline/rtl/core/7_ex3_mem/mmio.sv). Peripherals are mapped as follows:

| Register Address | Access Type | Width | Mapped Board Hardware |
|---|---|---|---|
| `0x80000000` | Write-Only | 10-bit | Green/Red LEDs (`LEDR[9:0]`) |
| `0x80000004` | Write-Only | 24-bit | $6 \times$ 7-segment hex displays (`HEX0`-`HEX5`) |
| `0x80000008` | Read-Only | 10-bit | Slide Switches (`SW[9:0]`) |
| `0x8000000C` | Read-Only | 2-bit | Pushbutton Keys (`KEY[1:0]`) |

---

## Synthesis & Performance Metrics

Performance benchmarks collected from Altera Quartus Prime synthesis are recorded in [cpu_benchmarks.md](cpu_benchmarks.md):

| Design Version | Clock Frequency ($F_{max}$) | Logic Elements (LEs) | Registers | Memory Bits |
| :--- | :--- | :--- | :--- | :--- |
| **Single Cycle** | ~48 MHz | 10,587 | 8,522 | 0 |
| **5-Stage Pipeline (Unoptimized)** | ~92 MHz | 11,262 | 8,817 | 0 |
| **5-Stage Pipeline (Sync Reads)** | ~70 MHz | 1,828 | 393 | 18,432 |
| **8-Stage Pipeline (Active)** | **125.0 MHz** | **2,796** | **1,347** | **69,632** |

---

## Verification & Testing

The project uses two verification methodologies: modular unit simulations and differential trace-matching co-simulations. **All scripts are designed to be executed directly from the root directory of the repository.**

### 1. Regression Unit Simulations
Modular SystemVerilog testbenches are run sequentially via a PowerShell simulation script.
*   **Tool Requirement:** ModelSim or QuestaSim (`vsim`) in your system PATH.
*   **Execution:** 
    ```powershell
    ./8_stage_pipeline/sim/scripts/run_all.ps1
    ```

### 2. Differential Testing Flow
The differential testing suite ([differential_testing/](8_stage_pipeline/differential_testing)) verifies the RTL execution instruction-by-instruction against the reference Spike ISA simulator.
*   **Test Cases:** The assembly test cases in [differential_testing/tests/](8_stage_pipeline/differential_testing/tests) were downloaded from the official RISC-V Architecture Test suite: [riscv-arch-test (RV32I tests)](https://github.com/riscv/riscv-arch-test/tree/act4/tests/rv32i/I).
*   **Tool Requirements:** ModelSim (`vsim`), Python 3, Windows Subsystem for Linux (WSL) containing the RISC-V GNU toolchain (`riscv64-unknown-elf-gcc`, `riscv64-unknown-elf-objcopy`, `riscv64-unknown-elf-nm`) and the Spike simulator.
*   **Compilation:** Compile assembly tests into program memory hex files:
    ```powershell
    python 8_stage_pipeline/differential_testing/generate_hex.py
    ```
*   **Running Differential Tests:** Run trace-matching on a specific test (e.g. `I-add-00.S`):
    ```powershell
    python 8_stage_pipeline/differential_testing/diff_test.py --test I-add-00.S
    ```

---

## FPGA Compilation & Deployment

The physical hardware target is the Intel MAX 10 FPGA (specifically the **10M50DAF484C7G** device on the Terasic DE10-Lite development board). **All scripts are designed to be executed directly from the root directory of the repository.**

*   **Synthesis Compilation:** Compile and generate the programming SOF bitstream:
    1.  Ensure Quartus Prime executable directories are in your system PATH.
    2.  Execute the Tcl script:
        ```powershell
        quartus_sh -t 8_stage_pipeline/fpga/compile.tcl
        ```
*   **Device Programming:** Program the MAX 10 FPGA through a connected USB-Blaster cable:
    ```powershell
    ./8_stage_pipeline/fpga/program.ps1
    ```
