// Diese Klasse ist von CWinThread abgeleitet. Beim Erzeugen einer Instanz
// dieser Klasse wird also ein neuer Thread gestartet. Die Kommunikation mit
// dem MOSES l�uft also parallel zur eigentlichen Anwendung ab, wodurch der
// der Anwender auch zeit-intensive Programme schreiben kann, ohne dass 
// dadurch zeitliche Probleme bei der �bertragung auftreten.
// Da ein Thread den selben Adressraum wie der eigentliche Vaterprozess
// besitzt, k�nnen sehr leicht gemeinsam genutzte Betriebsmittel erzeugt 
// werden. In diesem Fall sind dies die Sende- und Empfangs-FIFOs.
// Bei der Verwendung von Threads muss besonders bei Operationen auf 
// gemeinsam genutzte Betriebsmittel darauf geachtet werden, dass bei
// gleichzeitigem Zugriff Inkonsistenzen auftreten k�nnen. In solchen F�llen
// sollten Semaphore oder �hnliche Konstrukte verwendet werden, um den 
// exklusiven Zugriff zu gew�hrleisten. Obwohl uns keine Probleme im 
// Zusammenhang mit den FIFOs aufgefallen sind, so sind diese doch 
// theoretisch m�glich. Ggfs. m�ssen die Semaphore also nachtr�glich 
// eingef�hrt werden.
//---------------------------------------------------------------------------

#include "StdAfx.h"
#include "ComThread.h"
#include "Com.h"
#include "Stat.h"
#include <windows.h>
#include <queue>

using namespace std;

//Fehlermeldungen f�r die Kommunikation
const wchar_t* ComThread::ERRSTATSTR[] = {_T("NO ERROR"), 
										  _T("SND CTS NOT ZERO"), 
										  _T("SND NEGATIVE ACK"), 
										  _T("RCV WRONG STOPBIT"), 
										  _T("RCV WRONG PARITY"), 
										  _T("RCV WRONG STARTBIT"), 
										  _T("RCV FIFO FULL")};

IMPLEMENT_DYNCREATE(ComThread, CWinThread)

//Konstruktor
ComThread::ComThread() {
	//Pointer-Initialisierungen
	sndFifo = NULL;   //Sende-FIFO
	recvFifo = NULL;  //Empfangs-FIFO
	cPort = NULL;	  //Serielle Schnittstelle

	
	//Initialisierungen f�r Sendewiederholungen
	//infiniteSndTrys = false;   //Erlaube unendlich viele Wiederholungen
	retrySnd = 0;  //Z�hler der Wiederholungen
	maxSndRetrys = -1; //max. Zahl an Wiederholungen

	//Status-Informationen
	sndActive = false;
	recvActive = false;
	recvEnabled = false;
	sndEnabled = false;
	testEnabled = false;
	dataBuf = 0;

	
	//Sende- bzw. Empfangsdaten
	numBits = 0;
	errStat = 0;
	sendACK = 0;


	//Statistikinformationen
	stat = new Stat(this);

	//weitere Statusinformationen
	numSndBytes = 0;
	numRecvBytes = 0;
	numSndErrs = 0;
	numRecvErrs = 0;
	lastSndByte = 0;
	lastRecvByte = 0;
	response = 0;
}
//---------------------------------------------------------------------------



//Destruktor

ComThread::~ComThread() {
	//Dynamisch erzeugte Objekte entfernen
	delete(stat);
}
//---------------------------------------------------------------------------



//Methode der Klasse CWinThread muss �berschrieben werden
BOOL ComThread::InitInstance() {
	return TRUE;
}
//---------------------------------------------------------------------------


//Methode der Klasse CWinThread muss �berschrieben werden
int ComThread::ExitInstance() {	

	return 0;

}
//---------------------------------------------------------------------------



// Methode der Klasse CWinThread wird �berschrieben. Wird nach dem Start des
// Threads ausgef�hrt...

