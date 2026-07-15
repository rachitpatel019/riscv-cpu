# 8-Stage Pipeline CPU Synthesis & Power Specifications

This document outlines the performance benchmarks, synthesis results, and power dissipation analysis for the active **8-Stage Pipeline** processor design, compiled and simulated for Intel/Altera FPGAs.

---

## Synthesis & Performance Metrics

Performance benchmarks collected from Altera Quartus Prime synthesis:

| Design Version | Clock Frequency ($F_{max}$) | Logic Elements (LEs) | Registers | IMEM Capacity | DMEM Capacity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Single Cycle** | ~48 MHz | 10,587 | 8,522 | 1 KiB (256 words) | 1 KiB (256 words) |
| **5-Stage Pipeline (Unoptimized)** | ~92 MHz | 11,262 | 8,817 | 1 KiB (256 words) | 1 KiB (256 words) |
| **5-Stage Pipeline (Sync Reads)** | ~70 MHz | 1,828 | 393 | 1 KiB (256 words) | 1 KiB (256 words) |
| **8-Stage Pipeline (Active)** | **125.0 MHz** | **2,796** | **1,347** | **64 KiB (16,384 words)** | **64 KiB (16,384 words)** |

*Target Device:* Intel MAX 10 FPGA (**10M50DAF484C7G**) on the Terasic DE10-Lite development board.

---

## Power Dissipation & Analysis

Power dissipation metrics for the active **8-Stage Pipeline** design on the Intel MAX 10 FPGA (**10M50DAF484C7G**), simulated at **125.0 MHz** with a dynamic program workload (RISC-V Benchmark):

*   **Total Thermal Power Dissipation:** **329.99 mW**
*   **Core Dynamic Thermal Power Dissipation:** **223.81 mW**
*   **Core Static Thermal Power Dissipation:** **97.23 mW**
*   **I/O Thermal Power Dissipation:** **8.96 mW**

These metrics are estimated using the Quartus Prime Power Analyzer with switching activity extracted from a gate-level simulation VCD file.

### Running Power Analysis Automatically

All scripts are designed to be executed directly from the root directory of the repository:

1.  **Generate Switching Activity (VCD):** Run the gate-level simulation script to generate `power.vcd`:
    ```powershell
    ./8_stage_pipeline/fpga/run_power_sim.ps1
    ```
2.  **Estimate Power:** Run the Power Analyzer tool to estimate thermal dissipation and view the summary:
    ```powershell
    ./8_stage_pipeline/fpga/run_power_analysis.ps1
    ```
