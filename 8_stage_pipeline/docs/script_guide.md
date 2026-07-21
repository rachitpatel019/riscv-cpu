# 8-Stage RISC-V CPU Script & Automation Guide

This document provides a comprehensive overview of all automation, simulation, compilation, programming, analysis, and verification scripts in the [8_stage_pipeline](../) directory. 

All scripts are designed to be executed from both the root of the repository or their respective directories, as detailed below.

---

## Toolchain & Software Dependencies

The automation and verification scripts require the following toolchain and utility versions:

| Software Tool / Dependency | Version Requirement | Purpose / Usage |
| :--- | :--- | :--- |
| **Python 3** | Python 3.8+ | Manages the differential ISA and benchmark test harnesses, logs verification results, and generates/pads HEX files. |
| **Intel Quartus Prime** | Lite Edition 20.1+ | Synthesizes and fits the SystemVerilog design, performs TimeQuest timing analysis, and executes power analyzer. |
| **ModelSim / QuestaSim** | Starter/Lite Edition 20.1+ | Compiles RTL netlists, executes batch simulations, and dumps value change files (`power.vcd`). |
| **RISC-V Spike ISS** | Matches RV32I base | Serves as the golden reference Instruction Set Simulator for step-by-step register write-back trace matching. |
| **RISC-V GCC Toolchain** | `riscv64-unknown-elf-gcc` (tested on 14.2.0) | Cross-compiles C programs inside WSL to produce raw binary outputs loaded into ROM/RAM. |

---

## Script Index

The table below summarizes the purpose of each script in the project:

| Script Name | Path | Primary Purpose |
|:---|:---|:---|
| **Software Build** | | |
| [custom_build.py](../software/custom_build.py) | `8_stage_pipeline/software/` | Compiles and links custom C programs using GCC in WSL, generating `program.hex`. |
| **RTL Unit Simulation** | | |
| [run_all.ps1](../sim/scripts/run_all.ps1) | `8_stage_pipeline/sim/scripts/` | Sequential simulation runner that runs a regression suite of all block-level `.do` scripts. |
| `.do` Scripts (16 files) | `8_stage_pipeline/sim/scripts/` | ModelSim batch compilation and simulation execution files for specific modules and CPU core. |
| **FPGA Synthesis & Compilation** | | |
| [compile.tcl](../fpga/compile.tcl) | `8_stage_pipeline/fpga/` | Automated synthesis, fitting, and assembly flow for Quartus Prime. |
| [timing_analysis.tcl](../fpga/timing_analysis.tcl) | `8_stage_pipeline/fpga/` | Calculates propagation delay of each of the 8 pipeline stages and reports worst paths using TimeQuest STA. |
| [program.ps1](../fpga/program.ps1) | `8_stage_pipeline/fpga/` | Detects programming cables and flashes MAX 10 FPGA with compilation output bitstream. |
| **FPGA Power Analysis** | | |
| [run_power_sim.ps1](../fpga/run_power_sim.ps1) | `8_stage_pipeline/fpga/` | Runs gate-level simulation post-compilation to dump switching activity (`power.vcd`). |
| [run_power_analysis.ps1](../fpga/run_power_analysis.ps1) | `8_stage_pipeline/fpga/` | Executes Quartus Power Analyzer using `power.vcd` switching activity and parses output. |
| **Differential & Verification Testing** | | |
| [isa_diff_test.py](../differential_testing/ISA/isa_diff_test.py) | `8_stage_pipeline/differential_testing/ISA/` | Co-simulation regression suite testing architectural compliance tests on ModelSim vs Spike ISS. |
| [generate_hex.py](../differential_testing/ISA/generate_hex.py) | `8_stage_pipeline/differential_testing/ISA/` | Pre-compiles architectural tests into spliced instruction (`program.hex`) and data (`data.hex`) memories. |
| [run_diff.do](../differential_testing/ISA/run_diff.do) | `8_stage_pipeline/differential_testing/ISA/` | Loads/compiles testbench and memories for co-simulation inside ModelSim. |
| [benchmark_diff_test.py](../differential_testing/Benchmark_Test/benchmark_diff_test.py) | `8_stage_pipeline/differential_testing/Benchmark_Test/` | Co-simulation and step-by-step trace matching verification for a complex C benchmark program. |
| **Benchmark Runner** | | |
| [run_benchmark.ps1](../benchmark/run_benchmark.ps1) | `8_stage_pipeline/benchmark/` | Runs the benchmark SystemVerilog testbench inside ModelSim in batch mode. |
| [run_benchmark.do](../benchmark/run_benchmark.do) | `8_stage_pipeline/benchmark/` | ModelSim setup script to compile and execute the benchmark simulation. |

