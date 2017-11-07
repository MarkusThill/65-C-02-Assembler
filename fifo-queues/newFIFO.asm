
;Pointer für interne Zwecke benötigt
p = $80

;Anzahl der FIFOs, max. 127
fifoNum  = $8 

;Größe pro FIFO (in Bytes)
fifoSize = $10

;StartAdresse der kompletten Datenstruktur
;Berechnung der Größe
fifoAddr = $4500

	.ORG $4000
	JSR initFIFO
	
	;Versuch, in FIFO 8 zu schreiben (FEHLER)
	LDX #8
	LDA #1
	JSR writeFIFO
	;X=1 erwartet
	
	;Schreibe in FIFO7
	LDY #1
loop:
	TYA
	LDX #7
	JSR writeFIFO
	INY
	CPY #$12
	BNE loop
	;X=2 erwartet
	
	;Schreibe in FIFO6
	LDY #$11
loop1:
	TYA
	LDX #6
	JSR writeFIFO
	INY
	CPY #$23
	BNE loop1
	
	;Schreibe in FIFO5
	LDY #$21
loop2:
	TYA
	LDX #5
	JSR writeFIFO
	INY
	CPY #$33
	BNE loop2
	
	;Schreibe in FIFO4
	LDY #$31
loop3:
	TYA
	LDX #4
	JSR writeFIFO
	INY
	CPY #$43
	BNE loop3
	
;Schreibe in FIFO3
	LDY #$41
loop4:
	TYA
	LDX #3
	JSR writeFIFO
	INY
	CPY #$53
	BNE loop4
	
;Schreibe in FIFO2
	LDY #$51
loop5:
	TYA
	LDX #2
	JSR writeFIFO
	INY
	CPY #$63
	BNE loop5
	
;Schreibe in FIFO1
	LDY #$61
loop6:
	TYA
	LDX #1
	JSR writeFIFO
	INY
	CPY #$73
	BNE loop6
	
;Schreibe in FIFO0
	LDY #$71
loop7:
	TYA
	LDX #0
	JSR writeFIFO
	INY
	CPY #$83
	BNE loop7
	
;Versuch, aus FIFO 8 zu lesen (FEHLER)
 	LDX #8
	JSR readFIFO
	;X=1 erwartet
	
;Lese aus FIFO0
	LDY #$12	
loop8:
	LDX #0	
	JSR readFIFO
	DEY
	BNE loop8
	
;Lese aus 3 Werte aus FIFO1
	LDY #$03	
loop9:
	LDX #1
	JSR readFIFO
	DEY
	BNE loop9

;Schreibe wieder 3 Werte in die FIFO1
	LDY #$05
loop10:
	LDX #1
	TYA
	JSR writeFIFO
	DEY
	BNE loop10	
	
;Lese alle Werte aus der FIFO
	LDY #$12
loop11:
	LDX #1
	JSR readFIFO
	DEY
	BNE loop11	
	
;Test readFirst
	LDX #2
	JSR readFirstFIFO
	RTS
	
	

;===================================================================
;Initialisiere die FIFO
;===================================================================
initFIFO:
	SEI	;IRQs verbieten
	PHA	;sichere Akku auf den Stack
	
	;sichere das X-Register auf den Stack
	TXA
	PHA
	
	;Setze alle In-/Out-Zeiger zurück (Null)
	;Ermittle zunächst Anzahl der Schleifendurchläufe
	LDA #fifoNum
	ASL
	TAX
	LDA #0
	
;Setze alle In-/Out Pointer in der Schleife zurück
initFIFOsetP:
	STA fifoAddr-1, X
	DEX
	BNE initFIFOsetP
	
	;Alten Wert des X-Registers wieder laden	
	PLA
	TAX
	
	;Alten Akku-Wert wieder initialisieren
	PLA
	
	CLI	;Erlaube IRQs wieder
	RTS
;-------------------------------------------------------------------

;===================================================================
;Setzt die entsprechende FIFO zurück
;Parameter:
;	X-Register -> FIFONr 
;Rückgabewerte:
;	X-Register -> Erfolg
;===================================================================
deleteFIFO:
	PHA	;sichere Akku
	
	;Prüfe Nummer: Diese darf nicht >= fifoNum sein
	CPX #fifoNum
	BCS deleteFIFOWrongNum	
	
	TXA
	ASL	;Bestimme Offset für In-Pointer
	TAX
	
	LDA #0
	STA fifoAddr, X
	STA fifoAddr+1, X
	
	TAX	;Rückgabewert: 0
	BEQ deleteFIFOend

deleteFIFOWrongNum:
	LDX #1	;Fehler, FIFONr nicht vorhanden

deleteFIFOend:
	PHA	;Rücksichern des Akkus
	RTS
;-------------------------------------------------------------------


