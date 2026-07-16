# Running Custom C Programs on RV32I CPU

This guide explains how to compile, build, and run custom C programs on the 8-Stage Pipelined RISC-V CPU.

---

## Compiling & Building Programs

Custom C programs are compiled using the centralized build script [custom_build.py](8_stage_pipeline/software/custom_build.py) located in the `8_stage_pipeline/software/` folder.

### Step-by-Step Instructions:

1. **Configure Target C File:**
   Open [custom_build.py](8_stage_pipeline/software/custom_build.py) and modify the `TARGET_C_FILE` variable at the top of the script to specify the path to your `.c` source file relative to the `8_stage_pipeline/software/` directory.
   
   *Example:*
   ```python
   TARGET_C_FILE = "MMIO_Test/mmio_test.c"
   ```

2. **Execute Compilation:**
   Navigate to the `8_stage_pipeline/software/` directory and run the compilation script:
   ```powershell
   python custom_build.py
   ```

### Under the Hood:
The build script performs the following steps:
1. Invokes the RISC-V GCC compiler toolchain (`riscv64-unknown-elf-gcc`) inside Windows Subsystem for Linux (WSL).
2. Compiles and links the target C file with the custom linker script [linker.ld](8_stage_pipeline/software/linker.ld) and startup assembly [crt0.s](8_stage_pipeline/software/crt0.s).
3. Extracts the binary payload using `objcopy` and generates the formatted `program.hex` instruction file.
4. **Automatically deletes** the intermediate `.elf` file to keep the workspace clean.

---

## Software Multiplication & Division Helpers

Since the CPU implements the **RV32I Base Integer ISA** (which lacks the 'M' hardware multiplication/division extension), standard operators (`*`, `/`, `%`) cannot compile natively on bare metal without linker errors.

To address this, use the header-only software emulation library: [helper.h](8_stage_pipeline/software/helper.h).

### Usage:
Simply `#include "../helper.h"` in your C program to access these emulated operations:
* `multiply(a, b)`: Multiplies two signed 32-bit integers using shift-and-add.
* `divide(dividend, divisor)`: Divides two signed 32-bit integers using shift-and-subtract.
* `modulo(dividend, divisor)`: Computes the remainder of dividing two signed 32-bit integers (matching C99 sign rules).

---

## CPU Architectural Capabilities & Limitations

When writing custom programs, you must adhere to the physical hardware constraints of this CPU:

### What CAN Run:
* **RV32I Core Instruction Set:** Native support for 32-bit addition/subtraction, logical ops (`and`, `or`, `xor`), shifts (`sll`, `srl`, `sra`), comparison branching, and memory load/stores.
* **Bare-Metal C Code:** Standard basic C constructs (local variables, loops, branching, pointers, structures).
* **BSS Section Zero-Initialization:** Uninitialized global variables (`.bss` section) are automatically zeroed out at boot time by [crt0.s](8_stage_pipeline/software/crt0.s).
* **Memory-Mapped I/O:** Reading from physical switches/pushbuttons and writing to LEDs/Seven-Segment displays (mapped at addresses `0x80000000` to `0x8000000C`).

### What CANNOT Run (or has severe constraints):
* **No Hardware Multiplication/Division (RV32M):** Must use the software emulation routines provided in [helper.h](8_stage_pipeline/software/helper.h).
* **No Hardware Floating-Point (RV32F/D):** Floating-point operations (`float`, `double`) are unsupported.
* **Harvard Bus Separation (No ROM-to-RAM copy of static globals):** The CPU separates instruction ROM and data RAM into distinct buses, both starting at address `0x00000000`. Since load instructions (`lw`) only read from RAM, the CPU cannot read constants (`.rodata`) or copy initial values (`.data` section) from the instruction ROM at runtime. Statically-initialized globals (like `int x = 42;`) are therefore not supported.
* **Strict Memory Limits:** Instruction code (`.text`) must fit within the **64 KB ROM** limit, and RAM variables/stack frames must fit within the **64 KB RAM** limit.
* **No Standard C Library (libc):** Standard functions like `printf()` or `malloc()` are unavailable.
* **No OS/Privileged Modes:** The CPU has no supervisor modes, virtual memory, page tables, interrupts, or CSR registers.
