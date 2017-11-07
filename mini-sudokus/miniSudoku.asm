; Field is stored in a 1-dim. array
;|-----------------|
;| 00, 01 | 02, 03 |
;| 04, 05 | 06, 07 |
;|--------+--------|
;| 08, 09 | 10, 11 |
;| 12, 13 | 14, 15 |
;|-----------------|

; Pointer 
p = $80
FIELD_SIZE = 16 
CELLS_PER_ROW = 4
CELLS_PER_COL = 4
NUM_DIGITS = 4

currentSudoku = sudoku16

;====================================================================
; Macros
;====================================================================
SAXY_TO_STACK.MACRO sS, sA, sX, sY
	.IF sS
	PHP
	.ENDIF
	.IF sA
	PHA
	.ENDIF
	.IF sX
	TXA
	PHA
	.ENDIF
	.IF sY
	TYA
	PHA
	.ENDIF
	.ENDM
	
SAXY_FROM_STACK.MACRO sS, sA, sX, sY
	.IF sY
	PLA
	TAY
	.ENDIF
	.IF sX
	PLA
	TAX
	.ENDIF
	.IF sA
	PLA
	.ENDIF
	.IF sS
	PLP
	.ENDIF
	.ENDM
	
	.ORG $4000
main:
	; SAXY_TO_STACK 1,1,1,1
	; JSR IS_FULL_TEST
	; JSR IS_LEGAL_COL_TEST
	; JSR IS_LEGAL_HOUSE_TEST
	; JSR IS_LEGAL_BOARD_TEST
	; JSR init
	LDA #<currentSudoku ;defined above
	STA p
	LDA #>currentSudoku
	STA p+1
	JSR init
	JSR solve
	RTS
;--------------------------------------------------------------------	

;====================================================================
; 1. copy given Sudoku referenced by Pointer p to array field 
;====================================================================
init:
	SAXY_TO_STACK 1,1,1,1
	
	; reset field
	; LDY #FIELD_SIZE-1
	; LDA #0
; init_resetField:
	;STA field, Y
	; DEY
	; BPL init_resetField
	
	; copy content of referenced input-field to field
	LDY #FIELD_SIZE-1
init_cpy_field:
	LDA (p), Y
	STA field, Y
	DEY
	BPL init_cpy_field
	
	SAXY_FROM_STACK 1,1,1,1
	RTS
;--------------------------------------------------------------------	

;====================================================================
; Solve the Sudoku given in the array "field"
; Parameters:
;	None
; Return:
;	AKKU: True(1) if Sudoku could be solved, otherwise False (0) 
;		Alternative is the Zero-Flag
; Temporary variables used:
; 	none
;====================================================================	
solve:
	SAXY_TO_STACK 0,0,1,1
	
	LDA #0
	PHA	; start at index 0
	PHA	; digit
	
	; check, if board is full, then we have a solution
	JSR is_full
	BEQ solve_nextCell
	
	; We have a solution
	SEC
	BCS solveEnd
	
solve_nextCell:	;loop
	TSX
	LDA $0102, X	;load index
	TAY
	
	; Check, if current cell is empty
	LDA field, Y
	BNE solve_nextCellEnd ;continue with next cell, if not empty
	
	LDA #1
	STA $0101, X	; load digit
solve_nextDigit:	
	
	STA field, Y	; set current cell
	; check, if it is a legal move
	JSR isLegalBoard
	BEQ solve_nextDigitEnd ; continue, if not legal
	JSR solve
	SEC ; if we have a solution, use Carry to indicate this
	BNE solveEnd ; stop, if we have a solution
solve_nextDigitEnd:
	; continue with next digit
	INC $0101, X
	LDA $0101, X
	CMP #NUM_DIGITS+1
	BMI solve_nextDigit
	; delete cell again
	LDA #0
	STA field, Y
	
	; All digits were tried, end routine
	CLC ; we could not solve yet
	BEQ solveEnd
	
solve_nextCellEnd:
	INC $0102, X
	LDA #FIELD_SIZE
	CMP $0102, X
	BPL solve_nextCell
	
	CLC ; C-Flag needed to decide on return value