;===================================================================
;Parameter:
;	X-Register: Nummer der FIFO
;Rückgabewerte:
;	Akku: Datenbyte
;	X-Register: Erfolg der Operation
;TODO: Verbiete IRQs in kritischen Bereichen
;===================================================================
readFIFO:
	TYA
	PHA	;sichere Y-Register auf den Stack
	
	;Prüfe Nummer: Diese darf nicht >= fifoNum sein
	CPX #fifoNum
	BCS readFIFOWrongNum	
	
	TXA
	ASL	;Bestimme Offset für In-Pointer
	;FIFO leer, Wenn IN = OUT
	TAY
	LDA fifoAddr, Y
	;INY
	CMP fifoAddr + 1, Y
	BEQ readFIFOempty	;Verzweige, wenn FIFO leer
	
	LDA fifoAddr + 1, Y	;Lade OUT-Pointer
	TAY
	
	;Berechne:
	;   Basis-Adresse	->Beginn des Datenbereiches
	; + FIFONr * fifoSize ->Pointer auf Start der FIFO
	; + fifoNum * 2	->IN-/OUT P. befinden sich vor FIFOs
	TXA	;Nr. der FIFO	
	JSR getFIFOPointer
	
	LDA (p), Y	;Lese Wert aus der FIFO
	PHA		;zunächst auf den Stack
	LDA #0
	STA (p), Y	;Lösche übersichtshalber den Wert (DEBUG)
	
	INY		;Inkrementiere den OUT-Pointer
	CPY #fifoSize	;Prüfe, ob Ende der FIFO erreicht
	BNE readFIFOSuccess
	LDY #0		;Zeiger wird wieder auf den Start gesetzt
		
readFIFOSuccess:
	TXA	;Nr. der FIFO steht noch im X-Register
	ASL	;Offset für den In-Pointer
	TAX
	INX	;Offset für den Out-Pointer
	
	TYA	;OUT-Pointer nach Akku
	STA fifoAddr, X
	
	PLA	;Datenbyte vom Stack
	
	LDX #0	;Rückgabewert
	BEQ readFIFOend
		
readFIFOWrongNum:
	LDX #1
	BNE readFIFOend
	
readFIFOempty:
	LDX #2
readFIFOend:
	STA p	;Nutzte p als temporäre Variable
	
	PLA	;Hole Y-Register vom Stack
	TAY
	
	LDA p
	RTS
;-------------------------------------------------------------------


;===================================================================
;Unterschied zu readFIFO: 
;	Der gelesene Wert bleibt in der FIFO erhalten
;Parameter:
;	X-Register: Nummer der FIFO
;Rückgabewerte:
;	Akku: Datenbyte
;	X-Register: Erfolg der Operation
;TODO: Verbiete IRQs in kritischen Bereichen
;===================================================================
readFirstFIFO:
	;Prüfe Nummer: Diese darf nicht >= fifoNum sein
	CPX #fifoNum
	BCS readFirstFIFOWrongNum	
	
	TYA
	PHA	;sichere Y-Register auf den Stack
	
	TXA
	ASL	;Bestimme Offset für In-Pointer
	
	;FIFO leer, Wenn IN = OUT
	TAY
	LDA fifoAddr, Y
	;INY
	CMP fifoAddr + 1, Y
	BEQ readFirstFIFOempty	;Verzweige, wenn FIFO leer
	
	LDA fifoAddr + 1, Y	;Lade OUT-Pointer
	TAY
	
	;Berechne:
	;   Basis-Adresse	->Beginn des Datenbereiches
	; + FIFONr * fifoSize ->Pointer auf Start der FIFO
	; + fifoNum * 2	->IN-/OUT P. befinden sich vor FIFOs
	TXA	;Nr. der FIFO	
	JSR getFIFOPointer
	
	LDA (p), Y	;Lese Wert aus der FIFO
	TAX		;zunächst nach X-Register
	
	PLA
	TAY		;Rücksichern des Y-Registers
	
	TXA		;Datenbyte
	
	LDX #0		;Rückagebwert
	BEQ readFirstFIFOend
	
readFirstFIFOWrongNum:
	LDX #1
	BNE readFirstFIFOend
	
readFirstFIFOempty:
	PLA
	TAY		;Rücksichern des Y-Registers
	LDX #2
	
readFirstFIFOend:
	RTS
;-------------------------------------------------------------------	
		



