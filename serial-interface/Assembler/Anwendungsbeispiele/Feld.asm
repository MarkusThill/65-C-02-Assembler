	
_serHP = $82

	.ORG $4000
	LDA #<hFeld
	STA _serHP
	LDA #>hFeld
	STA _serHP + 1
	
;===================================================================
;Sendet ein ein Feld von Bytes an den Kommunikationspartner. Die
;Adresse des Feldes wird im Pointer _serHP hinterlegt. Das erste
;Bytes des Feldes enthält die Anzahl der zu übertragenen Bytes.
;Die Routine versucht jedes Byte max. 10-mal zu übertragen. Schlägt
;dies fehl, so bricht diese Routine mit einer Fehlerkennung im
;X-Register ab. 
;Parameter:
;	keine
;Rückgabewerte:
;	X-Register: 0 -> kein Fehler, ansonsten Byte-Nr(>0) für die 
;		Übertragung fehlgeschlagen ist
;===================================================================
SPSAusFeld:
	;sichere Akku auf den Stack
	PHA
	
	;sichere Y-Register auf den Stack
	TYA
	PHA
	
	LDY #0 ;Schleifenvariable (Anzahl der Durchläufe)
	
	;Lege Anzahl der zu übertragenen Bytes auf den Stack
	LDA (_serHP), Y
	PHA
		
	;Fehler-Zähler als lokale Variable
	LDA #0
	PHA
	
_SPSAusFeld1:
	TSX
	;Prüfe, ob alle Bytes übertragen wurden
	TYA
	CMP $0102, X 
	BEQ _SPSAusFeld4
	
	INY ;Anzahl der übertragenen Bytes inkrementieren
	
	;Setze Fehler-Zähler zurück
	LDA #0 
	STA $0101, X
_SPSAusFeld2:
	LDA (_serHP), Y ;Datenbyte
	LDX #0			;Warte auf Empfänger
	JSR SPSAus
	
	;Prüfe, ob Übertragung erfolgreich verlaufen ist
	CPX #0
	BEQ _SPSAusFeld1 ;kein Fehler, Verzweige
	
	;Fehler
	TSX
	INC $0101, X
	LDA #10
	CMP $0101, X
	BNE _SPSAusFeld2
	
_SPSAusFeld3:
	;10 Fehler bei einer Übertragung, breche ab
	TYA
	TAX	;Fehlerkennung: Byte-Nr im hFeld
	BNE _SPSAusFeldEnde
	
_SPSAusFeld4:
	;Alle Bytes erfolgreich übertragen
	LDX #0	;Rückgabewert -> alles OK
	
_SPSAusFeldEnde:
	;Hole lokale Variablen vom Akku
	PLA
	PLA

	;Hole Y-Register vom Akku
	PLA
	TAY

	;Hole gesicherten Wert vom Akku vom Stack
	PLA
	RTS
;-------------------------------------------------------------------

	.ORG $6000
hFeld: .BYTE $4, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10