solveEnd:
	PLA ; get index-counter from stack
	PLA ; get digit-counter from stack
	SAXY_FROM_STACK 0,0,1,1
	LDA #0	;return value for no solution yet
	BCC solveEndNoSolution
	
	LDA #1 ; we found the solution
solveEndNoSolution:
	RTS
;--------------------------------------------------------------------	


;====================================================================
; Check if the given house (0-3) is legal. 
; Empty cells are considered as legal. 
; Parameters:
;	None
; Return:
;	AKKU: True(1) or False (0), Alternative is the Zero-Flag
; Temporary variables used:
; 	return+1:		Return-value
;====================================================================
isLegalBoard:
	SAXY_TO_STACK 0,1,1,1
	
	LDA #0
	STA return+1 ;return+1 is not used by called subroutines
	
	LDX #3
isLegalBoardLoop:
	TXA
	JSR isLegalHouse
	BEQ isLegalBoardEnd
	TXA
	JSR isLegalCol
	BEQ isLegalBoardEnd
	TXA
	JSR isLegalRow	
	BEQ isLegalBoardEnd
	DEX
	BPL isLegalBoardLoop
	INC return+1
	
isLegalBoardEnd:
	SAXY_FROM_STACK 0,1,1,1
	LDA return+1
	RTS
;--------------------------------------------------------------------	
	
	

;====================================================================
; Check if the given house (0-3) is legal. 
; Empty cells are considered as legal. 
; Parameters:
;	AKKU: House to be checked
; Return:
;	AKKU: True(1) or False (0), Alternative is the Zero-Flag
; Temporary variables used:
; 	return:		Return-value
;	counter:	Offset/temporary
;====================================================================
	;|-----------------|
	;| 00, 01 | 02, 03 |
	;| 04, 05 | 06, 07 |
	;|--------+--------|
	;| 08, 09 | 10, 11 |
	;| 12, 13 | 14, 15 |
	;|-----------------|
isLegalHouse:
	SAXY_TO_STACK 0,1,1,1
	
	LDA #0
	STA counter ;offset for even houses
	STA return 
	
	; Get starting index
	TSX
	LDA $0103, X
		
	LSR ;C-Flag is set for odd house
	BCC isLegalHouse_EvenHouse
	INC counter 
	INC counter ;Add offset of 2 for odd house
isLegalHouse_EvenHouse:	
	ASL
	ASL
	ASL
	ADC counter
	;STA counter  ;now we have the starting-index of our house
	
	; Compare first cell with next three cells
	TAX
	TAY
	
	; calc indexes of all cells of this house
	INY
	STY counter
	INY
	INY
	INY
	STY counter+1
	INY
	STY counter+2
	
	; Compare
	LDY counter
	LDA field, X
	BEQ isLegalHouse_EvenHouse_Cell2
	CMP field, Y
	BEQ isLegalHouseEnd ; Error if 1st equal to 2nd cell
	LDY counter+1
	CMP field, Y
	BEQ isLegalHouseEnd ; Error if 1st equal to 3rd cell
	INY
	CMP field, Y
	BEQ isLegalHouseEnd ; Error if 1st equal to 4th cell
	
isLegalHouse_EvenHouse_Cell2:
	; Compare 2nd cell with next two cells
	INX
	LDA field, X
	BEQ isLegalHouse_EvenHouse_Cell3
	LDY counter+2
	CMP field, Y
	BEQ isLegalHouseEnd ; Error if 2nd equal to 4th cell
	DEY
	CMP field, Y
	BEQ isLegalHouseEnd ; Error if 2nd equal to 3rd cell

isLegalHouse_EvenHouse_Cell3:
	; Compare 3rd cell with last cell
	LDY counter+1
	LDA field, Y
	BEQ isLegalHouseTrue
	INY
	CMP field, Y
	BEQ isLegalHouseEnd ; Error if 3rd equal to 4th cell

isLegalHouseTrue:	
	INC return
		
isLegalHouseEnd:	
	SAXY_FROM_STACK 0,1,1,1
	; Load Return-value to akku
	LDA return
	RTS
;--------------------------------------------------------------------



