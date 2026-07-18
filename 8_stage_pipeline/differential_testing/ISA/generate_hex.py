import os
import sys
import shutil
import subprocess
import argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TESTS_DIR = os.path.join(SCRIPT_DIR, "tests")
ENV_DIR = os.path.join(SCRIPT_DIR, "env")
LINKER_LD = os.path.join(SCRIPT_DIR, "linker.ld")
BUILD_DIR = os.path.join(SCRIPT_DIR, "build")

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
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if check and res.returncode != 0:
        print(f"[ERROR] WSL command failed: {' '.join(cmd)}")
        print(f"Stdout: {res.stdout}")
        print(f"Stderr: {res.stderr}")
        raise subprocess.CalledProcessError(res.returncode, cmd, res.stdout, res.stderr)
    return res

def clean_build():
    """Remove the build directory."""
    if os.path.exists(BUILD_DIR):
        print(f"Cleaning build directory: {BUILD_DIR}")
        try:
            shutil.rmtree(BUILD_DIR)
            print("[SUCCESS] Build directory cleaned.")
        except Exception as e:
            print(f"[ERROR] Failed to clean build directory: {e}")
            sys.exit(1)
    else:
        print("Build directory does not exist. Nothing to clean.")

def compile_test(test_file):
    """Compile a single assembly test into ELF and HEX files."""
    test_basename = os.path.basename(test_file)
    test_name = os.path.splitext(test_basename)[0]
    
    print(f"[BUILDING] Test: {test_basename}")
    
    build_subdir = os.path.join(BUILD_DIR, test_name)
    os.makedirs(build_subdir, exist_ok=True)
    
    elf_file = os.path.join(build_subdir, "test.elf")
    bin_file = os.path.join(build_subdir, "test.bin")
    program_hex = os.path.join(build_subdir, "program.hex")
    data_hex = os.path.join(build_subdir, "data.hex")
    
    # WSL paths
    wsl_src = to_wsl_path(test_file)
    wsl_elf = to_wsl_path(elf_file)
    wsl_bin = to_wsl_path(bin_file)
    wsl_linker = to_wsl_path(LINKER_LD)
    wsl_env = to_wsl_path(ENV_DIR)
    
    # 1. Compile assembly test using WSL GCC toolchain
    compile_cmd = [
        "riscv64-unknown-elf-gcc", "-march=rv32i", "-mabi=ilp32", "-nostdlib",
        "-T" + wsl_linker, "-I" + wsl_env, wsl_src, "-o", wsl_elf
    ]
    try:
        run_wsl_command(compile_cmd)
    except subprocess.CalledProcessError:
        return False

    # 2. Generate flat binary using objcopy
    objcopy_cmd = ["riscv64-unknown-elf-objcopy", "-O", "binary", wsl_elf, wsl_bin]
    try:
        run_wsl_command(objcopy_cmd)
    except subprocess.CalledProcessError:
        return False

    # 3. Read binary and splice it into program.hex and data.hex
    if not os.path.exists(bin_file):
        print(f"[ERROR] Binary file {bin_file} not found!")
        return False
        
    with open(bin_file, "rb") as f:
        data = f.read()
    
    # Pad to 256KB (65536 words of 4 bytes)
    target_size = 256 * 1024
    if len(data) < target_size:
        data = data.ljust(target_size, b'\x00')
    elif len(data) > target_size:
        print(f"[ERROR] Binary size {len(data)} exceeds 256KB target buffer!")
        return False

    # First 128KB goes to instruction memory (program.hex)
    with open(program_hex, "w") as f:
        for i in range(0, 128 * 1024, 4):
            word = int.from_bytes(data[i:i+4], byteorder='little')
            f.write(f"{word:08x}\n")

    # Next 128KB goes to data memory (data.hex)
    with open(data_hex, "w") as f:
        for i in range(128 * 1024, 256 * 1024, 4):
            word = int.from_bytes(data[i:i+4], byteorder='little')
            f.write(f"{word:08x}\n")

    # Clean up the bin file
    if os.path.exists(bin_file):
        os.remove(bin_file)


    print(f"[SUCCESS] Built: {test_name} -> {build_subdir}")
    return True

def main():
    parser = argparse.ArgumentParser(description="RISC-V Hex/Elf Generator for Differential Testing")
    parser.add_argument("--test", type=str, default=None, help="Name of specific assembly test case (e.g. I-add-00.S)")
    parser.add_argument("--clean", action="store_true", help="Clean all build outputs")
    args = parser.parse_args()

    if args.clean:
        clean_build()
        sys.exit(0)

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

    print(f"Found {len(test_files)} assembly test cases to compile.")
    
    os.makedirs(BUILD_DIR, exist_ok=True)
    
    failed = []
    for f in test_files:
        if not compile_test(f):
            failed.append(os.path.basename(f))
            
    if failed:
        print(f"\n[ERROR] Failed to compile tests: {', '.join(failed)}")
        sys.exit(1)
    else:
        print("\n[SUCCESS] All test programs compiled successfully!")
        sys.exit(0)

if __name__ == "__main__":
    main()
