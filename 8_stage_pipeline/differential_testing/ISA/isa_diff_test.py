import os
import sys
import re
import shutil
import subprocess
import argparse

# Paths configuration relative to script location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TESTS_DIR = os.path.join(SCRIPT_DIR, "tests")
ENV_DIR = os.path.join(SCRIPT_DIR, "env")
LINKER_LD = os.path.join(SCRIPT_DIR, "linker.ld")

# Global counters for test progress
RUNNING_TEST_IDX = 0
TOTAL_TEST_COUNT = 0

# Temporary build outputs (Windows paths)
ELF_FILE = os.path.join(SCRIPT_DIR, "test.elf")
BIN_FILE = os.path.join(SCRIPT_DIR, "test.bin")
PROGRAM_HEX = os.path.join(SCRIPT_DIR, "program.hex")
DATA_HEX = os.path.join(SCRIPT_DIR, "data.hex")

# Simulation traces and signatures (Windows paths)
RTL_TRACE = os.path.join(SCRIPT_DIR, "rtl_trace.txt")
RTL_SIG = os.path.join(SCRIPT_DIR, "rtl_sig.txt")
SPIKE_TRACE = os.path.join(SCRIPT_DIR, "spike_trace.txt")
SPIKE_SIG = os.path.join(SCRIPT_DIR, "spike_sig.txt")
SIM_TRANSCRIPT = os.path.join(SCRIPT_DIR, "transcript")

def cleanup_temp_files():
    """Delete temporary build and simulation files to keep the directory clean."""
    temp_files = [
        BIN_FILE,
        PROGRAM_HEX,
        DATA_HEX,
        RTL_TRACE,
        RTL_SIG,
        SPIKE_TRACE,
        SPIKE_SIG,
        SIM_TRANSCRIPT
    ]
    for f in temp_files:
        if os.path.exists(f):
            try:
                os.remove(f)
            except Exception:
                pass

# Regex to match commit log lines for register writes
# Example: core   0: 3 0x80000000 (0x00000093) x1  0x00000000
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
    with open(trace_path, "r") as f:
        for line in f:
            match = trace_pattern.search(line)
            if match:
                pc = int(match.group(1), 16)
                rd = int(match.group(2))
                data = int(match.group(3), 16)
                trace.append((pc, rd, data))
    return trace

def parse_signature_file(sig_path):
    """Parse signature file into a list of 32-bit hex values."""
    sig = []
    if not os.path.exists(sig_path):
        return sig
    with open(sig_path, "r") as f:
        for line in f:
            val = line.strip()
            # Handle continuous hex strings (e.g. from Spike: 4 words per line)
            if len(val) == 32:
                # Spike prints 16-byte blocks as big-endian strings (highest address on left,
                # lowest on right). We parse right-to-left to match ascending address order.
                for i in range(24, -1, -8):
                    sig.append(val[i:i+8].lower())
            elif len(val) == 8:
                sig.append(val.lower())
    return sig