;====================================================================
; Check if the given column (0-3) is legal. If the column contains a 
; duplicate digit. Empty cells are considered as legal. 
; Parameters:
;	AKKU: Column to be checked
; Return:
;	AKKU: True(1) or False (0), Alternative is the Zero-Flag
; Temporary variables used:
; 	return:		Return-value
;	counter:	loop-counter outer-loop
;	counter+1:	loop-counter inner-loop
;	index:		second-last index of current column
;	index+1:	;last index of current column
;====================================================================
	;|-----------------|
	;| 00, 01 | 02, 03 |
	;| 04, 05 | 06, 07 |
	;|--------+--------|
	;| 08, 09 | 10, 11 |
	;| 12, 13 | 14, 15 |
	;|-----------------|
isLegalCol:
	SAXY_TO_STACK 0,1,1,1
	
	; Set return value, initially zero
	LDA #0
	STA return
	
	; Get starting index
	TSX
	LDA $0103, X
	STA counter
	
	; calc second-last index of current column
	CLC
	ADC #CELLS_PER_ROW*2
	STA index ;second-last index of current column
	
	; calc last index of current column
	ADC #CELLS_PER_ROW
	STA index+1 ;last index of current column
	
	; <outerLoop>
isLegalCol_checkLoop:
	CLC
	LDA counter
	TAY
	ADC #CELLS_PER_ROW
	STA counter+1
	
	; <innerLoop>
isLegalCol_countDigits:
	LDX counter+1
	LDA field, Y
	BEQ isLegalCol_checkLoopEnd
	CMP field, X
	BEQ isLegalColEnd ;If Digit is found again, return error
	
	CLC
	LDA counter+1
	ADC #CELLS_PER_ROW
	STA counter+1
	
	LDA index+1
	CMP counter+1
	
	BCS isLegalCol_countDigits
	; </innerLoop>
	
isLegalCol_checkLoopEnd:
	CLC
	LDA counter
	ADC #CELLS_PER_ROW
	STA counter
	
	LDA index
	CMP counter
	BCS isLegalCol_checkLoop
	; </outerLoop>
	INC return
	
isLegalColEnd:
	SAXY_FROM_STACK 0,1,1,1
	; Load Return-value to akku
	LDA return
	RTS

;====================================================================
; Check if the given row (0-3) is legal. If the row contains a 
; duplicate digit. Empty cells are considered as legal. 
; Parameters:
;	AKKU: Row to be checked
; Return:
;	AKKU: True(1) or False (0), Alternative is the Zero-Flag
; Temporary variables used:
; 	index: 	 starting index of next row
;	index+1: Last index of current row
;	return:	Return-value
;====================================================================
	;|-----------------|
	;| 00, 01 | 02, 03 |
	;| 04, 05 | 06, 07 |
	;|--------+--------|
	;| 08, 09 | 10, 11 |
	;| 12, 13 | 14, 15 |
	;|-----------------|
isLegalRow:
	SAXY_TO_STACK 0,1,1,1
	
	; Set return value, initially zero
	LDA #0
	STA return
	
	; Multiply with 4, to get starting index
	TSX
	LDA $0103, X
	ASL
	ASL
	TAX ;Use X for outer loop
	
	; Add 4 to get first index of the next row
	CLC
	ADC #CELLS_PER_ROW
	STA index
	
	; Add 3 to get last index of current row
	STA index+1
	DEC index+1
	
	; <Outer loop>
isLegalRow_checkLoop:
	TXA
	TAY ; Use Y for inner loop
	INY ; start to compare with next cell
	LDA field, X ;search for this digit
	; continue, if digit=0
	BEQ isLegalRow_CheckLoopEnd
	
	; <Inner loop>
isLegalRow_countDigits:
	CMP field, Y
	BEQ isLegalRow_End ; Same digit found, we have an illegal row
	INY
	CPY index
	BNE isLegalRow_countDigits
	; </Inner loop>
	
isLegalRow_CheckLoopEnd:
	INX
	CPX index+1
	BNE isLegalRow_checkLoop
	; </Outer loop>
	INC return
	
isLegalRow_End:

	SAXY_FROM_STACK 0,1,1,1
	; Load Return-value to akku
	LDA return
	RTS

