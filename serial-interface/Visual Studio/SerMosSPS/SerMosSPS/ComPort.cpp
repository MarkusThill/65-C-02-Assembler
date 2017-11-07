//Diese Klasse ist f�r den Zugriff und die Kommunikation mit
//der seriellen Schnittstelle zust�ndig. Hier finden sich Methoden
// zum �ffnen und Schlie�en von COM-Ports, sowie zur Kommunikation
// und Verwaltung.
//---------------------------------------------------------------------------

#include "StdAfx.h"
#include "ComPort.h"

//Konstruktor
ComPort::ComPort(void) {
   hCom=INVALID_HANDLE_VALUE;
   Connected=false;
   CTSstat = OFF;
}
//---------------------------------------------------------------------------

//Destruktor
ComPort::~ComPort(void) {
   CloseCom();
}
//---------------------------------------------------------------------------

//liefert das Handle des Ports
HANDLE ComPort::GetHCom(void) {
   return hCom;
}
//---------------------------------------------------------------------------

//�ffnet einen Port mit der Nummer, die �bergeben wird
int ComPort::OpenCom(int portnr) {
   DCB dcb;
   BOOL res;

   //Wurde auch eine korrekte Port-Nummer �bergeben???
   if(portnr<=0 || portnr>MAX_PORT) 
      return(WRONG_PORT);

   //Ermittle Port
	int index = portnr - 1;

	//Pr�fe auf falsche Port_Nr
   if(index<=-1 || index > ComPort::MAX_PORT)
		return -1; 

   //Bezeichnungen der einzelnen Ports
   CString port[4] = {_T("COM1"), _T("COM2"), _T("COM3"), _T("COM4")};

   //Versuche auf den entsprechenden Port zuzugreifen...
   //Behandlung als Datei
   hCom = CreateFile( port[index],  
                    GENERIC_READ | GENERIC_WRITE, 
                    0, 
                    0, 
                    OPEN_EXISTING,
                    FILE_FLAG_OVERLAPPED,
                    0);

   //Falls Port nicht ge�ffnet werden konnte
   if(hCom == INVALID_HANDLE_VALUE)
      return(OPEN_ERR);

   //Hole den DCB-Block zum Port (Statusinformationen)
   res = GetCommState(hCom, &dcb);
   if(!res) {
      CloseCom();
      return(STATE_ERR);
   }

   //Verbindung zum Port konnte erfolgreich hergestellt werden
   Connected = true;
   return(COMM_OK);
}
//---------------------------------------------------------------------------


//Gebe eine Liste der verf�gbaren Schnittstellen zur�ck
//Dazu wird ganz einfach versucht eine gewisse Anzahl an Ports
//zu �ffnen. 
//Es muss ein Array von C-Strings mit mindestens 4 Elementen �bergeben
//werden!
void ComPort::getPorts(CString *ports) {
	CString port[4] = {_T("COM1"), _T("COM2"), _T("COM3"), _T("COM4")};
	for(int i=0;i<4;i++) {
		// Pr�fe, ob Port ge�ffnet werden kann
		if(OpenCom(i+1) == COMM_OK) {
			ports[i].SetString(port[i]);

			//Ge�ffneter Port sollte wieder geschlossen werden
			CloseCom();
		}
	}
}
//---------------------------------------------------------------------------

//Ge�ffneter Port wird wieder geschlossen
void ComPort::CloseCom() {
   CloseHandle(hCom);
   hCom = INVALID_HANDLE_VALUE;
   Connected = false;
}

//---------------------------------------------------------------------------


//Grundeinstellungen wie Parit�t, baud-Zahl etc. vornehmen
BOOL ComPort::SetUART(DCB *dcb) {
   if(hCom != INVALID_HANDLE_VALUE)
      return(SetCommState(hCom, dcb));
   else
      return(false);
}

//---------------------------------------------------------------------------


//siehe obere Methode
BOOL ComPort::SetUART(long baud, char bytes, char parity, char stopbit) {
   if(hCom!=INVALID_HANDLE_VALUE) {
		// DCB ist eine Struktur f�r die Einstellungen der 
	    // COM-Schnittstelle(siehe MSDN)
		DCB dcb;
		dcb.BaudRate=baud;
		dcb.ByteSize=bytes;
		dcb.Parity=parity;
		dcb.StopBits=stopbit;
		return(SetCommState(hCom, &dcb));
   }
   else
      return(false);
}

//---------------------------------------------------------------------------

//Time-Out Parameter festlegen
BOOL ComPort::SetTimeouts(COMMTIMEOUTS *timeouts) {
   if(hCom!=INVALID_HANDLE_VALUE)
      return(SetCommTimeouts(hCom, timeouts));
   else
      return(false);
}

//---------------------------------------------------------------------------



//Time-Out Parameter festlegen
BOOL ComPort::SetTimeouts(long interval, int multiplier, int constant) {
	//Struktur f�r die Time-Out-Parameter(siehe MSDN)
   if(hCom!=INVALID_HANDLE_VALUE) {
      COMMTIMEOUTS timeouts;
      timeouts.ReadIntervalTimeout=interval;
      timeouts.ReadTotalTimeoutMultiplier=multiplier;
      timeouts.ReadTotalTimeoutConstant=constant;
      return(SetCommTimeouts(hCom, &timeouts));
   }
   else
      return(false);
}

