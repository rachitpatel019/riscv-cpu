import os
import subprocess
import sys

# Configuration
TOOLCHAIN_PREFIX = "riscv64-unknown-elf-"
CC = f"{TOOLCHAIN_PREFIX}gcc"
OBJCOPY = f"{TOOLCHAIN_PREFIX}objcopy"
CFLAGS = "-march=rv32i -mabi=ilp32 -nostdlib"
LDFLAGS = "-T ../linker.ld"
CRT0 = "../crt0.s"

def main():
    # Change directory to the directory containing this script so relative paths work
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    # Find the C source file in the current directory
    c_files = [f for f in os.listdir('.') if f.endswith('.c')]
    if not c_files:
        print("Error: No .c file found in the current directory.")
        sys.exit(1)
    
    src_file = c_files[0]
    base_name = os.path.splitext(src_file)[0]
    elf_file = f"{base_name}.elf"
    bin_file = f"{base_name}.bin"
    hex_file = "program.hex"

    print(f"Building {src_file} in {script_dir}...")

    # Helper to run commands (entering WSL if on Windows)
    def run_command(cmd):
        if os.name == 'nt':
            cmd = f"wsl {cmd}"
        print(f"Running: {cmd}")
        subprocess.run(cmd, shell=True, check=True)

    # 1. Compile and Link
    compile_cmd = f"{CC} {CFLAGS} {LDFLAGS} {CRT0} {src_file} -o {elf_file}"
    try:
        run_command(compile_cmd)
    except subprocess.CalledProcessError:
        print("Error: Compilation failed.")
        sys.exit(1)

    # 2. Create Binary
    objcopy_cmd = f"{OBJCOPY} -O binary {elf_file} {bin_file}"
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

    # 4. Clean up intermediate ELF file
    if os.path.exists(elf_file):
        print(f"Removing intermediate ELF file: {elf_file}")
        os.remove(elf_file)

if __name__ == "__main__":
    main()
