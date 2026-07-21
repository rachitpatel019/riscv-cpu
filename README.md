# Pipelined RISC-V (RV32I) CPU

This repository contains a SystemVerilog implementation of a 32-bit RISC-V processor conforming to the **RV32I Base Integer Instruction Set**. The primary active design is a high-performance, balanced **8-Stage Pipeline CPU** optimized for execution on Intel/Altera FPGAs.

---

## Documentation

Comprehensive guides and technical documentation are available under [8_stage_pipeline/docs/](8_stage_pipeline/docs/):

*   📄 **[Architecture Specification](8_stage_pipeline/docs/architecture.html)**
    *   *Pipeline stages, dynamic branch predictor, data forwarding/hazard logic, MMIO addresses, core ports, and a glossary of FPGA terminology.*
*   📊 **[Technical Report](8_stage_pipeline/docs/technical_report.md)**
    *   *Fmax measurements, static/dynamic power dissipation, per-stage timing slacks, CPI workload analysis, and co-simulation verification logs.*
*   ⚙️ **[Script & Automation Guide](8_stage_pipeline/docs/script_guide.md)**
    *   *System requirements, toolchain versions (GCC, Python, Quartus, ModelSim), compilation commands, and verification harnesses.*

---

## Repository Structure

*   **[8_stage_pipeline/](8_stage_pipeline/)** — Main processor design folder.
    *   `rtl/core/` — SystemVerilog pipeline stages, hazard control, and top-level [core.sv](8_stage_pipeline/rtl/core/core.sv).
    *   `tb/` — Unit testbenches for individual logic blocks.
    *   `sim/` — Simulation setups, ModelSim macros (`.do` files), and regression test scripts.
    *   `fpga/` — Quartus synthesis project, timing/power analysis setups, and hardware ports.
    *   `software/` — Custom C-based test programs, startup code (`crt0.s`), and build scripts.
    *   `differential_testing/` — Trace-matching co-simulation suites against reference Spike ISS.
*   **[Archive/](Archive/)** — Historical baseline designs.
    *   `single_cycle/` — Baseline single-cycle CPU.
    *   `5_stage_pipeline/` — Baseline 5-stage CPU (implemented in both LUT-based and BRAM-based memories).

---

## Quick Start Summary

All automation scripts are designed to be run from the repository root directory. For full parameters, refer to the [Script Guide](8_stage_pipeline/docs/script_guide.md).

### 1. Verification & Simulation
*   **RTL Unit Regressions:** Run sequentially in ModelSim/QuestaSim:
    ```powershell
    ./8_stage_pipeline/sim/scripts/run_all.ps1
    ```
*   **ISA Compliance Diff-Tests:** Verify RV32I opcodes against the Spike simulator trace:
    ```powershell
    python 8_stage_pipeline/differential_testing/ISA/isa_diff_test.py
    ```
*   **Benchmark Trace Diff-Tests:** Co-simulate a complex C program:
    ```powershell
    python 8_stage_pipeline/differential_testing/Benchmark_Test/benchmark_diff_test.py
    ```

### 2. FPGA Synthesis & Programming
*   **Full Synthesis & Fitting:** Compile the Quartus project:
    ```powershell
    quartus_sh -t 8_stage_pipeline/fpga/compile.tcl
    ```
*   **FPGA Device Flashing:** Upload compiled SOF bitstream dynamically to MAX 10 FPGA over JTAG:
    ```powershell
    ./8_stage_pipeline/fpga/program.ps1
    ```