//---------------------------------------------------------------------------



//DTR-Pin des COM-Ports direkt setzen

void ComPort::SetDTR(int kz) {
   if(hCom!=INVALID_HANDLE_VALUE) //Falls Zugriff auf den Port besteht
      if(kz==ON)
         EscapeCommFunction(hCom, SETDTR);  // setzen
      else
         EscapeCommFunction(hCom, CLRDTR);  // Loeschen  
}

//---------------------------------------------------------------------------



//RTS-Pin des COM-Ports direkt setzen
void ComPort::SetRTS(int kz) {
   if(hCom!=INVALID_HANDLE_VALUE) //Falls Zugriff auf den Port besteht
      if(kz==ON)
         //EscapeCommFunction(hCom, SETRTS);  // setzen
			EscapeCommFunction(hCom, CLRRTS);  // setzen
      else  
			//EscapeCommFunction(hCom, CLRRTS);  // setzen
			EscapeCommFunction(hCom, SETRTS);  
}

//---------------------------------------------------------------------------

//TXD-Pin des COM-Ports direkt setzen
void ComPort::SetTXD(int kz) {
   if(hCom!=INVALID_HANDLE_VALUE) //Falls Zugriff auf den Port besteht
      if(kz==ON)
			EscapeCommFunction(hCom, CLRBREAK);  // Loeschen
      else
			EscapeCommFunction(hCom, SETBREAK);  // setzen  
}
//---------------------------------------------------------------------------

//DTR, RTS und TXD direkt auf den gleichen Pegel setzen
void ComPort::SetAll(int kz) {
   SetAll(kz, kz, kz);
}
//---------------------------------------------------------------------------


//DTR, RTS und TXD setzen
void ComPort::SetAll(int dtr, int rts, int txd) {
   SetDTR(dtr);
   SetRTS(rts);
   SetTXD(txd);
}
//---------------------------------------------------------------------------


//Eingang CTS lesen
BOOL ComPort::GetCTS(void) {
   if(hCom!=INVALID_HANDLE_VALUE) {
      DWORD COMStatus;

      GetCommModemStatus(hCom, &COMStatus);  
	  //Falls ein LOW am Eingang liegt(das Bit f�r CTS ist nicht gesetzt)
	  //Bei der Kommunikation mit dem MOSES ist dies genau invertiert, 
	  //daher wird auf HIGH angefragt
      if(COMStatus & MS_CTS_ON)
         return OFF;
      return ON;
   }
   else
      return OFF;
}
//---------------------------------------------------------------------------

//Eingang DSR lesen
//Wird nicht f�r die Kommunikation mit dem MOSES ben�tigt, ansonsten m�ssen
//die Abfragen auch invertiert werden s.o.
BOOL ComPort::GetDSR(void) {
   if(hCom!=INVALID_HANDLE_VALUE) {
      DWORD COMStatus;

      GetCommModemStatus(hCom, &COMStatus);  
	  //Falls ein HIGH am Eingang liegt(das Bit f�r DSR ist gesetzt)
      if(COMStatus & MS_DSR_ON)
         return ON;
      return OFF;
   }
   else
      return OFF;
}
//---------------------------------------------------------------------------

//Daten �ber die Schnittstelle versenden
unsigned long ComPort::Send(const char *text) {
	
	//Breche ab, wenn Port nicht ge�ffnet
   if(hCom!=INVALID_HANDLE_VALUE) {
      unsigned long sent;

	  //Schreibe auf Port
	  WriteFile(hCom, text, strlen(text), &sent, NULL);
	  return(sent);
   }
   else
      return(0);
}
//---------------------------------------------------------------------------


//Daten �ber die Schnittstelle empfangen
unsigned long ComPort::Receive(char *text, size_t maxsize) {
	//Breche ab, wenn Port nicht ge�ffnet
   if(hCom!=INVALID_HANDLE_VALUE) {
      unsigned long received;

      ReadFile(hCom, text, maxsize, &received, NULL);
      text[received] = 0;

      return(received);
   }
   else
      return(0);
}
//---------------------------------------------------------------------------


// Da eine echte Flankensteuerung des CTS-Pins ohne weiteres nicht m�glich
// ist, muss diese Software-technisch realisiert werden. Dazu muss in 
// gewissen Zeitabst�nden (ca. 2ms) der Zustand des Pins gepr�ft werden. 
// Jedoch pr�ft diese Methode nur auf fallende Flanken. Bei einem 
// Abtastintervall von T muss eine durchschnittliche Abweichung von T/2
// beachtet werden. In gewissen F�llen kann die CPU-Auslastung nach oben
// schnellen. Die Verwendung dieser Methode sollte daher nur dann 
// stattfinden, wenn dies wirklich n�tig ist
BOOL ComPort::CTSPoll(void) {
	BOOL tmpCTS = GetCTS();
	CTSfallingEdge = CTSstat && !tmpCTS;
	CTSstat = tmpCTS;	//Neuer Zustand der Leitung CTS
	return CTSfallingEdge;
}
//---------------------------------------------------------------------------