int ComThread::Run() {

	//Es muss ein ComPort-Objekt angelegt sein
	ASSERT(cPort != NULL);

	//Sende-FIFO-Objekt muss bereits erzeugt sein
	ASSERT(sndFifo != NULL);

	//Empfangs-FIFO-Objekt muss bereits erzeugt sein
	ASSERT(recvFifo != NULL);

	// Diese Schleife wird �ber die gesamte Lebensdauer des Threads
	// abgearbeitet
	while(1) {

		//Pr�fe, ob Verbindung zu einem COM-Port hergestellt wurde.
		//Weitere Operationen machen erst dann einen Sinn.
		if(cPort->Connected) {
			//Pr�fe, ob der Empfang erlaubt ist...
			if(recvEnabled)
				tryReceive();

			//Pr�fe, ob die Sendefreigabe gegeben ist
			if(sndEnabled)
				trySend();

			// Ansonsten wird der Thread eine gewisse Zeit schlafen gelegt
			// damit keine CPU-Zeit verschwendet wird
			else if(!sndEnabled && !recvEnabled)
				Sleep(PAUSETIME); //Senden und Empfang sind nicht erlaubt
		}
		else
			// Lege Thread schlafen
			Sleep(PAUSETIME); 
	}
	return 0;
}
//---------------------------------------------------------------------------


// Es muss bekannt sein, aus welchen Sende-FIFO gelesen und in welchen
// Empfangs-FIFO geschrieben werden muss. Diese Methode muss daher durch
// das entsprechende Com-Objekt aufgerufen werden
void ComThread::setQueuePtr(queue<BYTE> *sndFifo, queue<BYTE> *recvFifo) {
	this->sndFifo = sndFifo;
	this->recvFifo = recvFifo;
}
//---------------------------------------------------------------------------


// Es muss bekannt sein, welcher COM-Port zur Kommunikation verwendet wird
void ComThread::setComPort(ComPort* cPort) {
	this->cPort = cPort;
}
//---------------------------------------------------------------------------


// Setzen der Empfangsfreigabe
void ComThread::setRecvEn(bool enabled) {
	recvEnabled = enabled;
}
//---------------------------------------------------------------------------


//Setzen der Sendefreigabe
void ComThread::setSndEn(bool enabled) {
	sndEnabled = enabled;
}
//---------------------------------------------------------------------------


// Ggfs. einen Empfangsvorgang einleiten
void ComThread::tryReceive() {
	//10-Zeitintervalle lang Leitung auf fallende Flanke pr�fen
	for(int i=0;i<10;i++) {
		if(cPort->CTSPoll()) { //Fallende Flanke erkannt??
			recvActive = true;
			
			//F�r Empfang ben�tigte Daten zur�cksetzen
			resetRecvData();

			//In den Empfangsmodus wechseln
			cPort->SetRTS(ComPort::OFF);

			//Zun�chst halbe Periodendauer warten
			sleep(Com::TIMEINTERVALL / 2);

			//Empfang durchf�hren
			while(!receive())
				sleep(Com::TIMEINTERVALL);
			cPort->CTSPoll();
			break; //Beende Methode nach Empfang
		}
		sleep(POLLTIME);
	}
}

//---------------------------------------------------------------------------

// Setze die f�r einen Empfangsvorgang n�tigen Informationen zur�ck
void ComThread::resetRecvData() {
	numBits = 0;
	errStat = 0;
	sendACK = 0;
	errStat = NOERR;
}
//---------------------------------------------------------------------------