;====================================================================
;Tests, if the sudoku-field is completly filled. It doesnt check for
;inconsistencys, only if every cell is unequal to zero. The result
;is returned in the AKKU (0, if not completly full, 1 otherwise). 
;After call of this function the zero-flag can be used for further
;processing in the calling routine.
;====================================================================	
is_full:
	LDA #0 ; assume, field is not full 
	;        -> return value is false (0)
	SAXY_TO_STACK 0,1,1,1
	
	LDX #FIELD_SIZE-1
is_full_loop:
	;Check, if cell is empty and leave loop, if this is the case
	LDY field, X
	BEQ is_full_end
	;Cell was not empty, so check next cell
	DEX
	BPL is_full_loop ;only continue for X >= 0
	
	; All cells were filled, so the field is full
	; Set the return-value to true (1)
	TSX 
	INC $0103, X
	
is_full_end:
	SAXY_FROM_STACK 0,1,1,1
	RTS
;--------------------------------------------------------------------	


;====================================================================
; Tests the is_full() subroutine. Returns $1 on success and $00
; in case of an error.
;====================================================================	
IS_FULL_TEST:
	LDX #FIELD_SIZE
IS_FULL_TEST_LOOP:
	; Check, if result of is_full() is false
	JSR is_full
	BNE IS_FULL_TEST_ERROR
	
	LDA #1
	STA field-1, X
	
	DEX
	BNE IS_FULL_TEST_LOOP
	
	; Check if result equals to true
	JSR is_full
	BNE IS_FULL_TEST_END
	
IS_FULL_TEST_ERROR:
	LDA #$0
	RTS
	
IS_FULL_TEST_END:
	LDA #$1
	RTS
;--------------------------------------------------------------------	


;====================================================================
; tests the function isLegalRow. Returns 0 on an error, otherwise 1
; in the accumulator
;====================================================================
IS_LEGAL_ROW_TEST:
	JSR init
	
	;-----------------------------------------------------------
	; Set first cell to 1
	LDA #1
	STA field
	
	PHA ; return value
	
	; Test 1
	LDY #CELLS_PER_COL-1
IS_LEGAL_ROW_TEST_T1:
	TYA
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERR1
	DEY
	BPL IS_LEGAL_ROW_TEST_T1
	BMI IS_LEGAL_ROW_TEST_TEST2

IS_LEGAL_ROW_TEST_ERR1:
	JMP IS_LEGAL_ROW_TEST_ERROR
	

	;-----------------------------------------------------------
IS_LEGAL_ROW_TEST_TEST2:
	; Set second cell to 1
	LDA #1
	STA field+3
	
	; Test 2
	LDA #0
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERR1 ; we expect an error
	
	LDY #CELLS_PER_COL-1
IS_LEGAL_ROW_TEST_T2:
	TYA
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERR1
	DEY
	BNE IS_LEGAL_ROW_TEST_T2
	BEQ IS_LEGAL_ROW_TEST_TEST3
	
	;-----------------------------------------------------------
IS_LEGAL_ROW_TEST_TEST3:
	LDA #3 ; write to last cell of second row
	STA field+7
	
	LDA #0
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERR1 ; we expect an error
	
	LDY #CELLS_PER_COL-1
IS_LEGAL_ROW_TEST_T3:
	TYA
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERR1
	DEY
	BNE IS_LEGAL_ROW_TEST_T3
	
	;-----------------------------------------------------------
	LDA #3 ; write to last but one cell of second row
	STA field+6
	
	LDA #0
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERR1 ; expect error for first row
	
	LDA #1
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERR1 ; expect error for second row
	
	LDA #2
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERR1 ; expect no error for third row
	
	LDA #3
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERR1 ; expect no error for fourth row
	
	;-----------------------------------------------------------
	LDA #1 ; write to last but one cell of second row
	STA field+6
	
	LDA #0
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERR1 ; expect error for first row
	
	LDA #1
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERROR ; expect no error for second row
	
	LDA #2
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERROR ; expect no error for third row
	
	LDA #3
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERROR ; expect no error for fourth row
	
	;-----------------------------------------------------------
	LDA #3 
	STA field+5
	
	LDA #0
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for first row
	
	LDA #1
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for second row
	
	LDA #2
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERROR ; expect no error for third row
	
	LDA #3
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERROR ; expect no error for fourth row
	
	;-----------------------------------------------------------
	LDA #4 
	STA field+12
	STA field+13
	
	LDA #0
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for first row
	
	LDA #1
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for second row
	
	LDA #2
	JSR isLegalRow
	BEQ IS_LEGAL_ROW_TEST_ERROR ; expect no error for third row
	
	LDA #3
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for fourth row
	
	;-----------------------------------------------------------
	LDA #3 
	STA field+9
	STA field+10
	
	LDA #0
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for first row
	
	LDA #1
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for second row
	
	LDA #2
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for third row
	
	LDA #3
	JSR isLegalRow
	BNE IS_LEGAL_ROW_TEST_ERROR ; expect error for fourth row
	BEQ IS_LEGAL_ROW_TEST_END
	
	
	; ERROR
