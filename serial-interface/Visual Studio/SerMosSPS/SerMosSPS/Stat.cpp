// Diese Klasse ist zur Verwaltung des Status-Informationen der Kommunikation
// zust�ndig. Der Anwender kann sich ein Status-Objekt geben lassen und 
// anschlie�end entsprechend auswerten

#include "StdAfx.h"
#include "Stat.h"

// Konstruktor
Stat::Stat(ComThread *pThread) {
	//Thread-Objekt, dass die eigentliche Kommunikation mit dem MOSES
	// �bernimmt, muss �bergeben werden
	this->pThread = pThread;
}
//---------------------------------------------------------------------------


// Destruktor
Stat::~Stat(void) {
}
//---------------------------------------------------------------------------


// Setze alle Status-Informationen zur�ck
void Stat::resetAllStats() {
	pThread->resetAllStats();
}
//---------------------------------------------------------------------------


// Setze Anzahl der gesendeten Bytes zur�ck
void Stat::resetNumSndBytes() {
	pThread->resetNumSndBytes();
}
//---------------------------------------------------------------------------


// Setze Anzahl der empfangenen Bytes zur�ck
void Stat::resetNumRecvBytes() {
	pThread->resetNumRecvBytes();
}
//---------------------------------------------------------------------------


// Setze Anzahl der Sende-Fehler zur�ck
void Stat::resetNumSndErrs() {
	pThread->resetNumSndErrs();
}

//---------------------------------------------------------------------------


// Setze Anzahl der Empfangs-Fehler zur�ck
void Stat::resetNumRecvErrs() {
	pThread->resetNumRecvErrs();
}
//---------------------------------------------------------------------------


// Setze max. Anzahl Sende-Versuche im Fehlerfall
void Stat::setMaxSndRetrys(int trys) {
	pThread->setMaxSndRetrys(trys);
}
//---------------------------------------------------------------------------

