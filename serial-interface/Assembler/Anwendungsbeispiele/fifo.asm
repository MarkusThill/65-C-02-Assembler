_fifoSize = 255		;Max. 255
_fifoAddr = $4500	;Startadresse der FIFO sowie der Verwaltungsinformationen

	.ORG $4000
	;Test
	LDA #%00000001
	JSR _parity
	JSR _initFIFO
	LDY #0
	
	;Schreibe fünf Werte in die FIFO
	;und Teste auf Voll
loop:
	INY
	TYA
	JSR _writeFIFO
	CPY #7
	BNE loop
	
	;Lese fünf Werte aus der FIFO und 
	;teste auf Leer
loop2:
	JSR _readFIFO
	DEY
	BNE loop2
	
	;TYA
	;JSR _writeFIFO
	
	;Teste countFifo
	LDA #1
	STA _fifoFlags
	LDA #254
	STA _fifoOutOffs
	LDA #13
	STA _fifoInOffs
	
	JSR _countEmptyFIFO
	LDX #0
	RTS
	;/Test
	
	
;Initialisiert die FIFO. 	
_initFIFO:
	;Initialisiere IN- und OUT-Offset
	LDA #0
	STA _fifoInOffs
	STA _fifoOutOffs
	
	;FIFO ist leer
	LDA #2
	STA _fifoFlags
	RTS
	
	
;Schreibt den im Akku übergeben Wert in die FIFO. Sollte
;die FIFO voll sein, so wird eine Fehlercode im X-Register
;zurückgegeben.
;Rückgabewerte im X-Register:
;	0 -> Fehlerfreie Ausführung
;	1 -> FIFO voll, Eintragung nicht möglich

_writeFIFO:	
	;Prüfe ob FIFO voll und breche ggfs. ab
	LDX _fifoFlags
	CPX #1
	BEQ _writeFIFO2

	;Schreibe Wert in FIFO
	LDX _fifoInOffs
	STA _fifo, X
	
	;Wert konnte erfolgreich geschrieben werden.
	;Rückgabewert X-Register = 0
	LDX #0
	
	;FIFO ist jetzt nicht mehr leer
	STX _fifoFlags
	
	;Inkrementiere IN-Position
	INC _fifoInOffs
	
	;Prüfe, ob Ende des Speicherbereiches erreicht
	LDA _fifoInOffs
	CMP #_fifoSize
	BNE _writeFIFO1
	
	;Ende ist erreicht, daher In-Offset auf Startwert 0 setzen
	STX _fifoInOffs
	TXA
	
_writeFIFO1: 
	;Prüfe ob FIFO voll, dh. IN = OUT
	CMP _fifoOutOffs
	BNE _writeFIFO2
	
	;FIFO voll, daher Flag setzen
	LDA _fifoFlags
	ORA #%00000001
	STA _fifoFlags
	;INC _fifoFlags ;sollte auch gehen
	
_writeFIFO2:
	RTS
	
	
	
;Ließt einen Wert aus der FIFO und schreibt den Wert in den
;Akku. Fehlerkennungen werden in das X-Register geschrieben
;Rückgabewerte im X-Register:
;	0 -> Konnte Wert erfolgreich aus der FIFO lesen
;	1 -> FIFO ist leer, konnte keinen Wert entnehmen

_readFIFO:
	;Breche ab, wenn Fifo leer ist
	LDX _fifoFlags
	CPX #2
	BEQ _readFIFO3
	
	;Lese Wert aus Fifo und lege vorübergehend auf Stack
	LDX _fifoOutOffs
	LDA _fifo, X
	PHA	
	
	;Inkrementiere Out-Position
	INX 
	STX _fifoOutOffs
	
	;FIFO ist nicht mehr Voll
	LDA #0
	STA _fifoFlags
	
	;Prüfe, ob Ende des Speicherbereiches erreicht
	CPX #_fifoSize
	BNE _readFIFO1
	
	;Ende ist erreicht, daher Out-Offset auf Startwert 0 setzen
	TAX
	STA _fifoOutOffs
	
_readFIFO1:
	;Prüfe, ob FIFO leer ist, dh. IN = OUT
	CPX _fifoInOffs
	BNE _readFIFO2
	
	;FIFO ist leer, dh. Flag setzen
	LDA _fifoFlags
	ORA #%00000010
	STA _fifoFlags
	
_readFIFO2:
	LDX #1	;Rückgabewert 0
	PLA		;Wert in Akku

_readFIFO3:
	DEX
	RTS
	
	
;Zählt die Anzahl der belegten Bytes in der FIFO und gibt das Ergebnis
;im Akkumulator zurück
_countFIFO:
	SEC
	LDA _fifoInOffs
	SBC _fifoOutOffs
	BCC _countFIFO1	;IN < OUT
	BNE _countFIFO2	;IN > OUT
	
	;IN = OUT
	LDA _fifoFlags
	AND #2
	BEQ _countFIFO2	;FIFO ist voll
	LDA #_fifoSize	;FIFO ist leer
	BNE _countFIFO2
	
_countFIFO1:
	ADC #_fifoSize
_countFIFO2:
	RTS
	
;Zählt die Anzahl an freien Bytes in der FIFO und gibt das Ergebnis
;im Akkumulator zurück
_countEmptyFIFO:
	JSR _countFIFO	;ermittle Anzahl der belegten Bytes in der FIFO
	SEC
	SBC #_fifoSize
	
	;Zweierkomplement bilden. Es wird dadurch keine temporäre
	;Variable benötigt
	EOR #$FF
	SEC
	ADC #0
	RTS

;Bildet die Parität des im Akku übergebenen Bytes. Das Ergebnis wird
;im X-Register zurückgegeben. C-Äquivalent:
;	while(x) { //Anzahl der gesetzten Bits bestimmen
;		count++;
;		x &= (x-1);
;	}
;	count &= 1;	//Parität bestimmen
_parity:
	PHA	;Sicherung, wird später zurückgeladen
	PHA	;gleicher Wert, wird jedoch verändert
	TSX
	LDA #0
	PHA	;Zähler für die Anzahl der gesetzten Bits
	LDA $0101, X
	BEQ _parity2
_parity1:
	INC $0100, X
	DEC $0101, X
	AND $0101, X
	STA $0101, X
	BNE _parity1
_parity2:
	PLA	;Anzahl der gesetzen Bits
	AND #1	;Berechne Parität
	TAX		;Rückgabewert
	PLA	;Müll
	PLA	;gesicherter Wert
	RTS
	

	.ORG _fifoAddr
_fifo: 			.BYTE $00

	.ORG _fifoAddr + _fifoSize
;Flags:
;Bit 0: FIFO ist voll
;Bit 1: FIFO ist leer
_fifoFlags:		.BYTE $00
_fifoInOffs: 	.BYTE $00
_fifoOutOffs: 	.BYTE $00
