import os
import subprocess
import sys

# Configuration
TOOLCHAIN_PREFIX = "riscv64-unknown-elf-"
CC = f"{TOOLCHAIN_PREFIX}gcc"
OBJCOPY = f"{TOOLCHAIN_PREFIX}objcopy"
CFLAGS = "-march=rv32i -mabi=ilp32 -nostdlib -O3 -flto -fsched-pressure -fno-align-loops -fno-align-jumps -fno-align-functions -mtune=rocket"



def to_wsl_path(win_path):
    abs_path = os.path.abspath(win_path)
    if len(abs_path) > 1 and abs_path[1] == ':':
        drive = abs_path[0].lower()
        rest = abs_path[2:].replace('\\', '/')
        return f"/mnt/{drive}{rest}"
    return abs_path.replace('\\', '/')

def main():
    # Get absolute directories
    script_dir = os.path.dirname(os.path.abspath(__file__))
    software_dir = os.path.dirname(script_dir)
    
    # Find the C source file in the stress test directory
    c_files = [f for f in os.listdir(script_dir) if f.endswith('.c')]
    if not c_files:
        print("Error: No .c file found in the stress test directory.")
        sys.exit(1)
    
    src_file = os.path.join(script_dir, c_files[0])
    base_name = os.path.splitext(os.path.basename(src_file))[0]
    
    elf_file = os.path.join(script_dir, f"{base_name}.elf")
    bin_file = os.path.join(script_dir, f"{base_name}.bin")
    hex_file = os.path.join(script_dir, "program.hex")

    linker_script = os.path.join(software_dir, "linker.ld")
    crt0_file = os.path.join(software_dir, "crt0.s")

    print(f"Building {os.path.basename(src_file)}...")

    # Convert all paths to absolute WSL paths
    cc_wsl = CC
    objcopy_wsl = OBJCOPY
    linker_wsl = to_wsl_path(linker_script)
    crt0_wsl = to_wsl_path(crt0_file)
    src_wsl = to_wsl_path(src_file)
    elf_wsl = to_wsl_path(elf_file)
    bin_wsl = to_wsl_path(bin_file)

    # Helper to run commands (entering WSL if on Windows)
    def run_command(cmd):
        if os.name == 'nt':
            cmd = f"wsl {cmd}"
        print(f"Running: {cmd}")
        subprocess.run(cmd, shell=True, check=True)

    # 1. Compile and Link using absolute paths
    compile_cmd = f"{cc_wsl} {CFLAGS} -T {linker_wsl} {crt0_wsl} {src_wsl} -o {elf_wsl}"
    try:
        run_command(compile_cmd)
    except subprocess.CalledProcessError:
        print("Error: Compilation failed.")
        sys.exit(1)

    # 2. Create Binary
    objcopy_cmd = f"{objcopy_wsl} -O binary {elf_wsl} {bin_wsl}"
    try:
        run_command(objcopy_cmd)
    except subprocess.CalledProcessError:
        print("Error: objcopy failed.")
        sys.exit(1)

    # 3. Generate Hex file
    print(f"Generating {hex_file}...")
    try:
        with open(bin_file, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Error: {bin_file} not found.")
        sys.exit(1)

    # Pad data to a multiple of 4 bytes
    padding_needed = (4 - len(data) % 4) % 4
    data += b'\x00' * padding_needed

    with open(hex_file, 'w') as f:
        for i in range(0, len(data), 4):
            # Convert 4 bytes to an integer (little-endian) and format as 8 hex digits
            word = int.from_bytes(data[i:i+4], byteorder='little')
            f.write(f"{word:08x}\n")

    print(f"Successfully generated {hex_file} ({len(data)//4} words).")

    # 4. Clean up intermediate ELF and BIN files
    if os.path.exists(elf_file):
        print(f"Removing intermediate ELF file: {elf_file}")
        os.remove(elf_file)
    if os.path.exists(bin_file):
        print(f"Removing intermediate BIN file: {bin_file}")
        os.remove(bin_file)

if __name__ == "__main__":
    main()