// Methode zum bitweisen Empfang der Daten
bool ComThread::receive() {
	if(numBits == STARTBIT) {
		//Wechlse in den Empfangsmodus (TxD = 0)
		cPort->SetRTS(ComPort::OFF);
	}
    if(numBits == ACKBIT) {
		//Schreibe den Erfolg der Operation auf die Leitung
		if(errStat == NOERR)
			cPort->SetRTS(ComPort::ON);
		else
			numRecvErrs++;
		numBits++;
		return false;
    }
	else if(numBits == ENDBIT) {
		//In den Zustand Idle wechseln
		cPort->SetRTS(ComPort::ON);
		recvActive = false;
		return true; //�bertragung ist abgeschlossen
    }

	//Lese n�chstes Bit von der Leitung
	//Vorsicht: Das Datenbyte ist zun�chst falsch herum
	dataBuf <<= 1;
	dataBuf |= (cPort->GetCTS() ? 1 : 0);

	//Nach dem Lesen des StopBits muss Parit�t berechnet werden,
	//sowie Start- bzw. StopBit �berpr�ft werden
	if(numBits == STOPBIT) {
        //Label6->Caption = dataBuf;
		//Pr�fe StopBit
		if(!(dataBuf & 1)) 
			errStat = ERRWRONGSTOP;

		dataBuf >>= 1;

		//Parit�ts-Bit lesen
		bool parityBit = (dataBuf & 1) != 0;
		dataBuf >>= 1;

		BYTE dataByte = 0;

		//DatenBits in die richtige Reihenfolge bringen
		for(short i=0;i<8;i++, dataBuf >>= 1, dataByte <<= 1)
			if(dataBuf & 1)
				dataByte |= 1;
		//Datenbyte wurde eins zuviel geshiftet
		dataByte >>= 1;

		//Parit�t �ber die DatenBits ermitteln
		if(parityBit != parity(dataByte))
			errStat = ERRWRONGPARITY;

		//Pr�fe StartBit
		if(dataBuf & 1)
			errStat = ERRWRONGSTART;

		//Trage in die FIFO, wenn kein Fehler ermittelt wurde
		if(errStat == NOERR)
			//Jedoch muss noch Platz in der FIFO sein
			if(recvFifo->size() < Com::FIFOMAXSIZE) {
				recvFifo->push(dataByte);
				numRecvBytes++;
				lastRecvByte = dataByte;
			}
			else
				//Fehler: Empfangs-FIFO ist voll
				errStat = ERRRECVFIFOFULL;
	}
	numBits++; 	//Inkrementiere Anzahl der �bertragenen Bits
	return false; //�bertragung ist noch nicht abgeschlossen
}
//---------------------------------------------------------------------------


// Versuche ein Datenbyte zu �bertragen
void ComThread::trySend() {
	if(!sndFifo->empty()) { //Pr�fe, ob Wert in der Fifo
		BYTE sndByte = sndFifo->front();

		//Kann ein Sendeevorgang gestartet werden?
		if(startSendByte(sndByte)) {
			//F�hre die bitweise �bertragung durch
			do 
				sleep(Com::TIMEINTERVALL);
			while(!send());

			//Pr�fe, ob Fehler w�hrend des Empfangs aufgetreten ist
			if(errStat != NOERR) {
				retrySnd++;
				numSndErrs++;
			}
			else {
				// Kein Fehler
				retrySnd = 0;
				numSndBytes++;

				// Setze das zuletzt �bertragene Byte auf neuen Wert
				lastSndByte = sndByte;

				// Datenbyte kann der FIFO entnommen werden
				sndFifo->pop();
			}
			if(retrySnd > maxSndRetrys) {
				// Max. Anzahl an Sendeversuchen wurde �berschritten
				if(maxSndRetrys != -1)
					// Programmausf�hrung wird unterbrochen
					ASSERT(retrySnd <= maxSndRetrys); //Fehler melden
				retrySnd = 0;
			}
			if(!recvEnabled)
				sleep(Com::TIMEINTERVALL);
		}
	}
	else if(testEnabled) {
		sendTestFrame();
	}
	//Lege Thread schlafen, wenn Empfang nicht erlaubt und SndFIFO leer
	else if(!recvEnabled)
		sleep(PAUSETIME);
}
//---------------------------------------------------------------------------


// Versuche einen Sendevorgang zu initieren
bool ComThread::startSendByte(BYTE val) {
	bool started = false;

	//Die serielle Schnittstelle muss ge�ffnet sein
	//Es darf kein Sendevorgang aktiv sein
	//Es darf kein Empfangsvorgang aktiv sein
	//Empf�nger muss seine RTS-Leitung im Zustand Idle haben
	if(cPort->Connected && !sndActive && !recvActive 
		&& cPort->GetCTS() == ComPort::ON) {

		sndActive = started = true;
		dataBuf = generateFrame(val); //Erzeuge Frame
		if(dataBuf & 1) //Setze RTS-Leitung (Regelfall: 0)
			cPort->SetRTS(ComPort::ON);
		else
			cPort->SetRTS(ComPort::OFF);
		dataBuf >>= 1; //Entferne Start-Bit
		numBits = 1; //Startbit liegt ja bereits auf der Leitung
	}
	return started; //Wurde eine �bertragung gestartet?
}
//---------------------------------------------------------------------------


