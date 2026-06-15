/**
 * MMIO Test Program for 8-stage RISC-V CPU
 * 
 * Features:
 * - Reads 10 physical switches and displays their decimal value 
 *   on the right 4 HEX displays.
 * - Uses the 2 pushbuttons to control a 2-digit decimal counter 
 *   on the left 2 HEX displays (Button 1: Increment, Button 0: Reset).
 * - Maps the 10 switches directly to the 10 LEDs.
 * 
 * Note: Avoids hardware division (%, /) to prevent linking errors 
 * against libgcc when compiled bare-metal (-nostdlib).
 */

#include <stdint.h>

// MMIO Base Addresses
#define LEDR (*(volatile uint32_t *)0x80000000)
#define HEX  (*(volatile uint32_t *)0x80000004)
#define SW   (*(volatile uint32_t *)0x80000008)
#define KEY  (*(volatile uint32_t *)0x8000000C)

/**
 * Converts a binary value (0-9999) to a 4-digit BCD format.
 * Uses repeated subtraction to avoid requiring a division library.
 */
uint32_t bin_to_bcd4(uint32_t val) {
    uint32_t thousands = 0, hundreds = 0, tens = 0, ones = 0;
    
    while (val >= 1000) { val -= 1000; thousands++; }
    while (val >= 100)  { val -= 100;  hundreds++;  }
    while (val >= 10)   { val -= 10;   tens++;      }
    ones = val;
    
    return (thousands << 12) | (hundreds << 8) | (tens << 4) | ones;
}

/**
 * Converts a binary value (0-99) to a 2-digit BCD format.
 */
uint32_t bin_to_bcd2(uint32_t val) {
    uint32_t tens = 0, ones = 0;
    
    while (val >= 10) { val -= 10; tens++; }
    ones = val;
    
    return (tens << 4) | ones;
}

int main() {
    uint32_t counter = 0;
    
    // The keys on DE10-Lite are active LOW (1 = unpressed, 0 = pressed).
    // We initialize last_keys to 3 (both keys unpressed) to prevent an initial trigger.
    uint32_t last_keys = 3; 

    while (1) {
        // Read current MMIO inputs
        uint32_t current_sw = SW & 0x3FF; // Mask to 10 switches
        uint32_t current_keys = KEY & 0x3; // Mask to 2 keys

        // Map switches directly to LEDs
        LEDR = current_sw;

        // Key Edge Detection (Falling Edge)
        // KEY[0] (Bit 0): Reset counter
        if ((last_keys & 1) && !(current_keys & 1)) {
            counter = 0;
        }
        
        // KEY[1] (Bit 1): Increment counter
        if ((last_keys & 2) && !(current_keys & 2)) {
            counter++;
            if (counter > 99) {
                counter = 0;
            }
        }

        // Store the state for edge detection in the next loop
        last_keys = current_keys;

        // Convert state to BCD for the seven-segment displays
        uint32_t sw_bcd = bin_to_bcd4(current_sw);
        uint32_t count_bcd = bin_to_bcd2(counter);

        // Update the displays
        // HEX register expects [23:20] for HEX5, [19:16] for HEX4, etc.
        HEX = (count_bcd << 16) | sw_bcd;

        // Delay loop for basic pushbutton debouncing
        for (volatile int i = 0; i < 50000; i++) {
            // Do nothing
        }
    }

    return 0; 
}
