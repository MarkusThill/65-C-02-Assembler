	
	.LIB "C:\SHELL\arbeit\KONST.lib"
	.LIB "C:\SHELL\arbeit\PIAT.lib"
	
	.ORG $4000
	;LDA xxx
	;JSR SPSIni
	
	;Alle Pins von Port B als Ausgang
	LDA CRB
	AND #%11111011  	;Zugriff auf DDRB
	STA CRB 
	LDX #$FF			;Alle Pins als Ausgänge
	STX DDRB
	ORA #%00000100  	;Jetzt wieder Zugriff auf DRB
	STA CRB
	
	;Port A als Normalen Eingang verwenden
	;Port A sollte verwendet werden, damit nicht zufälliger-
	;weise IRQs an PortB währenden Senden/Empfang quittiert
	;werden
	LDA #%00000100
	STA CRA
	;DDRA sollte bereits korrekt beschrieben sein
	
waitDig1:
	LDA #0
	JSR DigAus
	JSR DigEin
	STA tmp ;Schalterstellung zwischenspeichern
	AND #$04
	BEQ waitDig_con 
	JMP progEnd ;Mit Schalter 3 abbrechen
	
waitDig_con:
	LDA tmp ;Schalterstellung wieder laden
	AND #$08
	;solange warten wie Schalter 4 nicht betätigt
	BEQ waitDig1
	
	;Lese Schalterstellung an PortA ein
	LDA DRA
	STA tetr2 ;zunächst zwischenspeichern
	;LSBs wegschreiben
	AND #$0F
	STA tetr1
	
	;Ermittle MSBs
	LDA tetr2
	AND #$F0 
	LSR
	LSR
	LSR
	LSR
	STA tetr2
	
	;Auszuwertende Funktion ermitteln
	;hinteren beiden Schalter
	JSR DigEin
	AND #$03
	ASL
	ASL
	ASL
	ASL
	STA tmp ;zwischenspeichern
	
	;Zum ersten Übertragungsbyte hinzufügen
	ORA tetr1
	STA tetr1
	
	;Zum zweiten Übertragungsbyte hinzufügen
	LDA tmp
	ORA tetr2
	STA tetr2
	ORA #$40	;Vordere Tetrade
	
	LDY #0
sndLoop:
	LDA tetr1, Y
	;JSR SPSAusR################################################
	CPX #0
	BNE progEnd ;Im Fehlerfall Programm beenden
	
	INY
	CPY #2
	BNE sndLoop
	
	;Warte auf Antwort der SPS
waitRecv:
	;JSR _countFIFO ############################################
	CMP #2
	BNE waitRecv
	
	;Zwei Werte in der FIFO lesen
	;JSR readFIFO ##############################################
	STA tetr1
	;JSR readFIFO ##############################################
	STA tetr2
	
	;Prüfe, ob die Funktionsnummern übereinstimmen
	LDA tetr1
	AND #%00110000
	STA tmp
	
	LDA tetr2
	AND #%00110000
	CMP tmp
	;Programm Abbrechen, wenn Nummern nicht übereinstimmen
	BNE progEnd
	
	;Verarbeite Tetrade 1
	LDA tetr1
	AND#$40 ;Prüfe, ob vordere Tetrade
	BNE tetr1_front
	
	;tetr1 ist hintere Tetrade
	LDA tetr1
	AND #$0F
	JMP test_tetr2
	
tetr1_front:
	;tetr1 ist vordere Tetrade
	LDA tetr1
	ASL
	ASL
	ASL
	ASL

test_tetr2:
	STA tmp ;Tetrade 1 zwischenspeichern
	
	;Verarbeite Tetrade 2
	LDA tetr2
	AND #$40 ;Prüfe, ob vordere Tetrade
	BNE tetr2_front
	
	;tetr2 ist hintere Tetrade
	LDA tetr2
	AND #$0F
	JMP put_together
	
tetr2_front:
	;tetr2 ist vordere Tetrade
	LDA tetr2
	ASL
	ASL
	ASL
	ASL
	
put_together:
	;Setze beide Tedraden zusammen
	ORA tmp
	STA DRB ;Ergebnis auf Port B schreiben
	
	;Prüfe, ob Programm weiter ausgeführt wird
	JSR DigEin
	AND #$04
	BEQ JMPwaitDig1
	
progEnd:
	;Programmende
	LDA #$0F
	JSR DigAus
	RTS
	
JMPwaitDig1:
	JMP waitDig1
	
	.ORG $4500
tetr1: .BYTE $00
tetr2: .BYTE $00
tmp: .BYTE
	
