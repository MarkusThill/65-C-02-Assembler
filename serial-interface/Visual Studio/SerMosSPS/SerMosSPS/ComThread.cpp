// Diese Klasse ist von CWinThread abgeleitet. Beim Erzeugen einer Instanz
// dieser Klasse wird also ein neuer Thread gestartet. Die Kommunikation mit
// dem MOSES läuft also parallel zur eigentlichen Anwendung ab, wodurch der
// der Anwender auch zeit-intensive Programme schreiben kann, ohne dass 
// dadurch zeitliche Probleme bei der Übertragung auftreten.
// Da ein Thread den selben Adressraum wie der eigentliche Vaterprozess
// besitzt, können sehr leicht gemeinsam genutzte Betriebsmittel erzeugt 
// werden. In diesem Fall sind dies die Sende- und Empfangs-FIFOs.
// Bei der Verwendung von Threads muss besonders bei Operationen auf 
// gemeinsam genutzte Betriebsmittel darauf geachtet werden, dass bei
// gleichzeitigem Zugriff Inkonsistenzen auftreten können. In solchen Fällen
// sollten Semaphore oder ähnliche Konstrukte verwendet werden, um den 
// exklusiven Zugriff zu gewährleisten. Obwohl uns keine Probleme im 
// Zusammenhang mit den FIFOs aufgefallen sind, so sind diese doch 
// theoretisch möglich. Ggfs. müssen die Semaphore also nachträglich 
// eingeführt werden.
//---------------------------------------------------------------------------

#include "StdAfx.h"
#include "ComThread.h"
#include "Com.h"
#include "Stat.h"
#include <windows.h>
#include <queue>

using namespace std;

//Fehlermeldungen für die Kommunikation
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

	
	//Initialisierungen für Sendewiederholungen
	//infiniteSndTrys = false;   //Erlaube unendlich viele Wiederholungen
	retrySnd = 0;  //Zähler der Wiederholungen
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



//Methode der Klasse CWinThread muss überschrieben werden
BOOL ComThread::InitInstance() {
	return TRUE;
}
//---------------------------------------------------------------------------


//Methode der Klasse CWinThread muss überschrieben werden
int ComThread::ExitInstance() {	

	return 0;

}
//---------------------------------------------------------------------------



// Methode der Klasse CWinThread wird überschrieben. Wird nach dem Start des
// Threads ausgeführt...

