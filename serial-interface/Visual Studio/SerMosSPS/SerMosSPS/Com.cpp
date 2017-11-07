// Diese Klasse dient als Schnittstelle zwischen der Anwender-Klasse 
// und dem eigentlichen kommunikations-Thread. Hier sind alle nötigen
// Methoden für die Kommunikation mit dem MOSES definiert und können
// vom Anwender verwendet werden
//---------------------------------------------------------------------------

#include "StdAfx.h"
#include "Com.h"
#include "ComPort.h"

using namespace std;

// Konstruktor
Com::Com(void) {

	//FIFOs etc. zurücksetzen
	reset();	

	// Erzeuge den eigentlichen Kommunikations-Thread
	// Verwendete Klasse: ComThread
	// Priorität: Normal
	// Thread zunächst pausiert erzeugen
	pThread = (ComThread*) AfxBeginThread(	RUNTIME_CLASS(ComThread),
											THREAD_PRIORITY_NORMAL,
											NULL,
											CREATE_SUSPENDED, 
											NULL);

	//Prüfe, ob Thread erfolgreich gestartet werden konnte
	if (pThread) {
		// Setze Sende- und Empfangs-FIFO im Kommunikations-Thread
		pThread->setQueuePtr(&sndFifo, &recvFifo);

		// Zunächst Empfang und Senden deaktivieren
		disableRecv();
		disableSnd();

		// Teile Kommuniaktions-Thread den verwendeten COM-Port mit
		pThread->setComPort(&cPort);

		// Starte den Thread
		pThread->ResumeThread();
	}

	//Fehler: Thread konnte nicht gestartet werden
	ASSERT(pThread != NULL);
}
//---------------------------------------------------------------------------

// Destruktor
Com::~Com(void) {
	//Stoppe Thread und lösche Thread-Objekt
	pThread->SuspendThread();

	//Dynamisch erzeugtes Objekt muss entfernt werden
	delete(pThread);
}
//---------------------------------------------------------------------------


// Nur bei Objekt-Erzeugung aufrufen
void Com::reset() {
	//Sende- und Emfangs-FIFO zurücksetzen
	emptyRecvFifo();
	emptySndFifo();

	//Pointer zurücksetzen
	pThread = NULL;
}
//---------------------------------------------------------------------------


// Alle Elemente des Empfangs-FIFOs entfernen
void Com::emptyRecvFifo(void) {
	while(!recvFifo.empty()) {
		recvFifo.pop();
	}
}
//---------------------------------------------------------------------------


// Alle Elemente aus der Sende-FIFO löschen
void Com::emptySndFifo(void) {
	while(!sndFifo.empty()) {
		sndFifo.pop();
	}
}
//---------------------------------------------------------------------------


// Gebe die verfügbaren COM-Schnittstellen zurück
void Com::getPorts(CString *ports) {
	cPort.getPorts(ports);
}
//---------------------------------------------------------------------------


//Öffne den übergebenen COM-Port
bool Com::openPort(int num) {
	cPort.CloseCom(); //ggfs. alten Port schließen
	int stat = cPort.OpenCom(num);
	if(stat == ComPort::COMM_OK) {
		//In den Zustand Idle wechseln
		cPort.SetRTS(ComPort::ON);
		return true;
	}
	return false;
}
//---------------------------------------------------------------------------


// Schließe COM-Port
void Com::closePort() {
	cPort.CloseCom();
}
//---------------------------------------------------------------------------


// Deaktiviere Empfang
void Com::disableRecv() {
	pThread->setRecvEn(false);
}
//---------------------------------------------------------------------------


// Setze Empfangsfreigabe
void Com::enableRecv() {
	pThread->setRecvEn(true);
}
//---------------------------------------------------------------------------


// Sendefreigabe weg nehmen
void Com::disableSnd() {
	pThread->setSndEn(false);
}
//---------------------------------------------------------------------------


// Setze Sendefreigabe
void Com::enableSnd() {
	pThread->setSndEn(true);
}
//---------------------------------------------------------------------------


// Lese ein Datenbyte aus dem Empfangs-FIFO
int Com::receive() {
	// Prüfe, ob Empfangs-FIFO leer ist
	if(!recvFifo.empty()) {
		int val = (int)recvFifo.front();
		recvFifo.pop();
		return val;
	}
	return ERRREADRECVERR; //Fifo ist leer
}
//---------------------------------------------------------------------------


// Schreibe ein Datenbyte in das Sende-FIFO
bool Com::send(BYTE data) {
	// FIFO darf nicht die vorgeschriebene Größe nicht überschreiten
	if(sndFifo.size() == FIFOMAXSIZE)
		return false;

	// Schreibe in FIFO
	sndFifo.push(data);
	return true;
}
//---------------------------------------------------------------------------


// Hole Status-Informationen vom Kommunikations-Thread
Stat Com::getStat() {
	Stat stat = pThread->getStat();
	//Zwei weitere Informationen hinzufügen
	stat.sizeRecvFifo = recvFifo.size();
	stat.sizeSndFifo = sndFifo.size();
	return stat;
}

//---------------------------------------------------------------------------
bool Com::test(unsigned short testFrame) {
	if(pThread->isTestActive())
		return false;
	pThread->startTest(testFrame);
	return true;
}
//---------------------------------------------------------------------------