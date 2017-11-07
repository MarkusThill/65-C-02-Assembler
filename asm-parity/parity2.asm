
	.ORG $4000
main:
	LDA #$EF
	JSR parity
	
parity:	PHA 	; Save accumulator to stack
	TAX 	; Save accumulator as well to X-register
	TYA 
	PHA 	; save Y-register to stack
	TXA
	LDX #8	; init loop-counter
	LDY #0
loop:	ASL	; check next bit
	BCC cont
	INY 	; increment counter if bit=1
cont:	DEX	; run loop only 8 times
	BNE loop
	TYA	; check if number of bits is even/odd
	AND #1
	TAX	; Result is now in X-register
	PLA
	TAY	; Restore Y-Register
	PLA	; Restore Accumulator
	RTS