int ComThread::Run() {

	//Es muss ein ComPort-Objekt angelegt sein
	ASSERT(cPort != NULL);

	//Sende-FIFO-Objekt muss bereits erzeugt sein
	ASSERT(sndFifo != NULL);

	//Empfangs-FIFO-Objekt muss bereits erzeugt sein
	ASSERT(recvFifo != NULL);

	// Diese Schleife wird über die gesamte Lebensdauer des Threads
	// abgearbeitet
	while(1) {

		//Prüfe, ob Verbindung zu einem COM-Port hergestellt wurde.
		//Weitere Operationen machen erst dann einen Sinn.
		if(cPort->Connected) {
			//Prüfe, ob der Empfang erlaubt ist...
			if(recvEnabled)
				tryReceive();

			//Prüfe, ob die Sendefreigabe gegeben ist
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
	//10-Zeitintervalle lang Leitung auf fallende Flanke prüfen
	for(int i=0;i<10;i++) {
		if(cPort->CTSPoll()) { //Fallende Flanke erkannt??
			recvActive = true;
			
			//Für Empfang benötigte Daten zurücksetzen
			resetRecvData();

			//In den Empfangsmodus wechseln
			cPort->SetRTS(ComPort::OFF);

			//Zunächst halbe Periodendauer warten
			sleep(Com::TIMEINTERVALL / 2);

			//Empfang durchführen
			while(!receive())
				sleep(Com::TIMEINTERVALL);
			cPort->CTSPoll();
			break; //Beende Methode nach Empfang
		}
		sleep(POLLTIME);
	}
}

//---------------------------------------------------------------------------

// Setze die für einen Empfangsvorgang nötigen Informationen zurück
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
		return true; //Übertragung ist abgeschlossen
    }

	//Lese nächstes Bit von der Leitung
	//Vorsicht: Das Datenbyte ist zunächst falsch herum
	dataBuf <<= 1;
	dataBuf |= (cPort->GetCTS() ? 1 : 0);

	//Nach dem Lesen des StopBits muss Parität berechnet werden,
	//sowie Start- bzw. StopBit überprüft werden
	if(numBits == STOPBIT) {
        //Label6->Caption = dataBuf;
		//Prüfe StopBit
		if(!(dataBuf & 1)) 
			errStat = ERRWRONGSTOP;

		dataBuf >>= 1;

		//Paritäts-Bit lesen
		bool parityBit = (dataBuf & 1) != 0;
		dataBuf >>= 1;

		BYTE dataByte = 0;

		//DatenBits in die richtige Reihenfolge bringen
		for(short i=0;i<8;i++, dataBuf >>= 1, dataByte <<= 1)
			if(dataBuf & 1)
				dataByte |= 1;
		//Datenbyte wurde eins zuviel geshiftet
		dataByte >>= 1;

		//Parität über die DatenBits ermitteln
		if(parityBit != parity(dataByte))
			errStat = ERRWRONGPARITY;

		//Prüfe StartBit
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
	numBits++; 	//Inkrementiere Anzahl der übertragenen Bits
	return false; //Übertragung ist noch nicht abgeschlossen
}
//---------------------------------------------------------------------------


// Versuche ein Datenbyte zu übertragen
void ComThread::trySend() {
	if(!sndFifo->empty()) { //Prüfe, ob Wert in der Fifo
		BYTE sndByte = sndFifo->front();

		//Kann ein Sendeevorgang gestartet werden?
		if(startSendByte(sndByte)) {
			//Führe die bitweise Übertragung durch
			do 
				sleep(Com::TIMEINTERVALL);
			while(!send());

			//Prüfe, ob Fehler während des Empfangs aufgetreten ist
			if(errStat != NOERR) {
				retrySnd++;
				numSndErrs++;
			}
			else {
				// Kein Fehler
				retrySnd = 0;
				numSndBytes++;

				// Setze das zuletzt übertragene Byte auf neuen Wert
				lastSndByte = sndByte;

				// Datenbyte kann der FIFO entnommen werden
				sndFifo->pop();
			}
			if(retrySnd > maxSndRetrys) {
				// Max. Anzahl an Sendeversuchen wurde überschritten
				if(maxSndRetrys != -1)
					// Programmausführung wird unterbrochen
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

	//Die serielle Schnittstelle muss geöffnet sein
	//Es darf kein Sendevorgang aktiv sein
	//Es darf kein Empfangsvorgang aktiv sein
	//Empfänger muss seine RTS-Leitung im Zustand Idle haben
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
	return started; //Wurde eine Übertragung gestartet?
}
//---------------------------------------------------------------------------


// Sende ein Datenbit
bool ComThread::send(void) {
	//Prüfe, ob Übertragung abgeschlossen ist und lese Erfolg der Operation
	// ggfs. ein
	if(numBits == FINALBIT) {
		sendACK = cPort->GetCTS(); // Lese ACK / NACK
		numBits++;
		return false;
    }

	//Prüfe, ob Leitung des Empfängers auf NULL
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
		cPort->CTSPoll(); //Zunächst alle Flanken löschen

		//Wieder in den Zustand Idle wechseln
		cPort->SetRTS(ComPort::ON);
		errStat = sendACK ? NOERR : ERRACK;
		sndActive = false;
		return true; //Übertragung ist abgeschlossen
	}

	//Schreibe nächstes Bit auf die Leitung
	const int nextBit = ((dataBuf & 1) ? ComPort::ON : ComPort::OFF);
   cPort->SetRTS(nextBit);
	dataBuf >>= 1; //Entferne dieses Bit aus dem Frame
	numBits++; 	//Inkrementiere Anzahl der übertragenen Bits
	return false; //Übertragung ist noch nicht abgeschlossen
}
//---------------------------------------------------------------------------


void ComThread::sendTestFrame() {
	unsigned short tframe = testFrame; //Wert

	//Die serielle Schnittstelle muss geöffnet sein
	//Es darf kein Sendevorgang aktiv sein
	//Es darf kein Empfangsvorgang aktiv sein
	if(cPort->Connected && !sndActive && !recvActive) {
		//Verhalten des Empfängers mit response aufzeichnen
		response = 0;

		//Wechsle in den Zustand IDLE1
		//Dazu: Leitung auf Wert setzen und ca. 300ms pausieren
		//Dadurch werden direkte Reaktionen des Empfängers auf
		//Änderungen vermieden
		cPort->SetRTS(tframe & 1 ? ComPort::ON : ComPort::OFF);
		sleep(Com::TIMEINTERVALL * (SWAPBIT + 2));

		//Schreibe verbleibenden 15-Bits auf die Leitung
		for(short i=0;i<15;i++) {
			//zunächst Empfangsleitung einlesen
			response |= (cPort->GetCTS() == ComPort::ON ? 1 : 0);
			response <<= 1;

			//Schreibe Bit auf RTS-Leitung
			cPort->SetRTS((tframe >>= 1) & 1 ? ComPort::ON : ComPort::OFF);
			sleep(Com::TIMEINTERVALL);
		}

		//Eins zu weit geshiftet, dies rückgängig machen
		response >>= 1;
		//Nach ca. 300ms wieder in den normal-Betrieb übergehen
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
	frame <<= 1;	//Start-Bit wird hinzugefügt
	frame |= 0x400; //Stop-Bit wird hinzugefügt
	frame |= (parity(val) << 9); //Parität
	return frame;
}
//---------------------------------------------------------------------------


// Berechne die ungerade Parität zu einem Datenbyte
bool ComThread::parity(BYTE x) {
	BYTE count = 0;
    while(x) { //Anzahl der gesetzten Bits bestimmen
		count++;
		x &= (x-1);
	}
	return (count & 1);	//Parität bestimmen
}
//---------------------------------------------------------------------------


// Prüfe, ob ein Sendevorgang zur zeit aktiv ist
bool ComThread::isSendActive(void) {
	return sndActive;
}
//---------------------------------------------------------------------------


// Prüfe, ob ein Empfangsvorgang zur Zeit aktiv ist
bool ComThread::isReceiveActive(void) {
	return recvActive;
}
//---------------------------------------------------------------------------


// Besorge alle möglichen Statusinformationen und gebe diese zurück
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


// Setze alle Statistik-Informationen zurück
void ComThread::resetAllStats() {
	resetNumSndBytes();
	resetNumRecvBytes();
	resetNumSndErrs();
	resetNumRecvErrs(); 
}
//---------------------------------------------------------------------------


// Setze die Anzahl der übertragenen Bytes zurück
void ComThread::resetNumSndBytes() {
	numSndBytes = 0;
}
//---------------------------------------------------------------------------


// Setze die Anzahl der empfangenen Datenbytes zurück
void ComThread::resetNumRecvBytes() {
	numRecvBytes = 0;
}
//---------------------------------------------------------------------------


// Setze die Anzahl der Sendefehler zurück
void ComThread::resetNumSndErrs() {
	numSndErrs = 0;
}
//---------------------------------------------------------------------------


// Setzte die Anzahl der Empfangsfehler zurück
void ComThread::resetNumRecvErrs() {
	numRecvErrs = 0;
}
//---------------------------------------------------------------------------


// Setze die max. Anzahl an Sendeversuchen  
void ComThread::setMaxSndRetrys(int trys) {
	maxSndRetrys = trys;
}
//---------------------------------------------------------------------------


//Dieser Timer wird vermutlich nicht benötigt
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

	//Timer mit der gewünschten ZEit einstellen und starten
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

    // Lösche Timer in der Queue
    if (!DeleteTimerQueue(hTimerQueue))
        return false;
	return true;*/
		
	/*Dieser Teil ist zwar sehr genau, da
	er aber in einer Schleife läuft wird viel zu viel unnötige Prozessor-
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