;===================================================================
;Akku: Datenbyte
;X-Register: Nummer der FIFO
;TODO: Verbiete IRQs in kritischen Bereichen
;===================================================================
writeFIFO:
	PHA	;sichere Datenbyte zunächst auf den Stack
	
	TYA
	PHA	;sichere Y-Register auf den Stack
	
	TXA
	PHA	;sichere X-Register auf den Stack
	
	;Prüfe Nummer: Diese darf nicht >= fifoNum sein
	;SEC
	;TXA
	CMP #fifoNum
	BCS writeFIFOWrongNum
	
	;Prüfe ob FIFO voll: Kann auch ohne Berechnung der 
	;entsprechenden FIFO-BasisAdresse erfolgen
	;Voll = IN+1==OUT v (IN+1==SIZE & OUT==0)
	
	;TXA	;Offset für IN-Pointer berechnen
	ASL
	
	;Prüfe, ob IN+1==OUT
	TAY
	LDA fifoAddr, Y ;Lade IN-Pointer
	SEC
	ADC #0	
	;INY
	CMP fifoAddr + 1, Y ;Vergleiche mit OUT-Pointer
	BEQ writeFIFOFull
	
	;Prüfe, ob IN+1==SIZE & OUT==0
	;IN+1 steht noch im Akku
	CMP #fifoSize
	BNE writeFIFO1 ;Verzweige, wenn FIFO nicht voll
	
	;Prüfe, ob OUT==0
	LDA fifoAddr + 1, Y
	BEQ writeFIFOFull
	
writeFIFO1:
	;FIFO ist nicht voll
	TXA	;Nr. der FIFO befindet sich noch in X
	
	;Berechne:
	;   Basis-Adresse	->Beginn des Datenbereiches
	; + FIFONr * fifoSize ->Pointer auf Start der FIFO
	; + fifoNum * 2	->IN-/OUT P. befinden sich vor FIFOs
	JSR getFIFOPointer
	
	; + IN-Offset bestimmen	->Offset innerhalb der FIFO
	;DEY	;Y zeigt noch auf Out-Pointer
	
	TYA	;Sichere Offset für IN-Pointer
	PHA
	
	LDA fifoAddr, Y
	TAY	;Offset innerhalb der FIFO -> IN-Pointer
	
	;Schreibe Datenbyte in die FIFO
	TSX
	LDA $0104, X	;Hole Datenbyte vom Stack
	STA (p), Y	;Schreibe in die FIFO
	
	;Inkrementiere IN-Pointer
	INY
	CPY #fifoSize	;Prüfe, ob Ende der FIFO erreicht
	BNE writeFIFOSuccess
	LDY #0	;Zeiger wird wieder auf den Start gesetzt
		
writeFIFOSuccess:
	PLA	;Offset für IN-Pointer
	TAX
	TYA
	STA fifoAddr, X	;Speichere neuen IN-Pointer
	
	LDX #0
	BEQ writeFIFOend
	
writeFIFOWrongNum:	
	LDX #1
	BNE writeFIFOend
	
writeFIFOFull:
	LDX #2
	;BNE writeFIFOend
	
writeFIFOend:
	PLA	;Hole FIFONr vom Stack
	PLA	;Hole Y-Register vom Stack
	TAY
	PLA	;Hole Datenbyte vom Stack
	RTS
;-------------------------------------------------------------------

	
;===================================================================
;Berechnet einen Zeiger auf den Startpunkt einer FIFO!
;Akku wird nicht verändert!
;
;Parameter:
;	Akku 	-> Nr. der FIFO
;
;Ergebnis:
;	Der berechnete Pointer wird in p abgelegt	
;===================================================================
getFIFOPointer:
	PHA ;sichere FIFONr auf den Stack
	
	;Berechne Grundadresse der angesprochenen FIFO
	;Beide Operaden der Multiplikation werden direkt
	;über den Pointer übergeben

	STA p
	LDA #fifoSize	;Größe der FIFO
	STA p + 1
	JSR fifoMult	;Berechne: GrößederFIFO * FIFONR
	
	;Addiere Anzahl der belegten Bytes aller Pointer auf die 
	;Adresse, da die sich vor allen FIFOs befinden
	LDA #fifoNum	;Anzahl an belegten Bytes für die Pointer
	ASL
	
	CLC
	ADC p
	STA p
	
	LDA p+1
	ADC #0
	STA p+1
	
	;Addiere Basis-Adresse
	CLC
	LDA #<fifoData
	ADC p
	STA p
	
	LDA #>fifoData
	ADC p + 1
	STA p + 1	
	
	PLA	;Hole FIFONr wieder vom Stack
	
	;Im Pointer p befindet sich jetzt der Zeiger auf das
	;ausgewählte Element der entsprechenden FIFO
	RTS
;-------------------------------------------------------------------


;===================================================================
;Berechnet die Grundadresse der ausgewählten FIFO
;Parameter werden im Pointer abgelegt:
;	p 	: FIFONr
;	p + 1	:fifoSize
;Ergebnis in kompletten Pointer p:
;	FIFONr * fifoSize
;===================================================================	
fifoMult:
	TXA	;sichere X-Register
	PHA
	
	LDA #0
	LDX #8
	LSR p		;0 -> MSB
fifoMult1:
	BCC fifoMult2
	CLC
	ADC p + 1
fifoMult2:
	ROR		;darf nicht LSR sein
	ROR p
	DEX
	BNE fifoMult1
	
	STA p + 1	
	
	PLA
	TAX
	
	RTS
;-------------------------------------------------------------------

	
	.ORG fifoAddr
fifoData: .BYTE $00
	