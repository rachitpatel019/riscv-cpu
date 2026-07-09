.section .text
.global _start

.align 4
_start:
    # Set stack pointer to the end of data memory (4096 bytes)
    # data_mem is 1024 words = 4096 bytes.
    # We set it to 4092 to ensure even the first push is in bounds.
    li sp, 4092

    # Copy .data section from ROM to RAM
    # Note: On this specific Harvard architecture, loads from ROM space are routed
    # to RAM by the memory controller, meaning this copy loop will load from RAM.
    # We implement it anyway to show the standard architectural implementation.
    la a0, _data_load
    la a1, _data_start
    la a2, _data_end
data_copy_loop:
    bge a1, a2, data_copy_done
    lw a3, 0(a0)
    sw a3, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    j data_copy_loop
data_copy_done:

    # Zero out the .bss section in RAM
    la a0, _bss_start
    la a1, _bss_end
bss_zero_loop:
    bge a0, a1, bss_zero_done
    sw x0, 0(a0)
    addi a0, a0, 4
    j bss_zero_loop
bss_zero_done:
    
    # Jump to main
    call main

.align 4
loop:
    j loop
