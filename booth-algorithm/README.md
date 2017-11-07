# Booth's Efficient Multiplication Algorithm

Recently, I had to implement a multiplication routine in 6502 assembler for two integer-factors with the size of one byte, using Booth's multiplication algorithm. Implementing Booth's method itself is not that tricky. However, it took me some time to come up with the following solution, that only requires around 40 lines of code.

As I found, it was important to also write a routine that tests the multiplication for different pre-defined combinations of the two factors. The test also included all extreme-cases and also those cases with at least one factor equal to zero.