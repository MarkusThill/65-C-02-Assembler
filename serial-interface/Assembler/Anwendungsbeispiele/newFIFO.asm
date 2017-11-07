
;Pointer f�r interne Zwecke ben�tigt
_p = $80

;Anzahl der FIFOs, max. 127
_fifoNum  = $8 

;Gr��e pro FIFO (in Bytes)
_fifoSize = $10

;StartAdresse der kompletten Datenstruktur
;Berechnung der Gr��e
_fifoAddr = $4500

	.ORG $4000
	JSR _initFIFO
	
	;Versuch, in FIFO 8 zu schreiben (FEHLER)
	LDX #8
	LDA #1
	JSR _writeFIFO
	;X=1 erwartet
	
	;Schreibe in FIFO7
	LDY #1
loop:
	TYA
	LDX #7
	JSR _writeFIFO
	INY
	CPY #$12
	BNE loop
	;X=2 erwartet
	
	;Schreibe in FIFO6
	LDY #$11
loop1:
	TYA
	LDX #6
	JSR _writeFIFO
	INY
	CPY #$23
	BNE loop1
	
	;Schreibe in FIFO5
	LDY #$21
loop2:
	TYA
	LDX #5
	JSR _writeFIFO
	INY
	CPY #$33
	BNE loop2
	
	;Schreibe in FIFO4
	LDY #$31
loop3:
	TYA
	LDX #4
	JSR _writeFIFO
	INY
	CPY #$43
	BNE loop3
	
;Schreibe in FIFO3
	LDY #$41
loop4:
	TYA
	LDX #3
	JSR _writeFIFO
	INY
	CPY #$53
	BNE loop4
	
;Schreibe in FIFO2
	LDY #$51
loop5:
	TYA
	LDX #2
	JSR _writeFIFO
	INY
	CPY #$63
	BNE loop5
	
;Schreibe in FIFO1
	LDY #$61
loop6:
	TYA
	LDX #1
	JSR _writeFIFO
	INY
	CPY #$73
	BNE loop6
	
;Schreibe in FIFO0
	LDY #$71
loop7:
	TYA
	LDX #0
	JSR _writeFIFO
	INY
	CPY #$83
	BNE loop7
	
;Versuch, aus FIFO 8 zu lesen (FEHLER)
 	LDX #8
	JSR _readFIFO
	;X=1 erwartet
	
;Lese aus FIFO0
	LDY #$12	
loop8:
	LDX #0	
	JSR _readFIFO
	DEY
	BNE loop8
	
;Lese aus 3 Werte aus FIFO1
	LDY #$03	
loop9:
	LDX #1
	JSR _readFIFO
	DEY
	BNE loop9

;Schreibe wieder 3 Werte in die FIFO1
	LDY #$05
loop10:
	LDX #1
	TYA
	JSR _writeFIFO
	DEY
	BNE loop10	
	
;Lese alle Werte aus der FIFO
	LDY #$12
loop11:
	LDX #1
	JSR _readFIFO
	DEY
	BNE loop11	
	
;Test readFirst
	LDX #2
	JSR _readFirstFIFO
	RTS
	
	

;===================================================================
;Initialisiere die FIFO
;===================================================================
_initFIFO:
	SEI	;IRQs verbieten
	PHA	;sichere Akku auf den Stack
	
	;sichere das X-Register auf den Stack
	TXA
	PHA
	
	;Setze alle In-/Out-Zeiger zur�ck (Null)
	;Ermittle zun�chst Anzahl der Schleifendurchl�ufe
	LDA #_fifoNum
	ASL
	TAX
	LDA #0
	
;Setze alle In-/Out Pointer in der Schleife zur�ck
_initFIFOsetP:
	STA _fifoAddr-1, X
	DEX
	BNE _initFIFOsetP
	
	;Alten Wert des X-Registers wieder laden	
	PLA
	TAX
	
	;Alten Akku-Wert wieder initialisieren
	PLA
	
	CLI	;Erlaube IRQs wieder
	RTS
;-------------------------------------------------------------------

;===================================================================
;Setzt die entsprechende FIFO zur�ck
;Parameter:
;	X-Register -> FIFO_Nr 
;R�ckgabewerte:
;	X-Register -> Erfolg
;===================================================================
_deleteFIFO:
	PHA	;sichere Akku
	
	;Pr�fe Nummer: Diese darf nicht >= _fifoNum sein
	CPX #_fifoNum
	BCS _deleteFIFOWrongNum	
	
	TXA
	ASL	;Bestimme Offset f�r In-Pointer
	TAX
	
	LDA #0
	STA _fifoAddr, X
	STA _fifoAddr+1, X
	
	TAX	;R�ckgabewert: 0
	BEQ _deleteFIFOend

_deleteFIFOWrongNum:
	LDX #1	;Fehler, FIFO_Nr nicht vorhanden

_deleteFIFOend:
	PHA	;R�cksichern des Akkus
	RTS
;-------------------------------------------------------------------


