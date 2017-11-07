_myStackAddr = $7000
_myStackSize = 2000
_mySP = $80
	
; ======================================================
_JSR.MACRO FUNC	
.label1:
	PHP
	PHA
	CLC
	LDA #<.label1
	ADC #22 ;22 bytes until end of this macro
	JSR _myPHA
	LDA #>.label1
	ADC #0
	JSR _myPHA
	PLA
	PLP
	JMP FUNC	
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_RTS.MACRO
	PHP
	SEI
	PHA
	JSR _myPLA
	STA _myTmpAddr+1
	JSR _myPLA
	STA _myTmpAddr
	CLI
	PLA
	CLI
	PLP
	JMP (_myTmpAddr)
	.ENDM
; ------------------------------------------------------

; ======================================================
_PHA.MACRO
	JSR _myPHA
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_PLA.MACRO
	JSR _myPLA
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_PHX.MACRO
	JSR _myPHX
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_PLX.MACRO
	JSR _myPLX
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_PHY.MACRO
	JSR _myPHY
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_PLY.MACRO
	JSR _myPLY
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_PHP.MACRO
	JSR _myPHP
	.ENDM
; ------------------------------------------------------
	
; ======================================================
_PLP.MACRO
	JSR _myPLP
	.ENDM
; ------------------------------------------------------
	
; ======================================================
INCP.MACRO
	INC _mySP
	BNE .INCP_END
	INC _mySP+1
.INCP_END:
	.ENDM
; ------------------------------------------------------
	
; ======================================================
DECP.MACRO
	DEC _mySP
	INC _mySP
	BNE .INCP_END
	DEC _mySP+1
.INCP_END:
	DEC _mySP
	.ENDM
; ------------------------------------------------------
	
	
	.ORG _myStackAddr

; ======================================================
myStackInit:
	LDA #<_myStack
	STA _mySP
	LDA #>_myStack
	STA _mySP+1
	RTS
; ------------------------------------------------------

; ======================================================
	;TODO: Stack-overflow
_myPHA:
	SEI
	PHP
	STA _myTmp
	PHA
	TYA
	PHA
	LDY #0
	LDA _myTmp
	STA (_mySP), Y
	INCP
	PLA
	TAY
	PLA
	PLP
	CLI
	RTS
; ------------------------------------------------------
	

; ======================================================
	;TODO: Stack-"Underflow"
_myPLA:
	SEI
	DECP
	TYA
	PHA
	LDY #0
	LDA (_mySP), Y
	STA _myTmp
	PLA
	TAY
	LDA _myTmp
	CLI
	RTS
; ------------------------------------------------------
	

; ======================================================
_myPHX:
	SEI
	PHP
	PHA
	TYA
	PHA
	TXA
	LDY #0
	STA (_mySP), Y
	INCP
	PLA
	TAY
	PLA
	PLP
	CLI
	RTS
; ------------------------------------------------------
	

; ======================================================
_myPLX:
	SEI
	DECP
	PHA
	TYA
	PHA
	LDY #0
	LDA (_mySP), Y
	STA _myTmp
	PLA
	TAY
	PLA
	LDX _myTmp ;set corresponding flags
	CLI
	RTS
; ------------------------------------------------------
	

; ======================================================
_myPHY:
	SEI
	PHP
	PHA
	TYA
	LDY #0
	STA (_mySP), Y
	INCP
	TAY
	PLA
	PLP
	CLI
	RTS
; ------------------------------------------------------
	

; ======================================================
_myPLY:
	SEI
	DECP
	PHA
	LDY #0
	LDA (_mySP), Y
	STA _myTmp
	PLA
	LDY _myTmp ;set corresponding flags
	CLI
	RTS
; ------------------------------------------------------
	

; ======================================================
_myPHP:
	PHP
	SEI
	PHA
	TXA
	PHA
	TYA
	PHA
	TSX
	LDA $0104, X
	LDY #0
	STA (_mySP), Y
	INCP
	PLA
	TAY
	PLA
	TAX
	PLA
	
	; CLI; not needed bcause of PLP
	PLP
	RTS
; ------------------------------------------------------
	

; ======================================================
_myPLP:
	SEI
	DECP
	STA _myTmp+1
	TYA
	PHA
	LDY #0
	LDA (_mySP), Y
	; Optional: Delete B-Flag again
	AND #$EF
	STA _myTmp
	PLA
	TAY
	LDA _myTmp
	PHA
	LDA _myTmp+1
	PLP
	RTS
; ------------------------------------------------------
	
	
_myTmp: .RS 2
_myTmpAddr: .RS 2 ;use only for Return addresses in myRTS!!!
_myStack: .RS _myStackSize