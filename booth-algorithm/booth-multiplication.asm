; A little bit shorter version of the program can be created, when using a temporary variable
; instead of the X-Register.
.ORG $4000
main:
CLV
JSR bMult	; Perform multiplication A*B with the booth-method.
LDA R+1		; Load higher-Byte of result to Accumulator.
LDX R		; Load lower-Byte of result to X-Register
RTS		; Stop program.


bMult:	LDA A	; Load first operand.
BEQ bMultE	; stop if first operand is 0.
STA R		; store in lower byte of result. Will be shifted out of it later.
ASL		; Determine positions where additions or subtractions have to
EOR A		; be performed by using XOR. For every 1 in the X-Register a
TAX		; addition or subtraction has to be performed!
LDY #8		; Loop-Counter
bLoop: BVS bOvflw ; If B=$80 we get an overflow for the first subtraction, ignore sign!
LDA R+1		; Roll Result to the right. Remember that A is in the lower Byte,
ASL		; by shifting the next A-Bit into the carry flag we can determine
bOvflw:	ROR R+1	; later, what operation has to be performed (Addition or subtration);
ROR R		; The Carry-Flag first has to be saved to the stack, because it will
PHP		; be changed in the following lines. [*(1)]
TXA		; Shift X-Register to the right. By doing this we can check if any
LSR		; operation has to be performed (Addition/Subtraction). This is the
TAX		; case if the Carry-Flag is equal to 1.
PLA		; Restore Status-Register from *(1) to Accumulator.
BCC bLoopE	; Branch if no addition/subtraction has to be done...
LSR		; By shifting accumulator we get the old Carry-Flag from (*1).
LDA R+1		; Load result
BCC bAdd	; We can now decide if we have to add or subtract. Branch if we add.
SBC B		; Do a subtraction. We do not have to set the Carry-flag explicitly,
JMP bCont	; because we are sure the C-Flag is already set (based on the branch).
bAdd: ADC B	; Perform an addition. We do not have to reset the Carry-flag
bCont: STA R+1	; Store result of addition/subtraction.
bLoopE: DEY	; Decrement loop-counter.
BPL bLoop       ; Do loop exactly 8 times.
bMultE: RTS	; leave this subroutine. The result is in the variable R.

.ORG $4500
A: .BYTE $AA	; First factor. 1 Byte.
B: .BYTE $81	; Second factor. 1 Byte.
R: .WORD $0000	; The result. Needs two bytes.