IS_LEGAL_ROW_TEST_ERROR:
	TSX
	DEC $0101, X
IS_LEGAL_ROW_TEST_END:
	PLA
	RTS
	
	
;====================================================================
; tests the function isLegalCol. Returns 0 on an error, otherwise 1
; in the accumulator
;====================================================================
IS_LEGAL_COL_TEST:
	JSR init
	
	;------------------------------------------
	; Test 1
	LDA #1
	STA field+15
	PHA ; return value
	
	LDA #0
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #1
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #3
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	;------------------------------------------
	; Test 2
	LDA #1
	STA field+7
	
	LDA #0
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #1
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	;------------------------------------------
	; Test 3
	LDA #2
	STA field+11
	
	LDA #0
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #1
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	;------------------------------------------
	; Test 4
	LDA #2
	STA field+1
	
	LDA #0
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #1
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	JMP IS_LEGAL_COL_TEST_TEST5
	
IS_LEGAL_COL_TEST_ERROR:
	JMP IS_LEGAL_COL_TEST_ERROR1
	
IS_LEGAL_COL_TEST_TEST5:
	;------------------------------------------
	; Test 5
	LDA #2
	STA field+5
	
	LDA #0
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #1
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	;------------------------------------------
	; Test 6
	LDA #4
	STA field+12
	
	LDA #0
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #1
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	;------------------------------------------
	; Test 7
	LDA #4
	STA field
	
	LDA #0
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	LDA #1
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR
	
	;------------------------------------------
	; Test 8
	LDA #1
	STA field+2
	LDA #3
	STA field+10
	
	LDA #0
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR1
	
	LDA #1
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR1
	
	LDA #2
	JSR isLegalCol
	BEQ IS_LEGAL_COL_TEST_ERROR1
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR1
	
	;------------------------------------------
	; Test 9
	LDA #3
	STA field+14
	
	LDA #0
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR1
	
	LDA #1
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR1
	
	LDA #2
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR1
	
	LDA #3
	JSR isLegalCol
	BNE IS_LEGAL_COL_TEST_ERROR1
	BEQ IS_LEGAL_COL_TEST_END
	

IS_LEGAL_COL_TEST_ERROR1:
	TSX
	DEC $0101, X

IS_LEGAL_COL_TEST_END:	
	PLA	
	RTS
	

;====================================================================
; tests the function isLegalHouse. Returns 0 on an error, otherwise 1
; in the accumulator
;====================================================================
IS_LEGAL_HOUSE_TEST:
	JSR init
	
	LDA #1
	PHA ; return value
	
	;-----------------------------------------------------------
	; Test 1
	STA field
	
	LDA #0
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #1
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	;-----------------------------------------------------------
	; Test 2
	LDA #1
	STA field+5
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #1
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	;-----------------------------------------------------------
	; Test 3
	LDA #2
	STA field+5
	
	LDA #1
	STA field+4
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #1
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	BNE IS_LEGAL_HOUSE_TEST4

IS_LEGAL_HOUSE_TEST_ERROR:
	JMP IS_LEGAL_HOUSE_TEST_ERROR1
	

IS_LEGAL_HOUSE_TEST4:
	;-----------------------------------------------------------
	; Test 4
	LDA #2
	STA field+4
	
	LDA #1
	STA field+1
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #1
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	;-----------------------------------------------------------
	; Test 5
	LDA #2
	STA field+1
	STA field+7
	
	LDA #1
	STA field+5
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #1
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	;-----------------------------------------------------------
	; Test 6
	LDA #1
	STA field+2
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #1
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR
	BNE IS_LEGAL_HOUSE_TEST6
	
