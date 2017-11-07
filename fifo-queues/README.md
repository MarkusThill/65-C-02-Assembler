# Implementation of FIFO (First In First Out) Queues in Assembler
Here I uploaded some assembler-code that implements a FIFO (First in, First out)-list for max. 256 bytes. I used the concept of rotating pointers to realize this list. When the FIFO is empty, both pointers (IN and OUT) point to the same byte. After inserting a byte the IN-pointer will be incremented and after reading a byte the OUT-pointer will be incremented. Therefore it is not possible for the OUT-pointer to "overtake" the IN-pointer.
If one pointer reaches the end of the defined memory-area it will be moved to the first memory-cell again.

## A simple FIFO Data-Structure
The following points are considered:
- The size of the FIFO is defined with a constant in the beginning of the program
- If necessary, forbid interrupts if the consistency of the FIFO cannot be guaranteed (e.g. the interrupt-routine could also perform write-operations on the list)
- It is not necessary to use real pointers for IN and OUT, because the max. list-size is 256. It is possible to just use offsets for both pointers.
- Use flags to signalize if the FIFO is full or empty. This has to be done because in both cases IN will be equal to OUT.
- Restore all registers that are not used for return-values when leaving a subroutine.
- Test all subroutines sufficiently.


The following subroutines are implemented (`fifo.asm`):
- initFIFO: Initialize all necessary variables of the FIFO and reset the FIFO (empty FIFO in the beginning)
- writeFIFO: write a byte into the FIFO
  - Parameters: The data-byte in the accumulator
  - Return-value: The success in the X-register (0 on success, 1 if FIFO is already full)
- readFIFO: read a byte from the FIFO
  - Parameters: none
  - Return-values:
    - The data-byte in the accumulator
    - The success of the operation in the X-Register (0 on success, 1 if FIFO is empty)
- countFIFO: Count the elements in the FIFO
  - Parameters: None
  - Return-Value: Number of data-bytes in the FIFO provided in the accumulator.
 
## A Set of FIFO-Lists
In the file `fifo.asm` we already have a framework that implements a single FIFO-list. Now we want extend our framework (file `newFIFO.asm`) in a way that a whole set of FIFO-lists can be used (up to 128 FIFO-lists); The number of FIFOs is  defined with a constant at the beginning of your program.  Each FIFO-list can be accessed by a defined number (0-127) to for instance perform writing or reading operations.
For this purpose the following subroutines are implemented and the notes for the previous FIFO implementation are also taken into account:
- initFIFO: initialize the complete set of FIFOs
- resetFIFO: Empty a specified FIFO
  - Parameters: Nr. Of the FIFO to be emptied in the X-Register
  - Return: Success of the operation in the X-Register (0->OK, 1-> Wrong FIFO-Nr.)
- readFIFO: Read one data-byte from a specified FIFO
  - Parameters: FIFO-Nr. in the X-Register.
  - Return-Values:
    - Accumulator: Data-byte
    - X-Register: Success of the operation (0->OK, 1->Wrong FIFO-Nr., 2->Empty FIFO)
- readFirstFIFO: Read one data-byte from a specified FIFO without removing the element from the list.
  - Parameters: FIFO-Nr. in the X-Register.
  - Return-Values:
    - Accumulator: Data-byte
    - X-Register: Success of the operation (0->OK, 1->Wrong FIFO-Nr., 2->Empty FIFO)
- writeFIFO: Write a data-byte into a specified FIFO
  - Parameters:
    - Accumulator: Data-Byte
    - X-Register: FIFO-Nr.
  - Return-Value: Success in X-Register (0->OK, 1->Wrong FIFO-Nr., 2->Full FIFO)