// Sende ein Datenbit
bool ComThread::send(void) {
	//Pr�fe, ob �bertragung abgeschlossen ist und lese Erfolg der Operation
	// ggfs. ein
	if(numBits == FINALBIT) {
		sendACK = cPort->GetCTS(); // Lese ACK / NACK
		numBits++;
		return false;
    }

	//Pr�fe, ob Leitung des Empf�ngers auf NULL
	if(numBits <= WAITBIT && cPort->GetCTS() == ComPort::ON) {
		//Wieder in den Zustand Idle wechseln
		cPort->SetRTS(ComPort::ON);

		//Fehler-Flag setzen
		errStat = ERRLINEZERO;
		sndActive = false;
		return true;
	}
	if(numBits == WAITBIT) {
		//Nach dem Stop-Bit in den Zustand Null wechseln
		cPort->SetRTS(ComPort::OFF);
		numBits++;
		return false; //Sofort abbrechen
	}
	if(numBits == SWAPBIT) {
		cPort->CTSPoll(); //Zun�chst alle Flanken l�schen

		//Wieder in den Zustand Idle wechseln
		cPort->SetRTS(ComPort::ON);
		errStat = sendACK ? NOERR : ERRACK;
		sndActive = false;
		return true; //�bertragung ist abgeschlossen
	}

	//Schreibe n�chstes Bit auf die Leitung
	const int nextBit = ((dataBuf & 1) ? ComPort::ON : ComPort::OFF);
   cPort->SetRTS(nextBit);
	dataBuf >>= 1; //Entferne dieses Bit aus dem Frame
	numBits++; 	//Inkrementiere Anzahl der �bertragenen Bits
	return false; //�bertragung ist noch nicht abgeschlossen
}
//---------------------------------------------------------------------------


void ComThread::sendTestFrame() {
	unsigned short tframe = testFrame; //Wert

	//Die serielle Schnittstelle muss ge�ffnet sein
	//Es darf kein Sendevorgang aktiv sein
	//Es darf kein Empfangsvorgang aktiv sein
	if(cPort->Connected && !sndActive && !recvActive) {
		//Verhalten des Empf�ngers mit response aufzeichnen
		response = 0;

		//Wechsle in den Zustand IDLE1
		//Dazu: Leitung auf Wert setzen und ca. 300ms pausieren
		//Dadurch werden direkte Reaktionen des Empf�ngers auf
		//�nderungen vermieden
		cPort->SetRTS(tframe & 1 ? ComPort::ON : ComPort::OFF);
		sleep(Com::TIMEINTERVALL * (SWAPBIT + 2));

		//Schreibe verbleibenden 15-Bits auf die Leitung
		for(short i=0;i<15;i++) {
			//zun�chst Empfangsleitung einlesen
			response |= (cPort->GetCTS() == ComPort::ON ? 1 : 0);
			response <<= 1;

			//Schreibe Bit auf RTS-Leitung
			cPort->SetRTS((tframe >>= 1) & 1 ? ComPort::ON : ComPort::OFF);
			sleep(Com::TIMEINTERVALL);
		}

		//Eins zu weit geshiftet, dies r�ckg�ngig machen
		response >>= 1;
		//Nach ca. 300ms wieder in den normal-Betrieb �bergehen
		sleep(Com::TIMEINTERVALL * (SWAPBIT + 2));
		cPort->SetRTS(ComPort::ON);
	}
	testEnabled = false;
}
//---------------------------------------------------------------------------

void ComThread::startTest(unsigned short tFrame) {
	testFrame = tFrame;
	testEnabled = true;
}
//---------------------------------------------------------------------------

bool ComThread::isTestActive() {
	return testEnabled;
}
//---------------------------------------------------------------------------


// Erzeuge den Datenframe
short ComThread::generateFrame(BYTE val) {
	short frame = val; //LSB werden benutzt
	frame <<= 1;	//Start-Bit wird hinzugef�gt
	frame |= 0x400; //Stop-Bit wird hinzugef�gt
	frame |= (parity(val) << 9); //Parit�t
	return frame;
}
//---------------------------------------------------------------------------


// Berechne die ungerade Parit�t zu einem Datenbyte
bool ComThread::parity(BYTE x) {
	BYTE count = 0;
    while(x) { //Anzahl der gesetzten Bits bestimmen
		count++;
		x &= (x-1);
	}
	return (count & 1);	//Parit�t bestimmen
}
//---------------------------------------------------------------------------


// Pr�fe, ob ein Sendevorgang zur zeit aktiv ist
bool ComThread::isSendActive(void) {
	return sndActive;
}
//---------------------------------------------------------------------------