IS_LEGAL_HOUSE_TEST_ERROR2:
	JMP IS_LEGAL_HOUSE_TEST_ERROR1
	
IS_LEGAL_HOUSE_TEST6:
	;-----------------------------------------------------------
	; Test 6
	LDA #2
	STA field+6
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR2
	
	;-----------------------------------------------------------
	; Test 7
	LDA #2
	STA field+3
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR2
	
	;-----------------------------------------------------------
	; Test 8
	LDA #2
	STA field+2
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR2
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR2
	BNE IS_LEGAL_HOUSE_TEST9

IS_LEGAL_HOUSE_TEST_ERROR3:
	JMP IS_LEGAL_HOUSE_TEST_ERROR1	

IS_LEGAL_HOUSE_TEST9:
	;-----------------------------------------------------------
	; Test 9
	LDA #3
	STA field+3
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR3
	
	;-----------------------------------------------------------
	; Test 10
	LDA #1
	STA field+8
	
	LDA #2
	STA field+9
	
	LDA #3
	STA field+12
	
	LDA #4
	STA field+13
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #2
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR3
	
	;-----------------------------------------------------------
	; Test 11
	LDA #1
	STA field+13
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #2
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR3
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR3
	
	;-----------------------------------------------------------
	; Test 12
	LDA #1
	STA field+10
	
	LDA #2
	STA field+14
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #2
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR1
	
	;-----------------------------------------------------------
	; Test 13
	LDA #3
	STA field+11
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #2
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #3
	JSR isLegalHouse
	BEQ IS_LEGAL_HOUSE_TEST_ERROR1
	
	;-----------------------------------------------------------
	; Test 14
	LDA #3
	STA field+15
	
	LDA #0
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #1
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #2
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	
	LDA #3
	JSR isLegalHouse
	BNE IS_LEGAL_HOUSE_TEST_ERROR1
	BEQ IS_LEGAL_HOUSE_TEST_END
	
	
IS_LEGAL_HOUSE_TEST_ERROR1:
	TSX
	DEC $0101, X
	
IS_LEGAL_HOUSE_TEST_END:
	PLA
	RTS
	
	
	
IS_LEGAL_BOARD_TEST:
	JSR init
	
	LDA #1
	PHA
	
	;--------------------------------------------
	;Test 1
	;|---------------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 0 |
	;|---------------|
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 1
	;|---------------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 1 | 0 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 0 |
	;|---------------|
	LDA #1
	STA field+5
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 2
	;|---------------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 1 | 0 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #2
	STA field+15
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 3
	;|---------------|
	;| 0 , 0 | 0 , 2 |
	;| 0 , 1 | 0 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #2
	STA field+3
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 4
	;|---------------|
	;| 0 , 0 | 0 , 4 |
	;| 0 , 1 | 0 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #4
	STA field+3
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 5
	;|---------------|
	;| 0 , 0 | 0 , 4 |
	;| 0 , 1 | 4 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #4
	STA field+6
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 6
	;|---------------|
	;| 0 , 0 | 0 , 4 |
	;| 0 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #3
	STA field+6
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 7
	;|---------------|
	;| 0 , 0 | 0 , 4 |
	;| 3 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #3
	STA field+4
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 8
	;|---------------|
	;| 0 , 0 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #4
	STA field+4
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 9
	;|---------------|
	;| 0 , 4 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #4
	STA field+1
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 10
	;|---------------|
	;| 0 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #2
	STA field+1
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 11
	;|---------------|
	;| 1 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #1
	STA field
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR

	;--------------------------------------------
	;Test 12
	;|---------------|
	;| 3 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 0 , 0 | 0 , 2 |
	;|---------------|
	LDA #3
	STA field
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	BNE IS_LEGAL_BOARD_TEST12
	

IS_LEGAL_BOARD_TEST_ERROR:
	JMP IS_LEGAL_BOARD_TEST_ERROR1
	

