#ifndef _RISCV_ARCH_TEST_H
#define _RISCV_ARCH_TEST_H

#include "model_test.h"

#define RVTEST_BEGIN                           \
    .section .text;                            \
    .global _start;                            \
    _start:                                    \
        RVMODEL_BOOT                           \
        la x2, begin_signature;                \
        la x3, begin_testdata;                 \
        RVMODEL_INIT

#define RVTEST_CODE_END                        \
    RVMODEL_HALT

#define RVTEST_DATA_BEGIN                      \
    .section .data;                            \
    .align 4;                                  \
    .global begin_testdata;                    \
    begin_testdata:                            \
    RVMODEL_DATA_BEGIN

#define RVTEST_DATA_END                        \
    RVMODEL_DATA_END

#define RVTEST_SIG_SETUP                       \
    .section .tohost, "aw", @progbits;         \
    .align 4;                                  \
    .global tohost;                            \
    tohost: .word 0;                           \
    .global fromhost;                          \
    fromhost: .word 0;                         \
    .section .signature, "aw", @progbits;      \
    .align 4;                                  \
    .global begin_signature;                   \
    begin_signature:                           \
        .fill SIGUPD_COUNT * 4, 1, 0;          \
    .global end_signature;                     \
    end_signature:

#define RVTEST_TESTDATA_LOAD_INT(BaseReg, TargetReg) \
    lw TargetReg, 0(BaseReg);                        \
    addi BaseReg, BaseReg, 4

#define RVTEST_SIGUPD(BaseReg, Scratch1, Scratch2, ValueReg, Label, String) \
    sw ValueReg, 0(BaseReg);                                                \
    addi BaseReg, BaseReg, 4

#endif