---

## 1. Software Build Scripts

### `custom_build.py`
* **Path:** [8_stage_pipeline/software/custom_build.py](../software/custom_build.py)
* **Execution:**
  ```powershell
  cd 8_stage_pipeline/software/
  python custom_build.py
  ```
* **Purpose:** Compiles a target C source file into a RISC-V executable, extracts raw binaries, formats them into a 32-bit little-endian instruction hex representation (`program.hex`), and places it into the target build subdirectory.
* **Arguments & Variables:**
  * Configure `TARGET_C_FILE` directly inside the script to point to your `.c` file relative to the `8_stage_pipeline/software/` folder.
* **Under the Hood:**
  1. Invokes the WSL-installed GCC cross-compiler (`riscv64-unknown-elf-gcc`) with standard flags (`-march=rv32i -mabi=ilp32 -nostdlib -O3`).
  2. Integrates the assembly startup file [crt0.s](../software/crt0.s) and links using [linker.ld](../software/linker.ld).
  3. Uses `riscv64-unknown-elf-objcopy` to output a raw binary (`.bin`).
  4. Reads the `.bin` byte payload, formats it as 8-character little-endian hexadecimal words (padded to 4-byte boundaries), and outputs them to `program.hex`.
  5. Cleans up intermediate `.elf` and `.bin` files automatically.

> [!NOTE]
> **RV32I Software Multiplication & Division Helpers:**
> The CPU conforms strictly to the base RV32I integer set. Hardware multiplication and division instructions (`*`, `/`, `%`) are absent. Use the header library [helper.h](../software/helper.h) in your C programs to access software emulation routines (`multiply()`, `divide()`, `modulo()`).
> 
> **Harvard Memory Architecture Limitation:**
> The ROM (Instruction) and RAM (Data) buses are separated, starting at address `0x00000000`. Memory read operations (`lw`) access physical RAM and cannot read constant arrays (`.rodata`) or statically initialized global variables (`.data` section) stored in ROM. Global variables must remain uninitialized (residing in `.bss`, which is zero-initialized by the startup assembly), or variables must be initialized dynamically within your code (e.g. local array elements assigned within functions).

---

## 2. RTL Unit Simulation Scripts

### `run_all.ps1`
* **Path:** [8_stage_pipeline/sim/scripts/run_all.ps1](../sim/scripts/run_all.ps1)
* **Execution:**
  ```powershell
  # Can be executed from the repository root
  ./8_stage_pipeline/sim/scripts/run_all.ps1
  ```
* **Purpose:** Acts as a test harness runner for block-level testbenches. It runs all simulation scripts sequentially, checks execution outputs, and prints a tabular regression success summary.
* **Under the Hood:**
  1. Checks for the `vsim` executable in the system path.
  2. Iterates over 16 `.do` block scripts sequentially.
  3. Runs each in batch mode using `Start-Process vsim -ArgumentList "-batch", "-l", "vsim.log", "-do", "$script"`.
  4. Parses results and reports overall PASS/FAIL stats. Returns exit code `0` on total success and `1` on any failure. Cleans up temporary ModelSim libraries and transcripts upon completion.

### Individual `.do` Scripts (ModelSim)
* **Path:** `8_stage_pipeline/sim/scripts/run_[module_name].do`
* **Execution:**
  ```powershell
  vsim -c -do run_[module_name].do
  ```
* **Purpose:** Automation instructions executed by the ModelSim engine. Each script:
  * Cleans the local compiled `work` library.
  * Compiles required package files and SystemVerilog RTL modules.
  * Compiles the corresponding testbench located in the `tb/` directory.
  * Launches simulation, runs all testcases (`run -all`), and exits cleanly with appropriate exit codes.

---

## 3. FPGA Synthesis, Compilation & Deployment Scripts

### `compile.tcl`
* **Path:** [8_stage_pipeline/fpga/compile.tcl](../fpga/compile.tcl)
* **Execution:**
  ```powershell
  quartus_sh -t 8_stage_pipeline/fpga/compile.tcl
  ```
* **Purpose:** Runs a complete Quartus flow from command line.
* **Under the Hood:**
  1. Performs a sanity check verifying that all 8-stage RTL files, package configurations, program memory files, and SDC constraints exist.
  2. Opens the `cpu.qpf` project.
  3. Sets Device assignments (targeting `10M50DAF484C7G` / MAX 10 FPGA) and selects the `top` level module.
  4. Runs the compilation pipeline using `execute_flow -compile`.
  5. Outputs the synthesis, mapping, fitting, and programming files under the `output_files/` directory.

