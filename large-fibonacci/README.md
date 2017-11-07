# Computing Large Fibonacci-Numbers
### Usage of indirect Addressing, Subroutines, Loops and Tables

Here I developed small program that calculates the n first numbers of the Fibonacci-sequence and stores them in a table, in which the same amount of bytes is reserved for every number.
In mathematical terms, the sequence Fn of Fibonacci numbers is defined by the recurrence relation
F_n=F_(n-1)+F_(n-2)
with the seed values
F_0=0,F_1=1
The program adds one additional byte (representing a termination byte, e.g. $FF)  to every Fibonacci-number in the table, to make it easier to distinguish between the single numbers when reading the table. Depending on the number of Fibonacci numbers that we want to generate, we have to reserve a sufficient amount of bytes for each number. This value has to be set by us in advance.
When creating the table, one pointer p shall be used to read old values and place the new ones. The registers X and Y can be used effectively to solve this problem.
We have two subroutines: An initialization-routine and the routine to calculate the sequence and store it in the table.

The Fibonacci-sequence can also be described as the impulse response of a second-order IIR-Filter (F_n=h[n] ). If the System-function H(z) for the impulse-response is calculated, partial-fraction-decomposition performed and the inverse Z-transform applied, we can obtain the impulse-response h[n] (but now in another form) again and it is possible to calculate every desired Fibonacci-number without knowing F_(n-1) and F_(n-2). This we be described at some point in a blog-post on [markusthill.github.io](markusthill.github.io).
