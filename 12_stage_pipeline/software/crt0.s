.section .text
.global _start

.align 4
_start:
    # Set stack pointer to the end of data memory (1024 bytes)
    # data_mem is 256 words = 1024 bytes.
    # We set it to 1020 to ensure even the first push is in bounds.
    li sp, 1020
    
    # Jump to main
    call main

.align 4
loop:
    j loop