;===================================================================
;Parameter:
;	X-Register: Nummer der FIFO
;R�ckgabewerte:
;	Akku: Datenbyte
;	X-Register: Erfolg der Operation
;TODO: Verbiete IRQs in kritischen Bereichen
;===================================================================
_readFIFO:
	TYA
	PHA	;sichere Y-Register auf den Stack
	
	;Pr�fe Nummer: Diese darf nicht >= _fifoNum sein
	CPX #_fifoNum
	BCS _readFIFOWrongNum	
	
	TXA
	ASL	;Bestimme Offset f�r In-Pointer
	;FIFO leer, Wenn IN = OUT
	TAY
	LDA _fifoAddr, Y
	;INY
	CMP _fifoAddr + 1, Y
	BEQ _readFIFOempty	;Verzweige, wenn FIFO leer
	
	LDA _fifoAddr + 1, Y	;Lade OUT-Pointer
	TAY
	
	;Berechne:
	;   Basis-Adresse	->Beginn des Datenbereiches
	; + FIFO_Nr * _fifoSize ->Pointer auf Start der FIFO
	; + _fifoNum * 2	->IN-/OUT P. befinden sich vor FIFOs
	TXA	;Nr. der FIFO	
	JSR _getFIFOPointer
	
	LDA (_p), Y	;Lese Wert aus der FIFO
	PHA		;zun�chst auf den Stack
	LDA #0
	STA (_p), Y	;L�sche �bersichtshalber den Wert (DEBUG)
	
	INY		;Inkrementiere den OUT-Pointer
	CPY #_fifoSize	;Pr�fe, ob Ende der FIFO erreicht
	BNE _readFIFOSuccess
	LDY #0		;Zeiger wird wieder auf den Start gesetzt
		
_readFIFOSuccess:
	TXA	;Nr. der FIFO steht noch im X-Register
	ASL	;Offset f�r den In-Pointer
	TAX
	INX	;Offset f�r den Out-Pointer
	
	TYA	;OUT-Pointer nach Akku
	STA _fifoAddr, X
	
	PLA	;Datenbyte vom Stack
	
	LDX #0	;R�ckgabewert
	BEQ _readFIFOend
		
_readFIFOWrongNum:
	LDX #1
	BNE _readFIFOend
	
_readFIFOempty:
	LDX #2
_readFIFOend:
	STA _p	;Nutzte _p als tempor�re Variable
	
	PLA	;Hole Y-Register vom Stack
	TAY
	
	LDA _p
	RTS
;-------------------------------------------------------------------


;===================================================================
;Unterschied zu _readFIFO: 
;	Der gelesene Wert bleibt in der FIFO erhalten
;Parameter:
;	X-Register: Nummer der FIFO
;R�ckgabewerte:
;	Akku: Datenbyte
;	X-Register: Erfolg der Operation
;TODO: Verbiete IRQs in kritischen Bereichen
;===================================================================
_readFirstFIFO:
	;Pr�fe Nummer: Diese darf nicht >= _fifoNum sein
	CPX #_fifoNum
	BCS _readFirstFIFOWrongNum	
	
	TYA
	PHA	;sichere Y-Register auf den Stack
	
	TXA
	ASL	;Bestimme Offset f�r In-Pointer
	
	;FIFO leer, Wenn IN = OUT
	TAY
	LDA _fifoAddr, Y
	;INY
	CMP _fifoAddr + 1, Y
	BEQ _readFirstFIFOempty	;Verzweige, wenn FIFO leer
	
	LDA _fifoAddr + 1, Y	;Lade OUT-Pointer
	TAY
	
	;Berechne:
	;   Basis-Adresse	->Beginn des Datenbereiches
	; + FIFO_Nr * _fifoSize ->Pointer auf Start der FIFO
	; + _fifoNum * 2	->IN-/OUT P. befinden sich vor FIFOs
	TXA	;Nr. der FIFO	
	JSR _getFIFOPointer
	
	LDA (_p), Y	;Lese Wert aus der FIFO
	TAX		;zun�chst nach X-Register
	
	PLA
	TAY		;R�cksichern des Y-Registers
	
	TXA		;Datenbyte
	
	LDX #0		;R�ckagebwert
	BEQ _readFirstFIFOend
	
_readFirstFIFOWrongNum:
	LDX #1
	BNE _readFirstFIFOend
	
_readFirstFIFOempty:
	PLA
	TAY		;R�cksichern des Y-Registers
	LDX #2
	
_readFirstFIFOend:
	RTS
;-------------------------------------------------------------------	
		



