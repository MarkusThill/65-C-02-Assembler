#pragma once

#include "stdafx.h"
#include "ComThread.h"

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class Stat
{
private:
	ComThread *pThread;
public:
	bool isSndActive;
	bool isRecvActive;
	int numSndBytes;
	int numRecvBytes;
	int lastErrStat;
	CString lastErrStatStr;
	int numSndErrs;
	int numRecvErrs;
	int lastSndByte;
	int lastRecvByte;
	short response;
	int sizeRecvFifo;
	int sizeSndFifo;

	//Methoden
	Stat(ComThread *pThread);
	~Stat(void);
	void resetNumSndBytes();
	void resetNumRecvBytes();
	void resetNumSndErrs();
	void resetNumRecvErrs();
	void resetAllStats();
	void setMaxSndRetrys(int trys);
};
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------