	.LIB "C:\SHELL\arbeit\KONST.lib"	
	.LIB "C:\SHELL\arbeit\PIAT.lib"
	.LIB "C:\SHELL\arbeit\SPSMos.lib"
	
.ORG $4000
	
	;Setze FIFO zurück
	JSR _initFIFO		
	LDA #$02
	JSR SPSIni

loop:
	LDA #0	
		
	;Startwert des Datenbytes
	STA _serSndByte
	JSR DigEin
	CMP #2	
	BEQ PEnde
		
	;Schalterstellung = 2 beendet Programm
	CMP #1	
	BNE loop		

	;SchalterStellung = 1 startet Übertragung
	;Testfolge senden
	JSR DigAus
sndLoop:	
	LDA _serSndByte
	CMP #$64		
	
	;ABBRUCHBEDINGUNG
	BEQ endLoop
	LDX #0	
	JSR SPSAus
	INC _serSndByte
	
	;Fehler?	
	TXA	
	BEQ sndLoop
	INC _serNumErrs
	BNE sndLoop

endLoop:	
	JSR DigEin	
	CMP #0
	BEQ loop
	AND #2	
	BEQ endLoop	
PEnde:	
	RTS

	.ORG $4800
;===================================================================
;Debugs / Tests	
_serNumErrs: .BYTE $00	
_serSndByte: .BYTE $00
;/Debug/Tests
;===================================================================