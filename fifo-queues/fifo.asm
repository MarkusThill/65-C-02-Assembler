;===================================================================
;Daten der FIFO
progAddr = $4000
fifoSize = 255		;Max. 255
fifoAddr = progAddr + $500	;Startadr der FIFO und Verwaltungsinformationen
;===================================================================
	.ORG progAddr
main:
	JSR initFIFO
	JSR countFIFO
	JSR countEmptyFIFO
	LDA #$AA
	JSR writeFIFO
	LDA #00
	JSR countFIFO
	JSR readFIFO
	JSR readFIFO
	JSR countFIFO
	JSR countEmptyFIFO
	JSR writeFIFO
	JSR writeFIFO
	JSR writeFIFO
	JSR countFIFO
	JSR countEmptyFIFO
	JSR writeFIFO
	JSR writeFIFO
	JSR writeFIFO
	JSR countFIFO
	RTS


;===================================================================		
;Initialisiert die FIFO. 	
;===================================================================
initFIFO:
	;Verbiete Interrupts solange in dieser Funktion, um Fehler
	;zu vermeiden
	SEI
	
	;Initialisiere IN- und OUT-Offset
	LDA #0
	STA fifoInOffs
	STA fifoOutOffs
	
	;FIFO ist leer
	LDA #2
	STA fifoFlags
	CLI
	RTS
;-------------------------------------------------------------------	


;===================================================================	
;Schreibt den im Akku �bergeben Wert in die FIFO. Sollte
;die FIFO voll sein, so wird eine Fehlercode im X-Register
;zur�ckgegeben.
;R�ckgabewerte im X-Register:
;	0 -> Fehlerfreie Ausf�hrung
;	1 -> FIFO voll, Eintragung nicht m�glich
;===================================================================
writeFIFO:	
	;Verbiete IRQs, da im schlimmsten Fall beim Empfangsmodus
	;gleichzeitig in die FIFO geschrieben wird und dies zu 
	;Inkonsistenzen f�hren kann
	SEI
	PHA
	;Pr�fe ob FIFO voll und breche ggfs. ab
	LDX fifoFlags
	CPX #1
	BEQ writeFIFO2

	;Schreibe Wert in FIFO
	LDX fifoInOffs
	STA fifo, X
	
	;Wert konnte erfolgreich geschrieben werden.
	;R�ckgabewert X-Register = 0
	LDX #0
	
	;FIFO ist jetzt nicht mehr leer
	STX fifoFlags
	
	;Inkrementiere IN-Position
	INC fifoInOffs
	
	;Pr�fe, ob Ende des Speicherbereiches erreicht
	LDA fifoInOffs
	CMP #fifoSize
	BNE writeFIFO1
	
	;Ende ist erreicht, daher In-Offset auf Startwert 0 setzen
	STX fifoInOffs
	TXA
	
writeFIFO1: 
	;Pr�fe ob FIFO voll, dh. IN = OUT
	CMP fifoOutOffs
	BNE writeFIFO2
	
	;FIFO voll, daher Flag setzen
	LDA fifoFlags
	ORA #1
	STA fifoFlags
	;INC fifoFlags ;sollte auch gehen
	
writeFIFO2:
	;Interrupts wieder erlauben
	PLA
	CLI	
	RTS
;-------------------------------------------------------------------	
	
;===================================================================	
;Lie�t einen Wert aus der FIFO und schreibt den Wert in den
;Akku. Fehlerkennungen werden in das X-Register geschrieben
;R�ckgabewerte im X-Register:
;	0 -> Konnte Wert erfolgreich aus der FIFO lesen
;	1 -> FIFO ist leer, konnte keinen Wert entnehmen
;===================================================================
readFIFO:
	;Verbiete IRQs, da im schlimmsten Fall beim Empfangsmodus
	;gleichzeitig in die FIFO geschrieben wird und dies zu 
	;Inkonsistenzen f�hren kann
	SEI
	
	;Breche ab, wenn Fifo leer ist
	LDX fifoFlags
	CPX #2
	BEQ readFIFO3
	
	;Lese Wert aus Fifo und lege vor�bergehend auf Stack
	LDX fifoOutOffs
	LDA fifo, X
	PHA	
	
	;Inkrementiere Out-Position
	INX 
	STX fifoOutOffs
	
	;FIFO ist nicht mehr Voll
	LDA #0
	STA fifoFlags
	
	;Pr�fe, ob Ende des Speicherbereiches erreicht
	CPX #fifoSize
	BNE readFIFO1
	
	;Ende ist erreicht, daher Out-Offset auf Startwert 0 setzen
	TAX
	STA fifoOutOffs
	
readFIFO1:
	;Pr�fe, ob FIFO leer ist, dh. IN = OUT
	CPX fifoInOffs
	BNE readFIFO2
	
	;FIFO ist leer, dh. Flag setzen
	LDA fifoFlags
	ORA #2
	STA fifoFlags
	
readFIFO2:
	LDX #1	;R�ckgabewert 0
	PLA		;Wert in Akku

readFIFO3:
	DEX
	CLI		;Erlaube ab hier wieder Interrupts
	RTS
;-------------------------------------------------------------------	

;===================================================================	
;Z�hlt die Anzahl der belegten Bytes in der FIFO und gibt das 
;Ergebnis im Akkumulator zur�ck. 
;Es werden keine Ver�nderungen der FIFO durchgef�hrt, Interrupts 
;m�ssen hier also nicht gesperrt werden!
;===================================================================
countFIFO:
	LDA fifoFlags
	AND #2 ; Check, if FIFO is empty
	EOR #2
	BEQ countFIFO2
	SEC
	LDA fifoInOffs
	SBC fifoOutOffs
	BCC countFIFO1	;IN < OUT
	BNE countFIFO2	;IN > OUT
	
	;IN = OUT
	LDA fifoFlags
	AND #2
	BNE countFIFO2 ;FIFO ist leer
	
	;FIFO ist voll	
	CLC	
countFIFO1:
	ADC #fifoSize
countFIFO2:
	RTS
;-------------------------------------------------------------------
	
;===================================================================
;Z�hlt die Anzahl an freien Bytes in der FIFO und gibt das Ergebnis
;im Akkumulator zur�ck.
;Es werden keine Ver�nderungen der FIFO durchgef�hrt, Interrupts 
;m�ssen hier also nicht gesperrt werden!
;===================================================================
countEmptyFIFO:
	JSR countFIFO	;ermittle Anzahl der belegten Bytes in der FIFO
	SEC
	SBC #fifoSize
	
	;Zweierkomplement bilden. Es wird dadurch keine tempor�re
	;Variable ben�tigt
	EOR #$FF
	SEC
	ADC #0
	RTS
;-------------------------------------------------------------------



	.ORG fifoAddr
fifo: 			.BYTE $00

	.ORG fifoAddr + fifoSize
;Flags:
;Bit 0: FIFO ist voll
;Bit 1: FIFO ist leer
fifoFlags:	.BYTE $00
fifoInOffs: 	.BYTE $00
fifoOutOffs: 	.BYTE $00
;===================================================================