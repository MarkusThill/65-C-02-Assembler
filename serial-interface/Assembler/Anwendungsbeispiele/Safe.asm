

	.ORG $4000



;===================================================================

;Sendet ein Byte an den Kommunikationspartner. Der Unterschied zur

;Standardroutine besteht darin, dass bei fehlgeschlagener 

;Übertragung max. 10 Wiederholungen stattfinden. Sollte auch der

;letzte Versuch fehlschlagen, wird eine Fehlerkennung im X-Register

;hinterlegt.

;Parameter:

;	Akku: zu übertragenes Datenbyte

;Rückgabewerte:

;	X-Register: 0 -> kein Fehler, ansonsten 1

;===================================================================



SPSAusR:

	;Sichere Akku auf den Stack

	PHA



	;Sichere Y-Register auf den Stack

	TYA

	PHA



	LDY #0	;Fehler-Zähler

	

_SPSAusR1:	

	;Hole Datenbyte in den Akku

	TSX

	LDA $0101, X

	

	;Es soll auf den KP gewartet werden

	LDX #0

	JSR SPSAus



	;Prüfe, ob Übertragung erfolgreich verlaufen ist

	CPX #0

	BEQ _SPSAusR2 ;kein Fehler, Verzweige

	

	;Fehler

	INY

	CPY #10

	BEQ _SPSAusR3 ;Breche ab, wenn 10 Fehler erreicht

	BNE _SPSAusR1



_SPSAusR2:

	;kein Fehler, Lade 0 ins X-Register

	LDX #0

	BEQ _SPSAusREnde



_SPSAusR3:

	;Fehler, Lade Fehlerkennung ins X-Register

	LDX #1



_SPSAusREnde:

	;Hole Y-Register vom Akku

	PLA

	TAY

	;Hole gesicherten Wert vom Akku vom Stack

	PLA

	



	RTS

;-------------------------------------------------------------------