def run_test(test_file):
    """Execute differential test for a single test case using pre-compiled artifacts."""
    global RUNNING_TEST_IDX, TOTAL_TEST_COUNT
    RUNNING_TEST_IDX += 1
    
    test_basename = os.path.basename(test_file)
    test_name = os.path.splitext(test_basename)[0]
    print(f"\n==================================================")
    if TOTAL_TEST_COUNT > 0:
        print(f"[RUNNING] Test {RUNNING_TEST_IDX}/{TOTAL_TEST_COUNT}: {test_basename}")
    else:
        print(f"[RUNNING] Test: {test_basename}")
    print(f"==================================================")
    
    # 1. Locate pre-compiled build artifacts
    build_subdir = os.path.join(SCRIPT_DIR, "build", test_name)
    src_elf = os.path.join(build_subdir, "test.elf")
    src_prog = os.path.join(build_subdir, "program.hex")
    src_data = os.path.join(build_subdir, "data.hex")
    
    if not (os.path.exists(src_prog) and os.path.exists(src_data)):
        print(f"[ERROR] Pre-compiled hex artifacts not found for {test_name} under {build_subdir}!")
        print("Please run 'generate_hex.py' first to compile the test cases.")
        return False
        
    # 2. Copy artifacts to local folder for simulation
    print("[INFO] Loading pre-compiled artifacts...")
    try:
        shutil.copy2(src_prog, PROGRAM_HEX)
        shutil.copy2(src_data, DATA_HEX)
        if os.path.exists(src_elf):
            shutil.copy2(src_elf, ELF_FILE)
        else:
            # Compile on-the-fly to ELF_FILE since generate_hex.py cleans up .elf files
            print("[INFO] ELF file not found in build. Compiling on-the-fly...")
            wsl_src = to_wsl_path(test_file)
            wsl_elf = to_wsl_path(ELF_FILE)
            wsl_linker = to_wsl_path(LINKER_LD)
            wsl_env = to_wsl_path(ENV_DIR)
            compile_cmd = [
                "riscv64-unknown-elf-gcc", "-march=rv32i", "-mabi=ilp32", "-nostdlib",
                "-T" + wsl_linker, "-I" + wsl_env, wsl_src, "-o", wsl_elf
            ]
            run_wsl_command(compile_cmd)
    except Exception as e:
        print(f"[ERROR] Failed to load/compile artifacts: {e}")
        return False

    # 3. Extract symbol addresses of tohost, begin_signature, and end_signature
    print("[INFO] Extracting symbol table...")
    wsl_elf = to_wsl_path(ELF_FILE)
    try:
        symbols = get_elf_symbols(ELF_FILE)
        tohost_addr = symbols["tohost"]
        sig_begin = symbols["begin_signature"]
        sig_end = symbols["end_signature"]
        # Align end_signature to next 16-byte boundary to match Spike's 128-bit block alignment
        sig_end = (sig_end + 15) & ~15
    except KeyError as e:
        print(f"[ERROR] Required symbol {e} not found in ELF symbol table!")
        return False

    print(f"  tohost: 0x{tohost_addr:08x}")
    print(f"  begin_signature: 0x{sig_begin:08x}")
    print(f"  end_signature: 0x{sig_end:08x}")

    # 6. Compile and Launch RTL Simulation using ModelSim on Windows
    print("[INFO] Compiling RTL and testbench with vlog...")
    # Create work library if it does not exist
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
        "tb_diff.sv"
    ]
    
    vlog_cmd = ["vlog", "-work", "work"] + vlog_files
    res_vlog = subprocess.run(vlog_cmd, cwd=SCRIPT_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res_vlog.returncode != 0:
        print("[ERROR] Compilation with vlog failed!")
        print(res_vlog.stdout)
        print(res_vlog.stderr)
        return False

    print("[INFO] Launching ModelSim simulation...")
    # Clean old RTL logs
    for path in [RTL_TRACE, RTL_SIG]:
        if os.path.exists(path):
            os.remove(path)
            
    vsim_args = [
        "vsim", "-c", "-onfinish", "exit", "-voptargs=+acc", "work.tb_diff",
        f"+SIGNATURE_BEGIN={sig_begin:x}", f"+SIGNATURE_END={sig_end:x}", f"+TOHOST_ADDR={tohost_addr:x}",
        "-do", "run -all; quit -f"
    ]
    
    res = subprocess.run(vsim_args, cwd=SCRIPT_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0 or not os.path.exists(RTL_TRACE):
        print("[ERROR] ModelSim execution failed or trace file not generated!")
        print("Stdout:")
        print(res.stdout)
        print("Stderr:")
        print(res.stderr)
        return False

    # 7. Launch Spike Simulation inside WSL
    print("[INFO] Launching Spike ISA simulation...")
    # Clean old Spike logs
    for path in [SPIKE_TRACE, SPIKE_SIG]:
        if os.path.exists(path):
            os.remove(path)
            
    wsl_spike_sig = to_wsl_path(SPIKE_SIG)
    wsl_spike_trace = to_wsl_path(SPIKE_TRACE)
    
    # We pipe stderr (which holds the commit log) to spike_trace.txt
    spike_cmd = [
        "bash", "-c",
        f"spike -l --log-commits --isa=rv32i +signature={wsl_spike_sig} {wsl_elf} 2> {wsl_spike_trace}"
    ]
    try:
        run_wsl_command(spike_cmd)
    except subprocess.CalledProcessError:
        return False

    # 8. Compare Step-by-Step Retired Instruction Traces
    print("[INFO] Performing step-by-step trace comparison...")
    if not os.path.exists(RTL_TRACE) or not os.path.exists(SPIKE_TRACE):
        print("[ERROR] Trace file(s) missing!")
        return False
        
    rtl_trace = parse_trace_file(RTL_TRACE)
    spike_trace = parse_trace_file(SPIKE_TRACE)
    
    # Filter out bootloader instructions (PC < 0x80000000)
    spike_trace = [inst for inst in spike_trace if inst[0] >= 0x80000000]
    rtl_trace = [inst for inst in rtl_trace if inst[0] >= 0x80000000]
    
    mismatch = False
    max_len = max(len(rtl_trace), len(spike_trace))
    for i in range(max_len):
        if i >= len(rtl_trace):
            print(f"[FAIL] Mismatch at step {i}: RTL ended early.")
            print(f"  Golden (Spike) committed: PC=0x{spike_trace[i][0]:08x}, x{spike_trace[i][1]}=0x{spike_trace[i][2]:08x}")
            mismatch = True
            break
        if i >= len(spike_trace):
            print(f"[FAIL] Mismatch at step {i}: Golden (Spike) ended early.")
            print(f"  RTL committed: PC=0x{rtl_trace[i][0]:08x}, x{rtl_trace[i][1]}=0x{rtl_trace[i][2]:08x}")
            mismatch = True
            break
            
        r_pc, r_rd, r_data = rtl_trace[i]
        s_pc, s_rd, s_data = spike_trace[i]
        
        if r_pc != s_pc or r_rd != s_rd or r_data != s_data:
            print(f"[FAIL] Mismatch at step {i} (Instruction retirement index {i}):")
            print(f"  RTL:    PC=0x{r_pc:08x}, x{r_rd}=0x{r_data:08x}")
            print(f"  Golden: PC=0x{s_pc:08x}, x{s_rd}=0x{s_data:08x}")
            mismatch = True
            break
            
    if mismatch:
        print("[RESULT] Trace Match: FAILED")
        return False
    else:
        print(f"[SUCCESS] Step-by-step Trace Match! ({len(rtl_trace)} instructions verified)")

    # 9. Compare Final Signature Memory Traces
    print("[INFO] Comparing final signature buffers...")
    rtl_sig = parse_signature_file(RTL_SIG)
    spike_sig = parse_signature_file(SPIKE_SIG)
    
    if len(rtl_sig) != len(spike_sig):
        print(f"[FAIL] Signature size mismatch: RTL has {len(rtl_sig)} words, Spike has {len(spike_sig)} words.")
        return False
        
    sig_mismatch = False
    for i in range(len(rtl_sig)):
        if rtl_sig[i] != spike_sig[i]:
            print(f"[FAIL] Signature mismatch at word {i}: RTL=0x{rtl_sig[i]}, Golden=0x{spike_sig[i]}")
            sig_mismatch = True
            break
            
    if sig_mismatch:
        print("[RESULT] Signature Match: FAILED")
        return False
    else:
        print(f"[SUCCESS] Signature Match! ({len(rtl_sig)} words matched)")

    print(f"[RESULT] {test_name}: PASS")
    return True

def main():
    parser = argparse.ArgumentParser(description="Differential Testing Framework for 8-Stage RV32I CPU")
    parser.path = TESTS_DIR
    parser.add_argument("--test", type=str, default=None, help="Name of specific assembly test case (e.g. I-add-00.S)")
    args = parser.parse_args()

    # Find test files
    if args.test:
        test_file = os.path.join(TESTS_DIR, args.test)
        if not os.path.exists(test_file):
            print(f"[ERROR] Test case not found: {test_file}")
            sys.exit(1)
        test_files = [test_file]
    else:
        test_files = [os.path.join(TESTS_DIR, f) for f in os.listdir(TESTS_DIR) if f.endswith(".S")]
        test_files.sort()

    if not test_files:
        print("[ERROR] No assembly test files found!")
        sys.exit(1)

    print(f"Found {len(test_files)} assembly test cases.")
    
    global TOTAL_TEST_COUNT
    TOTAL_TEST_COUNT = len(test_files)
    
    passed_tests = []
    failed_tests = []

    for test_file in test_files:
        success = run_test(test_file)
        if success:
            passed_tests.append(os.path.basename(test_file))
        else:
            failed_tests.append(os.path.basename(test_file))
            # Break immediately on failure to help focus debugging
            break

    print(f"\n==================================================")
    print(f"TESTING REGRESSION SUMMARY")
    print(f"==================================================")
    print(f"Total Tests Run: {len(passed_tests) + len(failed_tests)}")
    print(f"Passed:          {len(passed_tests)}")
    print(f"Failed:          {len(failed_tests)}")
    
    if failed_tests:
        print(f"\nFailed Test list:")
        for t in failed_tests:
            print(f"  [-] {t}")
        sys.exit(1)
    else:
        print(f"\n[SUCCESS] ALL TESTS PASSED!")
        cleanup_temp_files()
        work_dir = os.path.join(SCRIPT_DIR, "work")
        if os.path.exists(work_dir):
            import shutil
            try:
                shutil.rmtree(work_dir)
            except Exception as e:
                print(f"[WARNING] Could not delete work directory: {e}")
        sys.exit(0)

if __name__ == "__main__":
    main()
