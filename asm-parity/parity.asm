	.ORG $4000
main:
	LDA #$11
	JSR parity
	RTS


;===================================================================
;Bildet die Parit�t des im Akku �bergebenen Bytes. Das Ergebnis wird
;im X-Register zur�ckgegeben. C-�quivalent:
;	while(x) { //Anzahl der gesetzten Bits bestimmen
;		count++;
;		x &= (x-1);
;	}
;	count &= 1;	//Parit�t bestimmen
;===================================================================
parity:
	PHA		;Sicherung, wird sp�ter zur�ckgeladen
	PHA		;gleicher Wert, wird jedoch ver�ndert
	TSX
	LDA #0
	PHA		;Z�hler f�r die Anzahl der gesetzten Bits
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
	AND #1		;Berechne Parit�t
	TAX		;R�ckgabewert
	PLA		;M�ll
	PLA		;gesicherter Wert
	RTS
;-------------------------------------------------------------------