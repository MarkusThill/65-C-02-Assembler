	
_serHP = $82

	.ORG $4000
	LDA #<hFeld
	STA _serHP
	LDA #>hFeld
	STA _serHP + 1
	
;===================================================================
;Sendet ein ein Feld von Bytes an den Kommunikationspartner. Die
;Adresse des Feldes wird im Pointer _serHP hinterlegt. Das erste
;Bytes des Feldes enth�lt die Anzahl der zu �bertragenen Bytes.
;Die Routine versucht jedes Byte max. 10-mal zu �bertragen. Schl�gt
;dies fehl, so bricht diese Routine mit einer Fehlerkennung im
;X-Register ab. 
;Parameter:
;	keine
;R�ckgabewerte:
;	X-Register: 0 -> kein Fehler, ansonsten Byte-Nr(>0) f�r die 
;		�bertragung fehlgeschlagen ist
;===================================================================
SPSAusFeld:
	;sichere Akku auf den Stack
	PHA
	
	;sichere Y-Register auf den Stack
	TYA
	PHA
	
	LDY #0 ;Schleifenvariable (Anzahl der Durchl�ufe)
	
	;Lege Anzahl der zu �bertragenen Bytes auf den Stack
	LDA (_serHP), Y
	PHA
		
	;Fehler-Z�hler als lokale Variable
	LDA #0
	PHA
	
_SPSAusFeld1:
	TSX
	;Pr�fe, ob alle Bytes �bertragen wurden
	TYA
	CMP $0102, X 
	BEQ _SPSAusFeld4
	
	INY ;Anzahl der �bertragenen Bytes inkrementieren
	
	;Setze Fehler-Z�hler zur�ck
	LDA #0 
	STA $0101, X
_SPSAusFeld2:
	LDA (_serHP), Y ;Datenbyte
	LDX #0			;Warte auf Empf�nger
	JSR SPSAus
	
	;Pr�fe, ob �bertragung erfolgreich verlaufen ist
	CPX #0
	BEQ _SPSAusFeld1 ;kein Fehler, Verzweige
	
	;Fehler
	TSX
	INC $0101, X
	LDA #10
	CMP $0101, X
	BNE _SPSAusFeld2
	
_SPSAusFeld3:
	;10 Fehler bei einer �bertragung, breche ab
	TYA
	TAX	;Fehlerkennung: Byte-Nr im hFeld
	BNE _SPSAusFeldEnde
	
_SPSAusFeld4:
	;Alle Bytes erfolgreich �bertragen
	LDX #0	;R�ckgabewert -> alles OK
	
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

