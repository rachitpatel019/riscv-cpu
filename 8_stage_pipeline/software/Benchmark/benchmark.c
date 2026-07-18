/*
 * RISC-V Bare-Metal Pipeline Benchmark for 8-Stage RV32I CPU
 */

#include <stdint.h>

#define ARRAY_SIZE 64
#define ITERATIONS 10

// MMIO Address for LED output (write-only on this CPU)
#define MMIO_LEDR (*(volatile uint32_t *)0x80000000)

// Node structure for linked-list walk
struct Node {
    volatile struct Node* next;
    volatile uint32_t value;
};

// Global uninitialized arrays (reside in .bss; dynamically initialized in main)
// Statically-initialized globals are NOT supported due to Harvard architecture constraints
volatile uint32_t src_array[ARRAY_SIZE];
volatile uint32_t dest_array[ARRAY_SIZE];
volatile struct Node list_nodes[ARRAY_SIZE];

// Xorshift32 PRNG to generate pseudo-random values without division or multiplication
uint32_t xorshift32(uint32_t *state) {
    uint32_t x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x;
    return x;
}

int main(void) {
    // 1. Signal benchmark start via MMIO (turn on all 10 board LEDs)
    MMIO_LEDR = 0x3FF;

    // Seed the PRNG state
    uint32_t prng_state = 0xACE1;

    // 2. Dynamic Initialization Phase
    // Populate the source array and link list nodes dynamically
    for (int i = 0; i < ARRAY_SIZE; i++) {
        src_array[i] = xorshift32(&prng_state) & 0x0000FFFF;
        
        // Link nodes
        if (i < ARRAY_SIZE - 1) {
            list_nodes[i].next = &list_nodes[i + 1];
        } else {
            list_nodes[i].next = 0; // NULL terminator
        }
        list_nodes[i].value = src_array[i];
    }

    volatile uint32_t global_hash = 0;

    // 3. Execution Phase: Run benchmark loops for the configured number of iterations
    for (int iter = 0; iter < ITERATIONS; iter++) {
        uint32_t sum1 = 0;
        uint32_t sum2 = 0;

        // Loop A: Array processing (exercises load-use stalls, ALU dependencies, and forwarding)
        for (int i = 0; i < ARRAY_SIZE; i++) {
            // Load value: causes load-use stall if accessed immediately
            uint32_t val = src_array[i];

            // ALU Dependency Chain: sequential dependent operations
            // Exercises forwarding paths (EX2 -> EX1 and EX3 -> EX1)
            val = (val ^ (val << 3)) - (val >> 2);
            val = (val + 0x1234) ^ 0xABCD;

            dest_array[i] = val;
            sum1 += val;
        }

        // Loop B: Linked-list walk (exercises pointer-chasing load-use stalls and branch mispredictions)
        volatile struct Node *node = &list_nodes[0];
        while (node != 0) {
            // Load-use stall: loading node->value and using it in condition immediately
            uint32_t val = node->value;

            // Conditional Branching: since data is pseudo-random, branch outcome will
            // frequently mispredict, flushing the pipeline and triggering BHT dynamics.
            if (val & 1) {
                // Dependency and ALU work
                sum2 += (val << 1) ^ 0x5555;
            } else {
                sum2 ^= (val >> 1) + 0xAAAA;
            }

            // Pointer chasing load-use stall: loading node->next and evaluating loop condition
            node = node->next;
        }

        // Combine sums and force write to prevent compiler optimizing away the work
        global_hash = sum1 + sum2;
        asm volatile("" : : "r"(global_hash) : "memory");
    }

    // 4. Signal benchmark completion via MMIO (turn off all LEDs)
    MMIO_LEDR = 0x000;

    return 0;
}
