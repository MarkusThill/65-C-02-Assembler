// Dies ist ein Timer, der in einem Thread l�uft und bei Ablauf den 
// Vater-Prozess benachrichtigt. Urspr�nglich sollte dieser Timer genauer
// sein als die Standard-Timer. Auf gewissen PCs ist die Abweichung dennoch
// zu gro�, sodass auf die Verwendung verzichtet wird.
#include "StdAfx.h"
#include "ThreadTimer.h"

// Konstruktor
ThreadTimer::ThreadTimer(void) {
	waitTime = (float) 0.02;
}
//---------------------------------------------------------------------------

// Destruktor
ThreadTimer::~ThreadTimer(void) {
}
//---------------------------------------------------------------------------


// Geerbte Methode wird �berschrieben
BOOL ThreadTimer::InitInstance() {
    return TRUE;
}
//---------------------------------------------------------------------------


int ThreadTimer::Run() {
	/*Dieser auskommentierte Teil ist zwar sehr genau, da
	er aber in einer Schleife l�uft wird viel zu viel unn�tige Prozessor-
	Zeit verschwendet!!!*/
	/*__int64 end_count, start_count;
	__int64 freq;
	float time;

	//Frequenz ermitteln
	QueryPerformanceFrequency((LARGE_INTEGER*)&freq);
	QueryPerformanceCounter((LARGE_INTEGER*)&start_count);
	do {
		QueryPerformanceCounter((LARGE_INTEGER*)&end_count);
		time = (float)(end_count - start_count) / (float)freq;
	}
	while(time < waitTime);*/

	//Auch extrem genau
	Sleep((int)waitTime);

	//Nachricht an Vater-Prozess schicken, dass Zeit abgelaufen ist
	parent->PostThreadMessage(WM_THREAD_TERMINATED, WM_THREAD_TERMINATED, NULL);
	return 0;
}
//---------------------------------------------------------------------------


// Vater-Prozess setzen, f�r Benachrichtigung ben�tigt
void ThreadTimer::setParent(CWinThread* parent) {
	this->parent = parent;
}
//---------------------------------------------------------------------------


// Stelle Wartezeit ein
void ThreadTimer::setWaitTime(float time) {
	waitTime = time;
}
//---------------------------------------------------------------------------