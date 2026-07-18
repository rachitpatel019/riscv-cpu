.section .text
.global _start

.align 4
_start:
    # Set stack pointer to the end of RAM (0x80020000 + 128KB = 0x80040000)
    # We set it to 0x8003fffc to ensure it is aligned and in bounds.
    li sp, 0x8003fffc

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

    # Write exit code (1) to tohost MMIO address to terminate simulation
    li t0, 1
    la t1, tohost
    sw t0, 0(t1)

.align 4
loop:
    j loop

.section .tohost, "aw", @progbits
.align 16
.global tohost
.global fromhost
tohost:
    .word 0
.align 16
fromhost:
    .word 0
