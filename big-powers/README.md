# Computing huge Powers in Assembler

I wrote a program, that is able to calculate the power a^b with a result R up to 128 Bytes. I defined a and b also as 128 Byte numbers and used the following technique when calculating the powers:

x^2=x*x

x^4=x^2*x^2

x^8=x^4*x^4

And so on.
This method makes it possible to efficiently calculate even big powers. Even the 6502 will be able to calculate the result in a very short time!
To realize the power-function you I first had to to implement a 128 byte multiplication-routine and a square-routine that calculates the power of 2. With these two functions it was fairly easy to implement the powers-function.
To check the results I wrote a JAVA-program that uses the BigInteger-class.