IS_LEGAL_BOARD_TEST12:
	;--------------------------------------------
	;Test 12
	;|---------------|
	;| 3 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 4 , 0 | 0 , 2 |
	;|---------------|
	LDA #4
	STA field+12
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 13
	;|---------------|
	;| 3 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 0 , 0 |
	;| 1 , 0 | 0 , 2 |
	;|---------------|
	LDA #1
	STA field+12
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 14
	;|---------------|
	;| 3 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 1 , 0 |
	;| 1 , 0 | 0 , 2 |
	;|---------------|
	LDA #1
	STA field+10
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 15
	;|---------------|
	;| 3 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 1 , 0 |
	;| 1 , 2 | 0 , 2 |
	;|---------------|
	LDA #2
	STA field+13
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 16
	;|---------------|
	;| 3 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 1 , 0 |
	;| 1 , 3 | 0 , 2 |
	;|---------------|
	LDA #3
	STA field+13
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 17
	;|---------------|
	;| 3 , 2 | 0 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 4 , 0 |
	;| 1 , 3 | 0 , 2 |
	;|---------------|
	LDA #4
	STA field+10
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 18
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 0 |
	;|-------+-------|
	;| 0 , 0 | 4 , 2 |
	;| 1 , 3 | 0 , 2 |
	;|---------------|
	LDA #1
	STA field+2
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 19
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 0 , 0 | 4 , 0 |
	;| 1 , 3 | 0 , 2 |
	;|---------------|
	LDA #2
	STA field+7
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 20
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 0 , 0 | 4 , 0 |
	;| 1 , 3 | 2 , 0 |
	;|---------------|
	LDA #2
	STA field+14
	LDA #0
	STA field+15
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 21
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 4 , 0 | 4 , 0 |
	;| 1 , 3 | 2 , 0 |
	;|---------------|
	LDA #4
	STA field+8
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 22
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 2 , 0 | 4 , 0 |
	;| 1 , 3 | 2 , 0 |
	;|---------------|
	LDA #2
	STA field+8
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 23
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 2 , 0 | 4 , 3 |
	;| 1 , 3 | 2 , 0 |
	;|---------------|
	LDA #3
	STA field+11
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR
	
	;--------------------------------------------
	;Test 24
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 2 , 0 | 4 , 3 |
	;| 1 , 3 | 2 , 3 |
	;|---------------|
	LDA #3
	STA field+15
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR1
	
	;--------------------------------------------
	;Test 25
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 2 , 0 | 4 , 3 |
	;| 1 , 3 | 2 , 4 |
	;|---------------|
	LDA #4
	STA field+15
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR1
	
	;--------------------------------------------
	;Test 26
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 2 , 0 | 4 , 3 |
	;| 1 , 3 | 2 , 1 |
	;|---------------|
	LDA #1
	STA field+15
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR1
	
	;--------------------------------------------
	;Test 27
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 2 , 0 | 4 , 3 |
	;| 1 , 3 | 2 , 0 |
	;|---------------|
	LDA #0
	STA field+15
	JSR isLegalBoard
	BEQ IS_LEGAL_BOARD_TEST_ERROR1
	
	;--------------------------------------------
	;Test 28
	;|---------------|
	;| 3 , 2 | 1 , 4 |
	;| 4 , 1 | 3 , 2 |
	;|-------+-------|
	;| 2 , 4 | 4 , 3 |
	;| 1 , 3 | 2 , 0 |
	;|---------------|
	LDA #4
	STA field+9
	JSR isLegalBoard
	BNE IS_LEGAL_BOARD_TEST_ERROR1
	BEQ IS_LEGAL_BOARD_TEST_End
	
	
IS_LEGAL_BOARD_TEST_ERROR1:
	TSX
	DEC $0101, X
	
IS_LEGAL_BOARD_TEST_End:
	PLA
	RTS
;--------------------------------------------------------------------
	
	.ORG $6000
field: .RS $10

sudoku16: 
ll161: .BYTE 0,4,0,3	;2,4,1,3
ll162: .BYTE 1,0,0,0	;1,3,2,4
ll163: .BYTE 0,0,0,0	;4,1,3,2
ll164: .BYTE 0,0,4,1	;3,2,4,1

sudoku15: 
ll151: .BYTE 0,0,0,1	;2,4,3,1
ll152: .BYTE 3,0,2,0	;3,1,2,4
ll153: .BYTE 4,0,0,3	;4,2,1,3
ll154: .BYTE 0,0,0,0	;1,3,4,2

