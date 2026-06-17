.section .text
.global _start

.align 4
_start:
    # Set stack pointer to the end of data memory (4096 bytes)
    # data_mem is 1024 words = 4096 bytes.
    # We set it to 4092 to ensure even the first push is in bounds.
    li sp, 4092
    
    # Jump to main
    call main

.align 4
loop:
    j loop
