	.START $4000
	.INCLUDE ".\myStack.65s"
	
	.ORG $4000
;==========================================================
main:
	NOP
	JSR myStackInit
	
	_JSR testFunc
	NOP
	NOP
	NOP
	NOP
	NOP
	LDX n
	LDY k
	
	CPX #3
	; stop, if n>2 (not allowed)
	BCS main_end
	_JSR ackerm
	
	NOP
	NOP
	NOP
main_end:
	RTS
;==========================================================
	

;==========================================================
testFunc:
	NOP
	NOP
	_RTS
;==========================================================


;==========================================================
ackerm:
	; check Y-Register (k)
	; check if k=0
	TYA ; just some OP to set flags
	BNE kNEQZ
	; k=0, so stop
	LDA x
	JMP end

kNEQZ: 	
	; return k+x if n=0
	TXA
	BNE nNEQZ
	;n=0, stop
	CLC
	TYA ; k->Akku
	ADC x
	JMP end ; return k+x in accu
	
nNEQZ:
	; k<>0 && n<>0, so call ackermann again
	; n-1
	TAX
	DEX
	_PHX ; put n-1 on stack first

	; call A(n, k-1)
	INX ; to get n again
	DEY ; k-1
	_JSR ackerm
	; Result of A(n, k-1) is in accumulator
	
	TAY ; move to Y-Register (k)
	_PLX ; get n-1 from stack again
	_JSR ackerm
	; Result is in accumulator
	
end:
	_RTS
;==========================================================
	

	.ORG $4200
n: .BYTE 2
k: .BYTE 5
x: .BYTE 2  

; for x=1
; A(1, 20) = 21
; A(1, 55) = 56

; for x=2, n=1
; A(1, 20) = 42
; A(1, 50) = 102
; A(1, 55) = 112
; A(1, 60) = 122
; A(1, 70) = 142
; A(1, 80) = 162
; A(1, 84) = 170
; A(1, 85) = 172 ;max possible for n=1

; for x=2, n=2
; A(2, 1) = 6
; A(2, 2) = 14
; A(2, 3) = 30
; A(2, 4) = 62
; A(2, 5) = 126 ;max. possible for n=2
	
; ======================================================	