sudoku14: 
ll141: .BYTE 0,0,0,1	;2,3,4,1
ll142: .BYTE 0,0,2,0	;4,1,2,3
ll143: .BYTE 0,4,0,0	;1,4,3,2
ll144: .BYTE 3,2,0,0	;3,2,1,4

sudoku13: 
ll131: .BYTE 0,0,0,0	;2,4,1,3	
ll132: .BYTE 1,3,0,0	;1,3,2,4
ll133: .BYTE 4,0,0,2	;4,1,3,2
ll134: .BYTE 0,0,4,0	;3,2,4,1

sudoku12: 
ll121: .BYTE 2,0,1,0	;not solvable
ll122: .BYTE 0,0,0,2	
ll123: .BYTE 0,3,0,1	
ll124: .BYTE 4,0,2,0	

sudoku11: 
ll111: .BYTE 0,0,1,0	;3,2,1,4
ll112: .BYTE 0,0,0,2	;1,4,3,2
ll113: .BYTE 0,3,0,1	;2,3,4,1
ll114: .BYTE 4,0,2,0	;4,1,2,3

sudoku10: 
ll101: .BYTE 0,0,4,0	;not solvable
ll102: .BYTE 0,1,0,3	
ll103: .BYTE 0,0,0,1	
ll104: .BYTE 1,0,0,4	

sudoku9: 
ll91: .BYTE 0,0,4,0	;2,3,4,1
ll92: .BYTE 0,1,0,3	;4,1,2,3
ll93: .BYTE 0,0,0,0	;3,4,1,2
ll94: .BYTE 1,0,0,4	;1,2,3,4

sudoku8: 
ll81: .BYTE 0,0,2,0	;4,3,2,1
ll82: .BYTE 2,0,0,3	;2,1,4,3
ll83: .BYTE 0,4,0,0	;3,4,1,2
ll84: .BYTE 0,0,3,0	;1,2,3,4

sudoku7: 
ll71: .BYTE 0,0,4,0	;3,2,4,1
ll72: .BYTE 1,4,0,0	;1,4,3,2
ll73: .BYTE 2,0,0,0	;2,3,1,4
ll74: .BYTE 0,0,2,0	;4,1,2,3

sudoku6: 
ll61: .BYTE 4,0,0,0	;4,1,2,3
ll62: .BYTE 3,0,1,4	;3,2,1,4
ll63: .BYTE 0,0,3,0	;2,4,3,1
ll64: .BYTE 1,0,0,0	;1,3,4,2

sudoku5: 
ll51: .BYTE 2,0,3,0	;2,1,3,4
ll52: .BYTE 0,3,0,0	;4,3,1,2
ll53: .BYTE 1,0,0,0	;1,2,4,3
ll54: .BYTE 0,0,2,0	;3,4,2,1

sudoku4: 
ll41: .BYTE 0,0,0,0	;4,3,2,1
ll42: .BYTE 1,0,3,0	;1,2,3,4
ll43: .BYTE 0,1,4,0	;3,1,4,2
ll44: .BYTE 2,0,0,0	;2,4,1,3

sudoku3: 
ll31: .BYTE 0,0,1,0	;2,4,1,3
ll32: .BYTE 0,3,0,0	;1,3,4,2
ll33: .BYTE 0,2,0,0	;4,2,3,1
ll34: .BYTE 0,0,0,4	;3,1,2,4

sudoku2: 
ll21: .BYTE 0,0,0,0	
ll22: .BYTE 0,0,0,0	
ll23: .BYTE 0,0,0,0	
ll24: .BYTE 0,0,0,0	

sudoku1: 
ll11: .BYTE 4,0,2,0	;4,3,2,1
ll12: .BYTE 1,0,0,3	;1,2,4,3
ll13: .BYTE 0,0,0,0	;2,1,3,4
ll14: .BYTE 0,0,0,2	;3,4,1,2

; Temporary variables, only valid in one subroutine, values are normally unequal to zero
; Only valid in a subroutine, if no other subroutine is called inbetween.
index: .RS $10
counter .RS $10
return: .RS $10