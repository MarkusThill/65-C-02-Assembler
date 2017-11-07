#pragma once
#include "stdafx.h"
#include <windows.h>
#include "ComPort.h"
#include <queue>

using namespace std;


class Stat;
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class ComThread : public CWinThread {

private:
	bool recvEnabled;
	bool sndEnabled;
	bool sndActive;
	bool recvActive;
	short dataBuf;

	//TestFrame übertragen
	bool testEnabled;
	BYTE numBits;
	BYTE errStat;
	BYTE sendACK;

	//Zeiger auf Sende- bzw. Empfangs-FIFO
	queue<BYTE>* recvFifo;
	queue<BYTE>* sndFifo;

	//Senden im Fehlerfall wiederholen
	unsigned int retrySnd;  //Zähler der Wiederholungen
	unsigned int maxSndRetrys; //max. Zahl an Wiederholungen (-1 = unendlich)

	//Zeiger auf die Com-Schnittstelle
	ComPort *cPort;

	//Statistik-Elemente
	unsigned int numSndBytes;
	unsigned int numRecvBytes;
	unsigned int numSndErrs;
	unsigned int numRecvErrs;
	int lastSndByte;
	int lastRecvByte;
	Stat *stat;

	//Nur bei Benutzen des Testframes verändert
	short response;
	unsigned short testFrame;

	//Allgemeine Konstanten
	//Wartezeit, falls Senden und Empfang nicht erlaubt
	static const unsigned int PAUSETIME = 1000;

	//Für RTS- / CTS-Leitungen
	static const bool OFF = false;
	static const bool ON = true;
	static const unsigned int POLLTIME = 2;

	//Konstanten betreffend numBits
	//Sender:
	static const BYTE WAITBIT = 11;
	static const BYTE FINALBIT = 12;
	static const BYTE SWAPBIT = 13;

	//Empfänger:
	static const BYTE STARTBIT = 0;
	static const BYTE STOPBIT = 10;
	static const BYTE ACKBIT = 11;
	static const BYTE ENDBIT = 12;

	//Fehler-Konstanten für errStat
	//Sender:
	static const BYTE NOERR = 0;
	static const BYTE ERRLINEZERO = 1;
	static const BYTE ERRACK = 2;

	//Empfänger:
	static const BYTE ERRWRONGSTOP = 3;
	static const BYTE ERRWRONGPARITY = 4;
	static const BYTE ERRWRONGSTART = 5;
	static const BYTE ERRRECVFIFOFULL = 6;

	//Fehler-Strings;
	static const wchar_t *ERRSTATSTR[];

	//Strings max. 22 Zeichen

	//Methoden
	bool sleep(unsigned int msec);
	void tryReceive();
	void resetRecvData();
	bool receive();
	void trySend();
	bool startSendByte(BYTE val);
	bool send(void);
	void sendTestFrame();
	short generateFrame(BYTE val);
	bool parity(BYTE x);
//---------------------------------------------------------------------------

public:
	DECLARE_DYNCREATE(ComThread)
	ComThread();
	~ComThread();

	virtual BOOL InitInstance();
	virtual int ExitInstance();
	virtual int Run();

	void setQueuePtr(queue<BYTE> *sndFifo, queue<BYTE> *recvFifo);
	void setComPort(ComPort* cPort);
	void setRecvEn(bool enabled);
	void setSndEn(bool enabled);
	bool isSendActive(void);
	bool isReceiveActive(void);
	Stat getStat();
	void resetAllStats();
	void resetNumSndBytes();
	void resetNumRecvBytes();
	void resetNumSndErrs();
	void resetNumRecvErrs();
	void setMaxSndRetrys(int trys);
	void startTest(unsigned short tFrame);
	bool isTestActive();
//---------------------------------------------------------------------------

	protected:
};
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------