### `timing_analysis.tcl`
* **Path:** [8_stage_pipeline/fpga/timing_analysis.tcl](../fpga/timing_analysis.tcl)
* **Execution:**
  ```powershell
  # Run after compilation compiles the project netlist
  quartus_sta -t 8_stage_pipeline/fpga/timing_analysis.tcl
  ```
* **Purpose:** Loads the design netlist and reports propagation delays (data path delays) specifically mapped to each of the 8 balanced pipeline stages, alongside the top 10 most critical timing paths.
* **Under the Hood:**
  1. Opens the Quartus project, creates a timing netlist, and reads design constraints from `cpu.sdc`.
  2. Iterates over defined source/destination register boundary patterns mapping to the 8 physical stages of the CPU.
  3. Uses `get_timing_paths -from [src] -to [dst] -setup` and extracts `-data_delay` info.
  4. Prints a formatted tabular report of stage latencies (in nanoseconds) and critical setup slack paths to the terminal.

### `program.ps1`
* **Path:** [8_stage_pipeline/fpga/program.ps1](../fpga/program.ps1)
* **Execution:**
  ```powershell
  ./8_stage_pipeline/fpga/program.ps1
  ```
* **Purpose:** Automatically flashes the compiled SRAM Object File (`cpu.sof`) onto a physically connected DE10-Lite development board.
* **Under the Hood:**
  1. Queries connected JTAG chains using `quartus_pgm -l`.
  2. Regular-expression-matches and selects the connected USB-Blaster hardware cable.
  3. Triggers the programming execution command `quartus_pgm -c $cable -m JTAG -o "p;output_files/cpu.sof"`.

---

## 4. FPGA Power Analysis Scripts

These scripts automate dynamic power dissipation reporting by simulating post-compilation gate-level netlists with realistic switching activities.

### `run_power_sim.ps1`
* **Path:** [8_stage_pipeline/fpga/run_power_sim.ps1](../fpga/run_power_sim.ps1)
* **Execution:**
  ```powershell
  ./8_stage_pipeline/fpga/run_power_sim.ps1
  ```
* **Purpose:** Generates a complete Value Change Dump file (`power.vcd`) representing node switching patterns over the course of execution.
* **Under the Hood:**
  1. Verifies that the post-fitting gate-level netlist file `simulation/questa/cpu.vo` has been generated by Quartus.
  2. Copies configured `modelsim.ini` configurations.
  3. Writes a temporary macro simulation command file `power_sim.do`.
  4. Launches ModelSim in command-line mode (`vsim -batch -do power_sim.do`) which compiles the netlist, links Intel FPGA simulation libraries (`fiftyfivenm_ver`, `altera_ver`), loads the testbench, registers signals using `vcd add -r /tb_top/dut/*`, runs the test, and dumps the VCD file.
  5. Cleans up temporary macro and log files, leaving only `power.vcd`.

### `run_power_analysis.ps1`
* **Path:** [8_stage_pipeline/fpga/run_power_analysis.ps1](../fpga/run_power_analysis.ps1)
* **Execution:**
  ```powershell
  ./8_stage_pipeline/fpga/run_power_analysis.ps1
  ```
* **Purpose:** Runs Quartus Power Analyzer and displays dynamic/static power summary statistics.
* **Under the Hood:**
  1. Confirms the existence of `power.vcd` (and invokes `run_power_sim.ps1` to generate it if missing).
  2. Runs `quartus_pow` on the compiled design.
  3. Opens the generated report file `output_files/cpu.pow.rpt`, extracts the `Power Analyzer Summary` block, and displays core dynamic/static/total thermal power dissipation values directly on the command line.

---

## 5. Differential Verification & Compliance Testing Scripts

These scripts implement co-simulation validation by matching instruction execution states step-by-step against the reference RISC-V Spike ISA Simulator.

### `isa_diff_test.py`
* **Path:** [8_stage_pipeline/differential_testing/ISA/isa_diff_test.py](../differential_testing/ISA/isa_diff_test.py)
* **Execution:**
  ```powershell
  # Run regression on all compliance tests
  python 8_stage_pipeline/differential_testing/ISA/isa_diff_test.py

  # Run regression on a specific test file
  python 8_stage_pipeline/differential_testing/ISA/isa_diff_test.py --test I-add-00.S
  ```
