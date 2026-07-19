import os
import sys
import re
import shutil
import subprocess
import argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

ELF_FILE = os.path.join(SCRIPT_DIR, "test.elf")
BIN_FILE = os.path.join(SCRIPT_DIR, "test.bin")
PROGRAM_HEX = os.path.join(SCRIPT_DIR, "program.hex")
DATA_HEX = os.path.join(SCRIPT_DIR, "data.hex")
RTL_TRACE = os.path.join(SCRIPT_DIR, "rtl_trace.txt")
SPIKE_TRACE = os.path.join(SCRIPT_DIR, "spike_trace.txt")
SIM_TRANSCRIPT = os.path.join(SCRIPT_DIR, "transcript")

def cleanup_temp_files():
    """Delete temporary build and simulation files to keep the directory clean."""
    temp_files = [
        BIN_FILE,
        PROGRAM_HEX,
        DATA_HEX,
        RTL_TRACE,
        SPIKE_TRACE,
        SIM_TRANSCRIPT
    ]
    for f in temp_files:
        if os.path.exists(f):
            try:
                os.remove(f)
            except Exception:
                pass

# Regex to match commit log lines for register writes
trace_pattern = re.compile(
    r"core\s+\d+:\s+3\s+0x([0-9a-fA-F]+)\s+\(0x[0-9a-fA-F]+\)\s+x(\d+)\s+0x([0-9a-fA-F]+)"
)

def to_wsl_path(win_path):
    """Convert Windows path to WSL path mapping."""
    p = os.path.abspath(win_path).replace('\\', '/')
    if p[1] == ':':
        drive = p[0].lower()
        p = f"/mnt/{drive}{p[2:]}"
    return p

