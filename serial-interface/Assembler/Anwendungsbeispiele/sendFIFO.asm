
;Mit diesen Routinen kann ein Sende-FIFO verwendet werden, in den
;ganz einfach Datenbytes geschrieben und an die SPS
;�bertragen werden k�nnen. Sollten mehrere Sende-FIFOs 
;unterschiedlicher Proirit�t ben�tigt werden, so k�nnen diese
;Programme als Vorlage dienen

;N�tige Subroutinen bitte den entsprechenden Bibliotheken entnehmen:
;	SPSAusR
;	_initFIFO
;	_deleteFIFO
;	_readFIFO
;	_readFirstFIFO
;	_writeFIFO
;	_getFIFOPointer
;	_fifoMult
;
;Konstanten festlegen:
;	_fifoNum  = $2 
;	Sonst -> Eigene Wahl
	
	
;===================================================================
	;TestProgramm
;===================================================================
	.ORG $4000
	JSR _initFIFO
	LDA #1
	JSR putFIFO
	
	LDA #2
	JSR putFIFO
	
	LDA #3
	JSR putFIFO
	
	LDA #$FF
	JSR sendNum
	
	JSR _deleteFIFO
	
	RTS

;===================================================================
;Schreibt ein Daten-Byte in den Sendepuffer
;Parameter:
;	Akku -> Datenbyte
;R�ckgabewerte:
;	X-Register -> 2 (FIFO voll), 0 sonst
;===================================================================
putFIFO:
	LDX #1	;Sende-FIFO ist Nr. 1
	JSR _writeFIFO
	
	;Im X-Register befindet sich bereits der R�ckgabewert
	RTS
;-------------------------------------------------------------------

;===================================================================
;Sendet eine gewisse Anzahl an Bytes an den Kommunikations-Partner
;Die Werte werden der FIFO entnommen. Ist die FIFO leer, so wird
;diese Routine fr�hzeitig beendet. Im Fehlerfall wird jedes Byte
;max. 10x �bertragen. Im endg�ltigen Fehlerfall bleibt das
;Datenbyte jedoch in der FIFO erhalten.
;Parameter:
;	Akku -> Max. Anzahl der zu �bertragenen Bytes (max. FF)
;R�ckgabewerte:
;	X-register:
;	0 -> Alle Datenbytes wurden �bertragen (FIFO ist leer)
;	1 -> Max. Anzahl Datenbytes �bertragen (FIFO ist nicht leer)
;	2 -> Fehler bei �bertragung eines Datenbytes (10x)
;===================================================================
sendNum:
	PHA	;sichere max. Anzahl der �bertragungen
	TAX
	
	TYA	;sichere Y-Register auf den Stack
	PHA
	
	TXA	
	TAY	;Anzahl der max. zu �bertr. Bytes ins Y-Register
_sendNum1:	;Schleife, zur �bertragung der einzelnen Bytes
	
	LDX #1	;Aus dem SendeFIFO lesen (noch nicht L�schen)
	JSR _readFirstFIFO
	CPX #2	;X-Register abfragen (Pr�fe, ob Leer)
	BEQ _sendNumEmpty	;Abbrechen, wenn FIFO leer
	
	JSR SPSAusR	;Versuche Datenbyte zu �bertragen
	CPX #1		;Frage X-Register ab
	BEQ _sendNumError ;Im Fehlerfall abbrechen
	
	INX	;X ist jetzt 1
	JSR _readFIFO	;alles erfolgreich, entferne aus FIFO
	
	DEY
	BNE _sendNum1	;Breche ab, wenn max. Zahl erreicht

	;FIFO kann leer sein, wenn im letzten Schleifendurchlauf
	;das letzte Byte aus der FIFO entfernt wurde
	CPX #2
	BEQ _sendNumEmpty ;Verzweige, wenn FIFO leer ist
	
	;FIFO ist noch nicht leer
	LDX #1		;R�ckgabewert
	BNE _sendNumend
	
_sendNumEmpty:
	LDX #0
	BEQ _sendNumend
	
_sendNumError:
	LDX #2
	;BNE _sendNumend
	
_sendNumend:
	PLA
	TAY	;Y-Register wiederherstellen
	
	PLA	;Akku wiederherstellen
	RTS
	