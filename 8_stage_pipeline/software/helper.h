#ifndef HELPER_H
#define HELPER_H

/**
 * helper.h
 * 
 * Header-only utility library providing software-emulated multiplication,
 * division, and modulo operations for the RV32I processor.
 * 
 * Designed to bypass the missing 'M' (Multiplication) instruction set extension.
 * Defined as static inline to allow inclusion in single-file C compilations
 * without duplicate linker definitions.
 */

#include <stdint.h>

/**
 * Multiplies two 32-bit signed integers using shift-and-add algorithm.
 */
static inline int32_t multiply(int32_t a, int32_t b) {
    uint32_t ua = (a < 0) ? -a : a;
    uint32_t ub = (b < 0) ? -b : b;
    uint32_t res = 0;
    
    while (ub > 0) {
        if (ub & 1) {
            res += ua;
        }
        ua <<= 1;
        ub >>= 1;
    }
    
    return ((a < 0) ^ (b < 0)) ? -(int32_t)res : (int32_t)res;
}

/**
 * Divides two 32-bit unsigned integers using restoring division (shift-and-subtract).
 * Optionally computes the remainder.
 */
static inline uint32_t divide_unsigned(uint32_t dividend, uint32_t divisor, uint32_t *remainder) {
    if (divisor == 0) {
        if (remainder) *remainder = dividend;
        return 0; // Division by zero fallback
    }
    
    uint32_t quotient = 0;
    uint32_t temp_remainder = 0;
    
    for (int i = 31; i >= 0; i--) {
        temp_remainder = (temp_remainder << 1) | ((dividend >> i) & 1);
        if (temp_remainder >= divisor) {
            temp_remainder -= divisor;
            quotient |= (1U << i);
        }
    }
    
    if (remainder) {
        *remainder = temp_remainder;
    }
    
    return quotient;
}

/**
 * Divides two 32-bit signed integers.
 */
static inline int32_t divide(int32_t dividend, int32_t divisor) {
    uint32_t u_dividend = (dividend < 0) ? -dividend : dividend;
    uint32_t u_divisor = (divisor < 0) ? -divisor : divisor;
    
    uint32_t u_quotient = divide_unsigned(u_dividend, u_divisor, 0);
    
    return ((dividend < 0) ^ (divisor < 0)) ? -(int32_t)u_quotient : (int32_t)u_quotient;
}

/**
 * Computes the remainder of dividing two 32-bit signed integers.
 */
static inline int32_t modulo(int32_t dividend, int32_t divisor) {
    uint32_t u_dividend = (dividend < 0) ? -dividend : dividend;
    uint32_t u_divisor = (divisor < 0) ? -divisor : divisor;
    uint32_t u_remainder = 0;
    
    divide_unsigned(u_dividend, u_divisor, &u_remainder);
    
    // In C99/C11, the modulo result takes the sign of the dividend
    return (dividend < 0) ? -(int32_t)u_remainder : (int32_t)u_remainder;
}

#endif // HELPER_H
