Computing the Parity of a Byte

I wrote a short subroutine that determines the odd parity for a given byte. The argument for the routine will be provided in the accumulator, the parity-routine should provide the result (0/1) in the X-register. If temporary variables are needed, then the stack is used and no other memory cells.
It is not allowed to change the accumulator and the Y-register. When leaving the routine, the old values for these registers are restored.