;===================================================================
;Akku: Datenbyte
;X-Register: Nummer der FIFO
;TODO: Verbiete IRQs in kritischen Bereichen
;===================================================================
_writeFIFO:
	PHA	;sichere Datenbyte zun�chst auf den Stack
	
	TYA
	PHA	;sichere Y-Register auf den Stack
	
	TXA
	PHA	;sichere X-Register auf den Stack
	
	;Pr�fe Nummer: Diese darf nicht >= _fifoNum sein
	;SEC
	;TXA
	CMP #_fifoNum
	BCS _writeFIFOWrongNum
	
	;Pr�fe ob FIFO voll: Kann auch ohne Berechnung der 
	;entsprechenden FIFO-BasisAdresse erfolgen
	;Voll = IN+1==OUT v (IN+1==SIZE & OUT==0)
	
	;TXA	;Offset f�r IN-Pointer berechnen
	ASL
	
	;Pr�fe, ob IN+1==OUT
	TAY
	LDA _fifoAddr, Y ;Lade IN-Pointer
	SEC
	ADC #0	
	;INY
	CMP _fifoAddr + 1, Y ;Vergleiche mit OUT-Pointer
	BEQ _writeFIFOFull
	
	;Pr�fe, ob IN+1==SIZE & OUT==0
	;IN+1 steht noch im Akku
	CMP #_fifoSize
	BNE _writeFIFO1 ;Verzweige, wenn FIFO nicht voll
	
	;Pr�fe, ob OUT==0
	LDA _fifoAddr + 1, Y
	BEQ _writeFIFOFull
	
_writeFIFO1:
	;FIFO ist nicht voll
	TXA	;Nr. der FIFO befindet sich noch in X
	
	;Berechne:
	;   Basis-Adresse	->Beginn des Datenbereiches
	; + FIFO_Nr * _fifoSize ->Pointer auf Start der FIFO
	; + _fifoNum * 2	->IN-/OUT P. befinden sich vor FIFOs
	JSR _getFIFOPointer
	
	; + IN-Offset bestimmen	->Offset innerhalb der FIFO
	;DEY	;Y zeigt noch auf Out-Pointer
	
	TYA	;Sichere Offset f�r IN-Pointer
	PHA
	
	LDA _fifoAddr, Y
	TAY	;Offset innerhalb der FIFO -> IN-Pointer
	
	;Schreibe Datenbyte in die FIFO
	TSX
	LDA $0104, X	;Hole Datenbyte vom Stack
	STA (_p), Y	;Schreibe in die FIFO
	
	;Inkrementiere IN-Pointer
	INY
	CPY #_fifoSize	;Pr�fe, ob Ende der FIFO erreicht
	BNE _writeFIFOSuccess
	LDY #0	;Zeiger wird wieder auf den Start gesetzt
		
_writeFIFOSuccess:
	PLA	;Offset f�r IN-Pointer
	TAX
	TYA
	STA _fifoAddr, X	;Speichere neuen IN-Pointer
	
	LDX #0
	BEQ _writeFIFOend
	
_writeFIFOWrongNum:	
	LDX #1
	BNE _writeFIFOend
	
_writeFIFOFull:
	LDX #2
	;BNE _writeFIFOend
	
_writeFIFOend:
	PLA	;Hole FIFO_Nr vom Stack
	PLA	;Hole Y-Register vom Stack
	TAY
	PLA	;Hole Datenbyte vom Stack
	RTS
;-------------------------------------------------------------------

	
;===================================================================
;Berechnet einen Zeiger auf den Startpunkt einer FIFO!
;Akku wird nicht ver�ndert!
;
;Parameter:
;	Akku 	-> Nr. der FIFO
;
;Ergebnis:
;	Der berechnete Pointer wird in _p abgelegt	
;===================================================================
_getFIFOPointer:
	PHA ;sichere FIFO_Nr auf den Stack
	
	;Berechne Grundadresse der angesprochenen FIFO
	;Beide Operaden der Multiplikation werden direkt
	;�ber den Pointer �bergeben

	STA _p
	LDA #_fifoSize	;Gr��e der FIFO
	STA _p + 1
	JSR _fifoMult	;Berechne: Gr��e_der_FIFO * FIFO_NR
	
	;Addiere Anzahl der belegten Bytes aller Pointer auf die 
	;Adresse, da die sich vor allen FIFOs befinden
	LDA #_fifoNum	;Anzahl an belegten Bytes f�r die Pointer
	ASL
	
	CLC
	ADC _p
	STA _p
	
	LDA _p+1
	ADC #0
	STA _p+1
	
	;Addiere Basis-Adresse
	CLC
	LDA #<_fifoData
	ADC _p
	STA _p
	
	LDA #>_fifoData
	ADC _p + 1
	STA _p + 1	
	
	PLA	;Hole FIFO_Nr wieder vom Stack
	
	;Im Pointer _p befindet sich jetzt der Zeiger auf das
	;ausgew�hlte Element der entsprechenden FIFO
	RTS
;-------------------------------------------------------------------


;===================================================================
;Berechnet die Grundadresse der ausgew�hlten FIFO
;Parameter werden im Pointer abgelegt:
;	_p 	: FIFO_Nr
;	_p + 1	:_fifoSize
;Ergebnis in kompletten Pointer _p:
;	FIFO_Nr * _fifoSize
;===================================================================	
_fifoMult:
	TXA	;sichere X-Register
	PHA
	
	LDA #0
	LDX #8
	LSR _p		;0 -> MSB
_fifoMult1:
	BCC _fifoMult2
	CLC
	ADC _p + 1
_fifoMult2:
	ROR		;darf nicht LSR sein
	ROR _p
	DEX
	BNE _fifoMult1
	
	STA _p + 1	
	
	PLA
	TAX
	
	RTS
;-------------------------------------------------------------------

	
	.ORG _fifoAddr
_fifoData: .BYTE $00
	