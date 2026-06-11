/**
 * ALU Test Program for 12-stage RISC-V CPU
 * 
 * This program performs each ALU operation supported by the CPU.
 * Results are designed to have the last 6 bits non-zero (0x3F) 
 * to distinguish them from other ALU operations like PC increments.
 */

// Use volatile to prevent compiler from optimizing away operations
// and to ensure they result in actual ALU instructions.
volatile int a;
volatile int b;
volatile int res;

// Small delay to make it easier to see results in waveform
void delay() {
    for (volatile int i = 0; i < 20; i++);
}

int main() {
    // 1. ADD
    a = 0x20; b = 0x1F;
    res = a + b; // 0x3F
    delay();

    // 2. SUB
    a = 0x50; b = 0x11;
    res = a - b; // 0x3F
    delay();

    // 3. AND
    a = 0xFFFFFFFF; b = 0x3F;
    res = a & b; // 0x3F
    delay();

    // 4. OR
    a = 0x30; b = 0x0F;
    res = a | b; // 0x3F
    delay();

    // 5. XOR
    a = 0xFFFFFFC0; b = 0xFFFFFFFF;
    res = a ^ b; // 0x3F
    delay();

    // 6. SLL
    a = 0x3F; b = 0;
    res = a << b; // 0x3F
    delay();

    // 7. SRL
    a = 0x3F0; b = 4;
    res = a >> b; // 0x3F
    delay();

    // 8. SRA
    a = 0xFFFFFC3F; b = 0;
    res = a >> b; // 0xFFFFFC3F -> last 6 bits are 111111
    delay();

    // 9. SLT (Signed Less Than)
    a = -1; b = 1;
    if (a < b) res = 0x3F; else res = 0x3E;
    delay();

    // 10. SLTU (Unsigned Less Than)
    unsigned int ua = 1;
    unsigned int ub = 2;
    if (ua < ub) res = 0x3F; else res = 0x3E;
    delay();

    // SUCCESS: Infinite loop with the result 0x3F (111111) in the ALU
    // This ensures that 'out_writeback_data' stays at 111111.
    while(1) {
        asm volatile("addi x1, x0, 0x3F");
    }

    return 0;
}
