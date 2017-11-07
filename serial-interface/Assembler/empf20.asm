	.LIB "C:\SHELL\arbeit\KONST.lib"
	.LIB "C:\SHELL\arbeit\PIAT.lib"
	.LIB "C:\SHELL\arbeit\SPSMos.lib"

	.ORG $4000

	;Setze FIFO zurück
	JSR _initFIFO
	
	LDA #$02
	JSR SPSIni

loop:
	JSR SPSEin
	CPX #0
	BNE loop_1
	JSR DigAus 
loop_1:
	JSR DigEin
	CMP #1
	BNE loop

	RTS