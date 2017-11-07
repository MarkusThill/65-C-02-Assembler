#include "stdafx.h"
#include <windows.h>

#pragma once


//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class TestTimer : public CWinThread
{
private:
	__int64 startTime;
	unsigned int countTestIntervall; 
	unsigned int maxTestIntervalls;
	float diffTestSum;
	float avgDiff;
	unsigned int intervallTime;
	bool timerTestActive;
	HWND parent;

	int lastErr;

	//Methoden
	void newTest(unsigned int numTestIntervalls, 
		unsigned int intervallTime);
	bool regNextTime();
	bool active(void);
	void resetAll();
	void startThreadTimer(unsigned int time);
	void testStdTimer();

public:
	DECLARE_DYNCREATE(TestTimer)
	TestTimer(void);
	~TestTimer(void);

	virtual BOOL InitInstance();
	virtual int ExitInstance();

	float getAvgDiff(void);
	bool startTimerTest(int testType, HWND parent, 
		unsigned int numTestIntervalls, unsigned int intervallTime);

	//Konstanten
	static const int THREADTIMERTEST = 1;
	static const int STDTIMERTEST = 2;

	//Fehler-Konstanten
	static const int CREATETIMERQUEUE = 1;
	static const int CREATEEVENT = 2;
	static const int CREATETIMERQUEUETIMER = 3;

protected:
	void OnThreadMsg(WPARAM idEvent, LPARAM param);
	DECLARE_MESSAGE_MAP()
};
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