// Pr�fe, ob ein Empfangsvorgang zur Zeit aktiv ist
bool ComThread::isReceiveActive(void) {
	return recvActive;
}
//---------------------------------------------------------------------------


// Besorge alle m�glichen Statusinformationen und gebe diese zur�ck
Stat ComThread::getStat() {
	stat->isSndActive = sndActive;
	stat->isRecvActive = recvActive;
	stat->numSndBytes = numSndBytes;
	stat->numRecvBytes = numRecvBytes;
	stat->lastErrStat = errStat;
	stat->lastErrStatStr.Format(L"%s", ERRSTATSTR[errStat]);
	stat->numSndErrs = numSndErrs;
	stat->numRecvErrs = numRecvErrs;
	stat->lastSndByte = lastSndByte;
	stat->lastRecvByte = lastRecvByte;
	stat->response = response;
	return *stat;
}
//---------------------------------------------------------------------------


// Setze alle Statistik-Informationen zur�ck
void ComThread::resetAllStats() {
	resetNumSndBytes();
	resetNumRecvBytes();
	resetNumSndErrs();
	resetNumRecvErrs(); 
}
//---------------------------------------------------------------------------


// Setze die Anzahl der �bertragenen Bytes zur�ck
void ComThread::resetNumSndBytes() {
	numSndBytes = 0;
}
//---------------------------------------------------------------------------


// Setze die Anzahl der empfangenen Datenbytes zur�ck
void ComThread::resetNumRecvBytes() {
	numRecvBytes = 0;
}
//---------------------------------------------------------------------------


// Setze die Anzahl der Sendefehler zur�ck
void ComThread::resetNumSndErrs() {
	numSndErrs = 0;
}
//---------------------------------------------------------------------------


// Setzte die Anzahl der Empfangsfehler zur�ck
void ComThread::resetNumRecvErrs() {
	numRecvErrs = 0;
}
//---------------------------------------------------------------------------


// Setze die max. Anzahl an Sendeversuchen  
void ComThread::setMaxSndRetrys(int trys) {
	maxSndRetrys = trys;
}
//---------------------------------------------------------------------------


//Dieser Timer wird vermutlich nicht ben�tigt
VOID CALLBACK _timerStopped(PVOID lpParam, BOOLEAN TimerOrWaitFired) {
    //if (lpParam == NULL) {
		//Sollte nicht auftreten
    //}
	SetEvent((HANDLE)lpParam);
}

//---------------------------------------------------------------------------


// Thread wird kurzzeitig pausiert.
bool ComThread::sleep(unsigned int msec) {
	/*HANDLE hTimer = NULL;
    HANDLE hTimerQueue = NULL;

    //Erstelle Timer-Queue
    hTimerQueue = CreateTimerQueue();
    if (NULL == hTimerQueue) {
        return false;
    }

	//Erzeuege ein Event
	HANDLE gDoneEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	if (NULL == gDoneEvent) {
			return false;
	}

	//Timer mit der gew�nschten ZEit einstellen und starten
	if (!CreateTimerQueueTimer( &hTimer, hTimerQueue, 
            &_timerStopped, gDoneEvent, msec, 0, 0)) {
			return false;
	}

	// Warte darauf, dass timer-queue thread beendet 
	//mithilfe des Event-Objektes
	// Der Thread wird dies nach der vorgegeben Zeit vornehmen
	if (WaitForSingleObject(gDoneEvent, INFINITE) != WAIT_OBJECT_0)
		return false;

	CloseHandle(gDoneEvent);

    // L�sche Timer in der Queue
    if (!DeleteTimerQueue(hTimerQueue))
        return false;
	return true;*/
		
	/*Dieser Teil ist zwar sehr genau, da
	er aber in einer Schleife l�uft wird viel zu viel unn�tige Prozessor-
	Zeit verschwendet!!!*/
	__int64 end_count, start_count;
	__int64 freq;
	float time;

	//Frequenz ermitteln
	QueryPerformanceFrequency((LARGE_INTEGER*)&freq);

	// Startzeitpunkt ermitteln
	QueryPerformanceCounter((LARGE_INTEGER*)&start_count);

	// Warte solange, bis Zeit abgelaufen ist
	do {
		QueryPerformanceCounter((LARGE_INTEGER*)&end_count);
		time = (float)(end_count - start_count) / (float)freq;
	}
	while(time < (float)msec / 1000);
	return true;
}
//---------------------------------------------------------------------------