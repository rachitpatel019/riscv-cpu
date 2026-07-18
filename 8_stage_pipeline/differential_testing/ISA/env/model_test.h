#ifndef _MODEL_TEST_H
#define _MODEL_TEST_H

#define RVMODEL_BOOT \
    li x1, 0; \
    li x4, 0; \
    li x5, 0; \
    li x6, 0; \
    li x7, 0; \
    li x8, 0; \
    li x9, 0; \
    li x10, 0; \
    li x11, 0; \
    li x12, 0; \
    li x13, 0; \
    li x14, 0; \
    li x15, 0; \
    li x16, 0; \
    li x17, 0; \
    li x18, 0; \
    li x19, 0; \
    li x20, 0; \
    li x21, 0; \
    li x22, 0; \
    li x23, 0; \
    li x24, 0; \
    li x25, 0; \
    li x26, 0; \
    li x27, 0; \
    li x28, 0; \
    li x29, 0; \
    li x30, 0; \
    li x31, 0;

#define RVMODEL_INIT

#define RVMODEL_HALT \
    li gp, 1; \
    la t0, tohost; \
    sw gp, 0(t0); \
    halt_loop: \
        j halt_loop;

#define RVMODEL_DATA_BEGIN \
    .align 4; \
    .global scratch; \
    scratch: \
        .word 0; \
        .word 0; \
        .word 0; \
        .word 0;

#define RVMODEL_DATA_END

#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_IO_ASSERT(_A)
#define RVMODEL_IO_WRITE_STR(_A, _B)

#define LI(reg, val) li reg, val
#define LA(reg, val) la reg, val

#define SIG_STRIDE 4
#define REGWIDTH 4
#define sreg sw
#define lreg lw
#define SREG sw
#define LREG lw

#endif
