
	.ORG $4000

;===================================================================
;Sendet die aktuelle SchDalterstellung am MOSES an den 
;Kommunikationspartner. ie Routine versucht das Byte max. 
;10-mal zu �bertragen. Schl�gt dies fehl, so bricht diese Routine 
;mit einer Fehlerkennung im X-Register ab. 
;Parameter:
;	keine
;R�ckgabewerte:
;	X-Register: 0 -> kein Fehler, ansonsten 1
;===================================================================

SPSAusDigEin:
	;sichere Akku auf den Stack
	PHA

	;sichere Y-Register auf den Stack
	TYA
	PHA

	LDY #0 ;Fehler-Z�hler

_SPSAusDigEin1:
	JSR DigEin 	;Lese aktuelle Schalterstellung ein
	LDX #0
	JSR SPSAus	;Versuche an KP zu senden

	;Pr�fe, ob �bertragung erfolgreich verlaufen ist
	CPX #0
	BEQ _SPSAusDigEinEnde ;kein Fehler, Verzweige
	
	;Fehler
	INY
	CPY #10
	BEQ _SPSAusDigEin3 ;Breche ab, wenn 10 Fehler erreicht
	BNE _SPSAusDigEin1

_SPSAusDigEin3:
	;Fehler, Lade Fehlerkennung ins X-Register
	LDX #1

_SPSAusDigEinEnde:
	;Hole Y-Register vom Akku
	PLA
	TAY

	;Hole gesicherten Wert vom Akku vom Stack
	PLA
	RTS
;-------------------------------------------------------------------	