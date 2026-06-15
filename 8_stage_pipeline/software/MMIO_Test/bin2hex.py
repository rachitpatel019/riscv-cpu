import sys

def main():
    try:
        with open('mmio_test.bin', 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print("Error: mmio_test.bin not found. Did you run objcopy?", file=sys.stderr)
        sys.exit(1)

    # Pad data to a multiple of 4 bytes
    padding_needed = (4 - len(data) % 4) % 4
    data += b'\x00' * padding_needed

    with open('program.hex', 'w') as f:
        for i in range(0, len(data), 4):
            # Convert 4 bytes to an integer (little-endian) and format as 8 hex digits
            word = int.from_bytes(data[i:i+4], byteorder='little')
            f.write(f"{word:08x}\n")

    print(f"Successfully generated program.hex ({len(data)//4} words).")

if __name__ == "__main__":
    main()
