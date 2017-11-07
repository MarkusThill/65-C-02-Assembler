// Diese Klasse ist zur Verwaltung des Status-Informationen der Kommunikation
// zuständig. Der Anwender kann sich ein Status-Objekt geben lassen und 
// anschließend entsprechend auswerten

#include "StdAfx.h"
#include "Stat.h"

// Konstruktor
Stat::Stat(ComThread *pThread) {
	//Thread-Objekt, dass die eigentliche Kommunikation mit dem MOSES
	// übernimmt, muss übergeben werden
	this->pThread = pThread;
}
//---------------------------------------------------------------------------


// Destruktor
Stat::~Stat(void) {
}
//---------------------------------------------------------------------------


// Setze alle Status-Informationen zurück
void Stat::resetAllStats() {
	pThread->resetAllStats();
}
//---------------------------------------------------------------------------


// Setze Anzahl der gesendeten Bytes zurück
void Stat::resetNumSndBytes() {
	pThread->resetNumSndBytes();
}
//---------------------------------------------------------------------------


// Setze Anzahl der empfangenen Bytes zurück
void Stat::resetNumRecvBytes() {
	pThread->resetNumRecvBytes();
}
//---------------------------------------------------------------------------


// Setze Anzahl der Sende-Fehler zurück
void Stat::resetNumSndErrs() {
	pThread->resetNumSndErrs();
}

//---------------------------------------------------------------------------


// Setze Anzahl der Empfangs-Fehler zurück
void Stat::resetNumRecvErrs() {
	pThread->resetNumRecvErrs();
}
//---------------------------------------------------------------------------


// Setze max. Anzahl Sende-Versuche im Fehlerfall
void Stat::setMaxSndRetrys(int trys) {
	pThread->setMaxSndRetrys(trys);
}
//---------------------------------------------------------------------------

