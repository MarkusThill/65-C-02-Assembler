; Berechnet Potenzen x^n mit einem Ergebnis bis zu 128 Byte
; Größe. Dabei wird folgendes Schema angewandt:
; x^2=x*x
; x^4 = (x^2)*(x^2)
; x^8 = (x^4)*(x^4)
; Beispiel:
; 	x^63 = (x^32)*(x^16)*(x^8)*(x^4)*(x^2)*x
; 	Dies erfordert nur 5+5=10 Multipliaktionen, normalerweise
;	wären 62 Multiplikationen erforderlich.
numBytes = 128 ;max is 128

; Pointer
fakA = 80
fakB = 82
prodRes = 84

variableStartAddr= $4500

XYA_TO_STACK.MACRO
; Save registers to stack
	PHA
	TXA
	PHA
	TYA
	PHA
	.ENDM
	
XYA_FROM_STACK.MACRO
; Get old register values from stack
	PLA
	TAY
	PLA
	TAX
	PLA
	.ENDM

	.ORG $4000
main:
	JSR power
	RTS


;====================================================================	
;====================================================================
power:
	XYA_TO_STACK
	
	; Reset result nxtSquare
	LDX #numBytes-1
	LDA #0
power_reset:
	STA result, X
	STA nxtSquare, X
	DEX
	BPL power_reset
	
	; Store #1 in result
	LDA #1
	STA result
	
	; store base in nxtSqaure
	LDA base
	STA nxtSquare
	LDA exponent
power_loop:
	LSR
	PHA
	BCC power_loop_nxtSquare
	; Bit was set, multiply nxtSquare with current result
	
	;Copy result to temporary variable
	LDX #numBytes-1
power_cpyResult:
	LDA result, X
	STA result_tmp, X
	DEX
	BPL power_cpyResult
	
	; Set pointers for multiplication
	LDA #<nxtSquare
	STA fakB
	LDA #>nxtSquare
	STA fakB+1
	
	LDA #<result_tmp
	STA fakA
	LDA #>result_tmp
	STA fakA+1
	
	LDA #<result
	STA prodRes
	LDA #>result
	STA prodRes+1
	
	JSR multi
	
power_loop_nxtSquare:
	JSR square
	PLA
	BNE power_loop
	
	XYA_FROM_STACK
	RTS

;====================================================================	
;====================================================================
square:
	XYA_TO_STACK
	; Copy last result to nxtPwr
	LDX #numBytes-1
square_cpy:
	LDA nxtSquare, X
	STA nxtSquare_tmp, X
	DEX
	BPL square_cpy
	
	; Set pointers for multiplication
	LDA #<nxtSquare_tmp
	STA fakA
	STA fakB
	LDA #>nxtSquare_tmp
	STA fakA+1
	STA fakB+1
	
	LDA #<nxtSquare
	STA prodRes
	LDA #>nxtSquare
	STA prodRes+1
	
	JSR multi
	
	XYA_FROM_STACK
	RTS



	
multi:
	XYA_TO_STACK

	;Reset Result R
	LDY #numBytes-1
	LDA #$00
multi_reset_R:
	STA (prodRes), Y
	DEY
	BPL multi_reset_R


	; Put B to the stack beginning with the highest Byte
	; and check if B=0
	; Stack ; 
	; ----- ;
	; MSB_B ;
	; ..... ; 
	; LSB_B ;
	;       ; <-SP
	LDY #numBytes-1
	LDX #$00 ;count number of Bytes <> 0
multi_BToStack:
	LDA (fakB), Y
	PHA
	BEQ multi_BToStack_1
	INX
multi_BToStack_1:
	DEY
	BPL multi_BToStack
	
	;check if B=0, in this case X=0
	DEX
	BMI multi_end

	; Initialize Loop-Counter
	LDA #0
	PHA
	LDA #numBytes
	PHA
	
	; Multiply with 8 to get Loop-counter
	TSX
	LDY #3
multi_init_LC:
	ASL $0101, X
	ROL $0102, X
	DEY
	BNE multi_init_LC
	
	; auf 2 Byte erweitern!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	; LDA #8*numBytes-1   ;loop-counter
	; PHA
	; BPL multi_mainIn
	
	; Stack ; 
	; ----- ;
	; MSB_B ;
	;MSB_B+1;
	;MSB_B+2; 
	; LSB_B ;
	;  LC_H ;
	;  LC_L ;
	;       ; <-SP
multi_mainLoop:	
multi_mainIn:
	; Check, if we are finished
	;Verbessern
	TSX
	CLC
	LDA $0101, X ;LSB of LC
	SBC #$00
	STA $0101, X
	
	LDA $0102, X ;MSB of LC
	SBC #$00
	STA $0102, X
	
	; If Carry = 0 we end the program
	BCC multi_end_loop
	
	; Shift the result left first
	LDY #0
	LDX #numBytes
	CLC
multi_shift_result:
	LDA (prodRes), Y
	ROL
	STA (prodRes), Y
	INY
	DEX
	BNE multi_shift_result
	
; multi_mainIn:
	; Shift B left
	TSX
	CLC
	LDY #numBytes
multi_shift_B:
	ROL $0103, X
	INX
	DEY
	BNE multi_shift_B
	
	; lsb of B is in C-Flag now
	BCC multi_mainLoop
	
	; C-Flag=1, so add A to the current result
	LDY #0 
	LDX #numBytes 
	CLC
multi_add_A:
	LDA (fakA), Y
	ADC (prodRes), Y ;Add Result to A
	STA (prodRes), Y
	INY
	DEX
	BNE multi_add_A
	BEQ multi_mainLoop
multi_end_loop:
	PLA ;get Loopcounter from stack
	PLA 
multi_end:
	; get numBytes Values: B + Loop-counter from stack
	LDX #numBytes
multi_stack_clean:
	PLA
	DEX
	BNE multi_stack_clean 
	; Get old register values from stack
	NOP
	XYA_FROM_STACK
	RTS
	

	.ORG variableStartAddr
;===================================
result: .Byte $00	
	.ORG variableStartAddr+numBytes
nxtSquare: .Byte $00
	.ORG variableStartAddr+2*numBytes
nxtSquare_tmp: .Byte $00
	.ORG variableStartAddr+3*numBytes
result_tmp: .Byte $00
	.ORG variableStartAddr+4*numBytes
base: .BYTE $29
exponent: .BYTE $BF
; result should be "9cc3182f708d3bd1cbe52c67a45b468dc370625a0cd9cb38eda8e88922f4ec91f33eecfefaa6675d9460b7b83d111bf9e9b9a485dca5ad0f9da997fe20129df7b96038ff252b8b1dff179112196db207d1fbe79e298aad519c20833b6114f71e6215a3c96e56afef12b29d797f07d4c1f99ef9f64fcec8d94d5074ada5217219"