* **Purpose:** Main regression wrapper for the standard RISC-V architectural compliance suite.
* **Arguments:**
  * `--test [testname.S]`: Optional. Targets a single test case; otherwise, all `.S` tests are processed sequentially.
  * `--keep`: Optional. Keeps intermediate `.elf`, `.bin`, `.hex`, and `.txt` traces for debug.
* **Under the Hood:**
  1. Compiles the assembly test code inside WSL using GCC.
  2. Generates instruction and data hex files.
  3. Runs the test program on the reference Spike simulator in WSL, generating an instruction commit trace (`spike_trace.txt`) and reference signature (`spike_sig.txt`).
  4. Runs the same test on the RTL model inside ModelSim in batch mode using the helper [run_diff.do](../differential_testing/ISA/run_diff.do), dumping registers and memory state signature writes (`rtl_trace.txt`, `rtl_sig.txt`).
  5. Parses and compares the traces instruction-by-instruction. Checks for differences in PC, writeback register IDs, and register data values. Reports errors on mismatch.

### `generate_hex.py`
* **Path:** [8_stage_pipeline/differential_testing/ISA/generate_hex.py](../differential_testing/ISA/generate_hex.py)
* **Execution:**
  ```powershell
  # Compile all compliance assembly files
  python 8_stage_pipeline/differential_testing/ISA/generate_hex.py

  # Compile a single compliance test file
  python 8_stage_pipeline/differential_testing/ISA/generate_hex.py --test I-add-00.S

  # Clean the build directory
  python 8_stage_pipeline/differential_testing/ISA/generate_hex.py --clean
  ```
* **Purpose:** Pre-compiles RISC-V assembly source tests into raw binary payload and segments them into instruction and data blocks.
* **Under the Hood:**
  1. Invokes the GCC toolchain in WSL to compile test files using the compliance environment headers and linker scripts.
  2. Extracts the flat binary.
  3. Pads the binary payload to 256 KB. Slices the first 128 KB into `program.hex` (Instruction ROM space) and the final 128 KB into `data.hex` (Data RAM space) formatted as 8-character little-endian hex words.

### `run_diff.do`
* **Path:** [8_stage_pipeline/differential_testing/ISA/run_diff.do](../differential_testing/ISA/run_diff.do)
* **Execution:** Executed automatically by `isa_diff_test.py` via ModelSim.
* **Purpose:** Compiles package dependencies, RTL files, and the co-simulation testbench `tb_diff.sv`. Starts the simulation in command-line mode passing command-line arguments to write traces.

### `benchmark_diff_test.py`
* **Path:** [8_stage_pipeline/differential_testing/Benchmark_Test/benchmark_diff_test.py](../differential_testing/Benchmark_Test/benchmark_diff_test.py)
* **Execution:**
  ```powershell
  python 8_stage_pipeline/differential_testing/Benchmark_Test/benchmark_diff_test.py
  ```
* **Purpose:** Verifies instruction-by-instruction execution correctness of a complex C-based benchmark program against Spike.
* **Under the Hood:**
  1. Compiles the target benchmark C file in WSL and outputs a test ELF.
  2. Runs Spike in WSL with tracing flags to dump reference retired PC and register updates.
  3. Runs ModelSim simulation of the 8-stage CPU containing the compiled benchmark code, which produces an RTL commit trace.
  4. Parses both output files, compares PC, destination register, and write data values, and prints step-by-step co-simulation validation stats.

---

## 6. Benchmark Runner Scripts

### `run_benchmark.ps1`
* **Path:** [8_stage_pipeline/benchmark/run_benchmark.ps1](../benchmark/run_benchmark.ps1)
* **Execution:**
  ```powershell
  ./8_stage_pipeline/benchmark/run_benchmark.ps1
  ```
* **Purpose:** Powershell wrapper to execute the standalone benchmark simulation in ModelSim and verify its outcome.
* **Under the Hood:**
  1. Checks for the `vsim` executable.
  2. Confirms that `run_benchmark.do`, `tb_benchmark.sv`, and `program.hex` exist.
  3. Changes directory to the benchmark folder and spawns ModelSim batch execution of the DO script.
  4. Parses exit codes, deletes intermediate ModelSim directories/work files, and outputs verification logs.

### `run_benchmark.do`
* **Path:** [8_stage_pipeline/benchmark/run_benchmark.do](../benchmark/run_benchmark.do)
* **Execution:** Executed automatically by `run_benchmark.ps1`.
* **Purpose:** ModelSim script that compiles packages, CPU pipeline stage files, custom memory blocks including MMIO controller, and the specialized benchmark testbench module `tb_benchmark.sv` before executing simulation to completion.