def run_wsl_command(args, check=True):
    """Run a command inside WSL."""
    cmd = ["wsl"] + args
    res = subprocess.run(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if check and res.returncode != 0:
        print(f"[ERROR] WSL command failed: {' '.join(cmd)}")
        print(f"Stdout: {res.stdout}")
        print(f"Stderr: {res.stderr}")
        raise subprocess.CalledProcessError(res.returncode, cmd, res.stdout, res.stderr)
    return res

def get_elf_symbols(elf_path):
    """Extract symbol addresses from ELF using nm in WSL."""
    wsl_elf = to_wsl_path(elf_path)
    res = run_wsl_command(["riscv64-unknown-elf-nm", wsl_elf])
    
    symbols = {}
    for line in res.stdout.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3:
            addr_str, _, name = parts[0], parts[1], parts[2]
            symbols[name] = int(addr_str, 16)
    return symbols

def parse_trace_file(trace_path):
    """Parse retired PC and register updates from trace file."""
    trace = []
    if not os.path.exists(trace_path):
        return trace
    with open(trace_path, "r") as f:
        for line in f:
            match = trace_pattern.search(line)
            if match:
                pc = int(match.group(1), 16)
                rd = int(match.group(2))
                data = int(match.group(3), 16)
                trace.append((pc, rd, data))
    return trace

def main():
    parser = argparse.ArgumentParser(description="Benchmark Differential Testing Framework")
    parser.add_argument("--keep", action="store_true", help="Keep temporary files after execution")
    args = parser.parse_args()

    print("==================================================")
    print("RUNNING BENCHMARK DIFFERENTIAL TESTING")
    print("==================================================")

    # 1. Compile benchmark.c with crt0_diff.s and ISA/linker.ld
    print("[INFO] Compiling benchmark.c to ELF...")
    c_src = os.path.join(SCRIPT_DIR, "../../software/Benchmark/benchmark.c")
    linker_script = os.path.join(SCRIPT_DIR, "linker.ld")
    crt0_file = os.path.join(SCRIPT_DIR, "crt0_diff.s")

    if not os.path.exists(c_src):
        print(f"[ERROR] Benchmark source file not found at {c_src}!")
        sys.exit(1)
    if not os.path.exists(linker_script):
        print(f"[ERROR] Linker script not found at {linker_script}!")
        sys.exit(1)
    if not os.path.exists(crt0_file):
        print(f"[ERROR] Startup file not found at {crt0_file}!")
        sys.exit(1)

    wsl_src = to_wsl_path(c_src)
    wsl_elf = to_wsl_path(ELF_FILE)
    wsl_bin = to_wsl_path(BIN_FILE)
    wsl_linker = to_wsl_path(linker_script)
    wsl_crt0 = to_wsl_path(crt0_file)

    compile_cmd = [
        "riscv64-unknown-elf-gcc", "-march=rv32i", "-mabi=ilp32", "-nostdlib",
        "-O3", "-flto", "-fsched-pressure", "-fno-align-loops", "-fno-align-jumps", "-fno-align-functions", "-mtune=rocket",
        "-T" + wsl_linker, wsl_crt0, wsl_src, "-o", wsl_elf
    ]
    try:
        run_wsl_command(compile_cmd)
    except Exception as e:
        print(f"[ERROR] Failed to compile C source to ELF: {e}")
        sys.exit(1)

    # 2. Extract raw binary and generate program.hex / data.hex
    print("[INFO] Extracting raw binary using objcopy...")
    objcopy_cmd = ["riscv64-unknown-elf-objcopy", "-O", "binary", wsl_elf, wsl_bin]
    try:
        run_wsl_command(objcopy_cmd)
    except Exception as e:
        print(f"[ERROR] Failed to extract raw binary: {e}")
        sys.exit(1)

    print("[INFO] Generating program.hex and data.hex...")
    if not os.path.exists(BIN_FILE):
        print(f"[ERROR] Binary file {BIN_FILE} not found!")
        sys.exit(1)

    with open(BIN_FILE, "rb") as f:
        data = f.read()

    # Pad binary to 256KB total (128KB Instruction Memory, 128KB Data Memory)
    target_size = 256 * 1024
    if len(data) < target_size:
        data = data.ljust(target_size, b'\x00')
    elif len(data) > target_size:
        print(f"[ERROR] Binary size {len(data)} exceeds 256KB target buffer!")
        sys.exit(1)

    # Split into instruction (first 128KB) and data (next 128KB) hex files
    with open(PROGRAM_HEX, "w") as f:
        for i in range(0, 128 * 1024, 4):
            word = int.from_bytes(data[i:i+4], byteorder='little')
            f.write(f"{word:08x}\n")

    with open(DATA_HEX, "w") as f:
        for i in range(128 * 1024, 256 * 1024, 4):
            word = int.from_bytes(data[i:i+4], byteorder='little')
            f.write(f"{word:08x}\n")

    # 3. Extract tohost address symbol from ELF
    print("[INFO] Extracting tohost address symbol...")
    try:
        symbols = get_elf_symbols(ELF_FILE)
        tohost_addr = symbols["tohost"]
    except KeyError:
        print("[ERROR] Required symbol 'tohost' not found in ELF symbol table!")
        sys.exit(1)

    print(f"  tohost: 0x{tohost_addr:08x}")

    # 4. Compile RTL and testbench with vlog
    print("[INFO] Compiling RTL and testbench with vlog...")
    work_dir = os.path.join(SCRIPT_DIR, "work")
    if not os.path.exists(work_dir):
        subprocess.run(["vlib", "work"], cwd=SCRIPT_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    vlog_files = [
        "../../packages/alu_pkg.sv",
        "../../packages/decoder_pkg.sv",
        "../../rtl/core/1_fetch/pc_update.sv",
        "instr_mem.sv",
        "../../rtl/core/3_decode/IF_ID.sv",
        "../../rtl/core/3_decode/control.sv",
        "../../rtl/core/3_decode/decode.sv",
        "../../rtl/core/3_decode/imm_gen.sv",
        "../../rtl/core/3_decode/ID_RR.sv",
        "../../rtl/core/4_reg_read/regfile.sv",
        "../../rtl/core/4_reg_read/bht.sv",
        "../../rtl/core/4_reg_read/RR_EX1.sv",
        "../../rtl/core/5_ex1/data_sel.sv",
        "../../rtl/core/5_ex1/EX1_EX2.sv",
        "../../rtl/core/6_ex2/alu.sv",
        "../../rtl/core/6_ex2/branch_eval.sv",
        "../../rtl/core/6_ex2/EX2_EX3.sv",
        "../../rtl/core/7_ex3_mem/pc_target_calc.sv",
        "../../rtl/core/7_ex3_mem/MEM_WB.sv",
        "data_mem.sv",
        "../../rtl/core/7_ex3_mem/mmio.sv",
        "memory.sv",
        "../../rtl/core/8_wb/writeback.sv",
        "../../rtl/core/hazard_control/forwarding_unit.sv",
        "../../rtl/core/hazard_control/hazard_detection_unit.sv",
        "../../rtl/core/core.sv",
        "tb_benchmark.sv"
    ]

    vlog_cmd = ["vlog", "-work", "work"] + vlog_files
    res_vlog = subprocess.run(vlog_cmd, cwd=SCRIPT_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res_vlog.returncode != 0:
        print("[ERROR] Compilation with vlog failed!")
        print(res_vlog.stdout)
        print(res_vlog.stderr)
        sys.exit(1)

    # 5. Launch ModelSim simulation
    print("[INFO] Launching ModelSim simulation...")
    if os.path.exists(RTL_TRACE):
        os.remove(RTL_TRACE)

    vsim_args = [
        "vsim", "-c", "-onfinish", "exit", "-voptargs=+acc", "work.tb_benchmark",
        f"+TOHOST_ADDR={tohost_addr:x}",
        "-do", "run -all; quit -f"
    ]
    res_vsim = subprocess.run(vsim_args, cwd=SCRIPT_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res_vsim.returncode != 0 or not os.path.exists(RTL_TRACE):
        print("[ERROR] ModelSim simulation failed!")
        print("Stdout:")
        print(res_vsim.stdout)
        print("Stderr:")
        print(res_vsim.stderr)
        sys.exit(1)

    # 6. Launch Spike ISA simulation (with timeout safety watchdog)
    print("[INFO] Launching Spike ISA simulation...")
    if os.path.exists(SPIKE_TRACE):
        os.remove(SPIKE_TRACE)

    wsl_spike_trace = to_wsl_path(SPIKE_TRACE)
    spike_cmd = [
        "bash", "-c",
        f"timeout 60s spike -l --log-commits --isa=rv32i --pc=0x80000000 '{wsl_elf}' < /dev/null 2> /tmp/spike_trace.txt && cp /tmp/spike_trace.txt '{wsl_spike_trace}' && rm /tmp/spike_trace.txt"
    ]
    res_spike = run_wsl_command(spike_cmd, check=False)
    if res_spike.returncode not in [0, 124, 143]:
        print(f"[ERROR] Spike simulation failed with return code {res_spike.returncode}!")
        print(res_spike.stderr)
        sys.exit(1)

    # 7. Parse and compare retired instruction traces
    print("[INFO] Parsing and comparing traces...")
    rtl_trace = parse_trace_file(RTL_TRACE)
    spike_trace = parse_trace_file(SPIKE_TRACE)

    if not rtl_trace:
        print("[ERROR] RTL trace file is empty or missing register write data!")
        sys.exit(1)
    if not spike_trace:
        print("[ERROR] Spike trace file is empty or missing register write data!")
        sys.exit(1)

    print(f"RTL retired {len(rtl_trace)} instructions with register writes.")
    print(f"Spike retired {len(spike_trace)} instructions with register writes.")

    # Compare step-by-step
    mismatch = False
    compare_len = min(len(rtl_trace), len(spike_trace))
    for i in range(compare_len):
        r_pc, r_rd, r_data = rtl_trace[i]
        s_pc, s_rd, s_data = spike_trace[i]

        if r_pc != s_pc or r_rd != s_rd or r_data != s_data:
            print(f"\n[FAIL] Mismatch found at instruction retirement index {i}:")
            print(f"  RTL:    PC=0x{r_pc:08x}, x{r_rd}=0x{r_data:08x}")
            print(f"  Golden: PC=0x{s_pc:08x}, x{s_rd}=0x{s_data:08x}")
            mismatch = True
            break

    if not mismatch and len(rtl_trace) != len(spike_trace):
        print(f"[FAIL] Trace length mismatch! RTL has {len(rtl_trace)} instructions, Spike has {len(spike_trace)} instructions.")
        mismatch = True

    if mismatch:
        print("\n[RESULT] BENCHMARK DIFFERENTIAL TESTING: FAILED (RTL Bug Found)")
        sys.exit(1)
    else:
        print(f"\n[SUCCESS] Trace Match! Checked all {compare_len} instructions successfully.")
        print("[RESULT] BENCHMARK DIFFERENTIAL TESTING: PASS")
        if not args.keep:
            cleanup_temp_files()
            if os.path.exists(work_dir):
                try:
                    shutil.rmtree(work_dir)
                except Exception:
                    pass
        sys.exit(0)

if __name__ == "__main__":
    main()
