# Master Testbench Generation Specification: `core_tb.sv`

This document contains the complete specification, the required test program, and the exact prompt needed to generate a UVM-lite, cycle-by-cycle, white-box testbench for the 12-Stage RISC-V CPU.

## 1. System Overview
* **Target DUT:** `core.sv` (12-Stage RISC-V RV32I CPU)
* **Testbench Style:** Single-file, UVM-Lite, cycle-by-cycle white-box checker.
* **Test Program:** A custom stress-test assembly program (`program.hex`) designed to trigger Read-After-Write (RAW) hazards, structural hazards, Load-Use stalls, and pipeline flushes.

## 2. Test Program (`program.hex`)
The testbench must load the following compiled hex code into the instruction memory. Save the left column as `program.hex`, or directly initialize the memory array in the testbench `initial` block with these 32-bit values.

```assembly
// --- Phase A: Datapath & ALU Sanity Check ---
00100093 // addi x1, x0, 1     // x1 = 1
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00200113 // addi x2, x0, 2     // x2 = 2
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
002081b3 // add  x3, x1, x2    // x3 = 3 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 

// --- Phase B: Forwarding Priority Stress Test ---
// Priority 1 (EX3 to EX1 Forwarding - Distance: 1 NOP)
00400213 // addi x4, x0, 4     // x4 = 4
00000013 // nop 
004202b3 // add  x5, x4, x4    // x5 = 8 (RAW Hazard EX3->EX1)

// Priority 2 (MEM1 to EX1 Forwarding - Distance: 2 NOPs)
00600313 // addi x6, x0, 6     // x6 = 6
00000013 // nop 
00000013 // nop 
006303b3 // add  x7, x6, x6    // x7 = 12 (RAW Hazard MEM1->EX1)

// Priority 3 (MEM2 to EX1 Forwarding - Distance: 3 NOPs)
00800413 // addi x8, x0, 8     // x8 = 8
00000013 // nop 
00000013 // nop 
00000013 // nop 
008404b3 // add  x9, x8, x8    // x9 = 16 (RAW Hazard MEM2->EX1)

// Priority 4 (WB to EX1 Forwarding - Distance: 4 NOPs)
00a00513 // addi x10, x0, 10   // x10 = 10
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00a505b3 // add  x11, x10, x10 // x11 = 20 (RAW Hazard WB->EX1)

// --- Phase C: Load-Use Hazard & Pipeline Stalls ---
00a02023 // sw   x10, 0(x0)    // Mem[0] = 10
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00002603 // lw   x12, 0(x0)    // x12 = Mem[0] = 10
00c606b3 // add  x13, x12, x12 // x13 = 20 (Triggers Stage 10/11 Load-Use Stall)

// --- Phase D: Control Flow & Pipeline Flushing ---
// Untaken Branch (Should NOT flush)
00100463 // beq  x0, x1, 8     // if (0 == 1) jump to 00000463 (Untaken)
00000013 // nop 

// Taken Branch (Should flush stages 1-8)
00000463 // beq  x0, x0, 8     // if (0 == 0) jump PC+8 (Taken)
00100713 // addi x14, x0, 1    // FLUSHED INSTRUCTION (x14 should remain 0)
00200793 // addi x15, x0, 2    // TARGET of Branch (x15 = 2)

// Jump and Link (Should flush stages 1-8 and save PC)
00c0086f // jal  x16, 12       // Jump PC+12, x16 = PC+4
00100893 // addi x17, x0, 1    // FLUSHED INSTRUCTION (x17 should remain 0)
00100913 // addi x18, x0, 1    // FLUSHED INSTRUCTION (x18 should remain 0)
00200993 // addi x19, x0, 2    // TARGET of Jump (x19 = 2)

// --- Phase E: Memory Integrity & Alignment ---
00a01123 // sh   x10, 2(x0)    // Mem[2:3] = 10 (Halfword)
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00201a03 // lh   x20, 2(x0)    // x20 = SignExtended(Mem[2:3])
00204a83 // lbu  x21, 2(x0)    // x21 = ZeroExtended(Mem[2])

// --- Completion Loop ---
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
00000013 // nop 
0000006f // jal  x0, 0         // Infinite loop to halt program execution