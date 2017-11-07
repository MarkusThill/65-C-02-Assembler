#include "StdAfx.h"
#include "TestTimer.h"
#include "ThreadTimer.h"
#include <windows.h>
#include <math.h>

//using namespace std;

IMPLEMENT_DYNCREATE(TestTimer, CWinThread)

TestTimer::TestTimer(void) {
	timerTestActive = false;
	parent = NULL;
}
//---------------------------------------------------------------------------


TestTimer::~TestTimer(void) {
}
//---------------------------------------------------------------------------


BEGIN_MESSAGE_MAP(TestTimer, CWinThread)
	ON_THREAD_MESSAGE(WM_THREAD_TERMINATED,	OnThreadMsg)
	ON_THREAD_MESSAGE(WM_THREAD_START_STDTIMERTEST,	OnThreadMsg)
END_MESSAGE_MAP()
//---------------------------------------------------------------------------


BOOL TestTimer::InitInstance() {
	return TRUE;
}
//---------------------------------------------------------------------------


int TestTimer::ExitInstance() {	
	return 0;
}
//---------------------------------------------------------------------------


void TestTimer::OnThreadMsg(WPARAM idEvent, LPARAM param) {
	switch(idEvent) {
		case WM_THREAD_START_STDTIMERTEST:
			testStdTimer();
			break;
		case WM_THREAD_TERMINATED:
			if(active()) {
				//Prüfe, ob alle Tests durchgelaufen sind
				if(regNextTime()) {
					::SendMessage(parent, WM_TESTTIMER_FINISHED, 
						WM_TESTTIMER_FINISHED, THREADTIMERTEST);
					timerTestActive  = false;
				}
				else {
					//Starte neuen Thread
					startThreadTimer((unsigned int)intervallTime);	
				}
			}
			break;
		default:
			break;
	}
}
//---------------------------------------------------------------------------


VOID CALLBACK TimerRoutine(PVOID lpParam, BOOLEAN TimerOrWaitFired) {
    if (lpParam == NULL) {
        ;//TODO: Exception
    }
	SetEvent((HANDLE)lpParam);
}
//---------------------------------------------------------------------------


void TestTimer::testStdTimer() {
	HANDLE hTimer = NULL;
    HANDLE hTimerQueue = NULL;

    //Erstelle Timer-Queue
    hTimerQueue = CreateTimerQueue();
    if (NULL == hTimerQueue) {
        lastErr = CREATETIMERQUEUE;
        return;
    }

	//Führe x Timer-Tests durch
	do {
		//Erzeuege ein Event
		HANDLE gDoneEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
		if (NULL == gDoneEvent) {
			lastErr = CREATEEVENT;
			return;
		}

		//Timer mit der gewünschten ZEit einstellen und starten
		if (!CreateTimerQueueTimer( &hTimer, hTimerQueue, 
            &TimerRoutine, gDoneEvent , intervallTime, 0, 0)) {
			lastErr = CREATETIMERQUEUETIMER;
			return;
		}

		// Warte darauf, dass timer-queue thread beendet mithilfe des Event-Objektes
		// Der Thread wird dies nach der vorgegeben Zeit vornehmen
		if (WaitForSingleObject(gDoneEvent, INFINITE) != WAIT_OBJECT_0)
			lastErr = lastErr;//TODO: Exception

		CloseHandle(gDoneEvent);
		//Sleep(20);
	}
	while(!regNextTime());

	//Benachrichtige Haupt-Anwendung
	::SendMessage(parent, WM_TESTTIMER_FINISHED, WM_TESTTIMER_FINISHED, 
		STDTIMERTEST);
	timerTestActive  = false;
    // Lösche alle Timer in der Queue
    if (!DeleteTimerQueue(hTimerQueue))
        lastErr = lastErr;//TODO: Exception
}
//---------------------------------------------------------------------------

bool TestTimer::startTimerTest(int testType, HWND parent, 
					unsigned int numTestIntervalls, unsigned int intervallTime) {
	if(!active()) {
		resetAll();
		this->parent = parent;
		newTest(numTestIntervalls, intervallTime);

		if(testType == THREADTIMERTEST) //ThreadTimer
			startThreadTimer(intervallTime);
		else if(testType == STDTIMERTEST) //Standard-Timer
			//testStdTimer();
			this->PostThreadMessage(WM_THREAD_START_STDTIMERTEST, 
				WM_THREAD_START_STDTIMERTEST, NULL);
		else
			return false; //Fehler: falscher Parameter
		return true;
	}
	return false; //Test ist noch aktiv
}
//---------------------------------------------------------------------------


void TestTimer::newTest(unsigned int numTestIntervalls, 
								unsigned int intervallTime) {

	//Anzahl der Durchläufe
	maxTestIntervalls = numTestIntervalls;

	//Anzahl der Durchläufe zurücksetzen
	countTestIntervall = 0;

	//Summe der Abweichungen zurücksetzen
	diffTestSum = 0.0;

	//Durchschnittliche Abweichung zurücksetzen
	avgDiff = 0.0;

	//Dauer eines Zeitintervalls
	this->intervallTime = intervallTime;

	//Speichere Startzeit
	QueryPerformanceCounter((LARGE_INTEGER*)&startTime);

	//Test ist jetzt aktiv
	timerTestActive = true;
}
//---------------------------------------------------------------------------


bool TestTimer::regNextTime() {
	__int64 end_count;
	__int64 freq;
	float time;

	// Get the frequency and save it, it shouldn't change
	QueryPerformanceFrequency((LARGE_INTEGER*)&freq);		
	QueryPerformanceCounter((LARGE_INTEGER*)&end_count);

	//Zeitdifferenz berechnen
	time = (float)(end_count - startTime) / (float)freq;

	//Addiere Differenz zur Summe
	diffTestSum += fabs((float)(time - (float)intervallTime / 1000));

	//Durchläufe hochzählen
	if(++countTestIntervall >= maxTestIntervalls) {
		avgDiff = (float)1000.0 * diffTestSum / (float) countTestIntervall;
		timerTestActive = false; //Test ist abgeschlossen
		return true; //Alle Durchläufe abgeschlossen
	}
	else
		QueryPerformanceCounter((LARGE_INTEGER*)&startTime);
	return false;
}
//---------------------------------------------------------------------------


float TestTimer::getAvgDiff(void) {
	return avgDiff; 
}
//---------------------------------------------------------------------------


bool TestTimer::active(void) {
	return timerTestActive; 
}
//---------------------------------------------------------------------------


void TestTimer::resetAll() {
	startTime = 0;
	countTestIntervall = 0; 
	maxTestIntervalls = 0;
	diffTestSum = 0.0;
	avgDiff = 0.0;
	intervallTime = 0;
	timerTestActive = false;
}
//---------------------------------------------------------------------------


void TestTimer::startThreadTimer(unsigned int time) {
	ThreadTimer* adapter = new ThreadTimer() ;
	//adapter->SethWnd(AfxGetMainWnd()->m_hWnd);
	adapter->CreateThread(CREATE_SUSPENDED) ;
	adapter->m_bAutoDelete = true ;
	//adapter->sName = _T("Test") ; 
	adapter->setParent(this);

	//Für QueryPerformanceTimer benötigt
	//float sec = (float)time / (float)1000.0;
	//adapter->setWaitTime(sec);
	adapter->setWaitTime((float)time);
	adapter->ResumeThread() ;
}
//---------------------------------------------------------------------------