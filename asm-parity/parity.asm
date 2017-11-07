	.ORG $4000
main:
	LDA #$11
	JSR parity
	RTS


;===================================================================
;Bildet die Parität des im Akku übergebenen Bytes. Das Ergebnis wird
;im X-Register zurückgegeben. C-Äquivalent:
;	while(x) { //Anzahl der gesetzten Bits bestimmen
;		count++;
;		x &= (x-1);
;	}
;	count &= 1;	//Parität bestimmen
;===================================================================
parity:
	PHA		;Sicherung, wird später zurückgeladen
	PHA		;gleicher Wert, wird jedoch verändert
	TSX
	LDA #0
	PHA		;Zähler für die Anzahl der gesetzten Bits
	LDA $0101, X
	BEQ parity2
parity1:
	INC $0100, X
	DEC $0101, X
	AND $0101, X
	STA $0101, X
	BNE parity1
parity2:
	PLA		;Anzahl der gesetzen Bits
	AND #1		;Berechne Parität
	TAX		;Rückgabewert
	PLA		;Müll
	PLA		;gesicherter Wert
	RTS
;-------------------------------------------------------------------