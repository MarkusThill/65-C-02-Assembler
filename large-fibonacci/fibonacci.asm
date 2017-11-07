; Number of Fibonacci-numbers to be calculated
NUM_ELEMENTS = 90 

;Reserve X Bytes for one fibo-nr and +1 Byte as termination- 
;byte. This constant can be changed by the user. The program 
;can handle these changes by itself
BYTES_PER_NUM = 9 

;Pointer for the program.
p=$80		  
	
;=============================================================
;Main program
;=============================================================
	.ORG $4000
	JSR init_fibo
	JSR fibo
	
	RTS

;=============================================================
;Initializes the program, so that the fibonacci-sequence can 
;be calculated
;=============================================================
init_fibo:
	;set pointer to first element (0) of the Fibonacci-table
	LDA #<fib
	STA p
	LDA #>fib
	STA p+1
	
	;Init the counter for the Fibonacci-numbers
	LDA #NUM_ELEMENTS-1
	STA fib_counter
	
	; Set the first two Fibonacci-numbers to the list
	LDY #BYTES_PER_NUM-1
	LDA #$FF
	STA (p), Y
	INY
	LDA #1
	STA (p), Y
	RTS
;-------------------------------------------------------------

;=============================================================
;Calculate the Fibonacci-Sequence until n=NUM_ELEMENTS by
;using the first two defined values of the sequence 
;=============================================================
fibo:
	
fibo_loop:
	;Calculate next fibonacci-number by summing the last two
	
	;This has to be done for X bytes
	LDX #BYTES_PER_NUM-1
	CLC
byte_loop:
	LDY #0
	LDA (p), Y ;Byte from first Fibonacci-Number
	LDY #BYTES_PER_NUM
	ADC (p), Y ;Byte from second Fibonacci-Number
	LDY #2*BYTES_PER_NUM
	STA (p), Y ;Store result in the new Fibonacci-Number
	
	;Set pointer to next byte
	INC p
	BNE byte_loop_1
	;Higher-byte of pointer has to be incremented as well
	INC p+1 
byte_loop_1: 
	DEX
	BNE byte_loop ; Add next higher byte, if available
	
	; Write termination-byte ($FF)
	LDA #$FF
	STA (p), Y
	
	; Set pointer to next fibonacci-number
	INC p
	BNE comparision
	;Higher-byte of pointer has to be incremented as well
	INC p+1 
	
comparision:
	;Check, if more Fibonacci-numbers have to be calculated
	;and repeat loop if this is the case
	DEC fib_counter
	BNE fibo_loop
	
	RTS
;-------------------------------------------------------------


	.ORG $4500

;Each fibonacci-number consists out of X bytes and one FF-Byte
;as an termination-symbol
fib_counter: .BYTE NUM_ELEMENTS-2
fib: .BYTE 0