#include "ComPort.h"
#include "ComThread.h"
#include "Stat.h"
#include <queue>

#pragma once

using namespace std;


//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class Com
{
private:
	ComPort cPort;
	queue<BYTE> recvFifo;
	queue<BYTE> sndFifo;

	ComThread *pThread;

public:
	Com(void);
	~Com(void);
	void reset() ;
	void emptyRecvFifo(void);
	void emptySndFifo(void);
	void getPorts(CString *ports);
	bool openPort(int num);
	void closePort();
	void disableRecv();
	void enableRecv();
	void disableSnd();
	void enableSnd();
	int  receive();
	bool send(BYTE data);
	Stat getStat();
	bool test(unsigned short testFrame);

	//FIFO-Konstanten
	static const int FIFOMAXSIZE = 1000;
	static const int ERRREADRECVERR = -1;

	//Kommunikations-Konstanten
	static const unsigned int TIMEINTERVALL = 20;	//Periode in ms
};
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------