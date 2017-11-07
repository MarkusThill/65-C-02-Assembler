#ifndef CPORT_H
#define CPORT_H "cport.h"

#include <windows.h>


//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class ComPort
{
private:
   HANDLE hCom;
   BOOL CTSstat;    	//Gibt den Zustand nach dem letzten Pollen an
   BOOL CTSfallingEdge;
public:
   static const int OFF = 0;
   static const int ON = 1;
   static const int MAX_PORT = 4;
   static const int STATE_ERR = -3; 
   static const int OPEN_ERR = -2;
   static const int WRONG_PORT = -1;
   static const int COMM_OK = 0;
   bool Connected;

   //Konstruktor / Destruktor
   ComPort(void);
   ~ComPort(void);

   HANDLE GetHCom(void);
   int OpenCom(int portnr);
   void getPorts(CString *ports);
   void CloseCom(void);

   BOOL SetUART(DCB *dcb);
   BOOL SetUART(long baud, char bytes, char parity, char stopbit);

   BOOL SetTimeouts(COMMTIMEOUTS *timeouts);
   BOOL SetTimeouts(long interval, int multiplier, int constant);

   void SetDTR(int kz);
   void SetRTS(int kz);
   void SetTXD(int kz);
   void SetAll(int kz);
   void SetAll(int dtr, int rts, int txd);

   BOOL GetCTS(void);
   BOOL GetDSR(void);

   unsigned long Send(const char *text);
   unsigned long Receive(char *text, size_t maxsize);

   BOOL CTSPoll(void);
};

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

#endif

