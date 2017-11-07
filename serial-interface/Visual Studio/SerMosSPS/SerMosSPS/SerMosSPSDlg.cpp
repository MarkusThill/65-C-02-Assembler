// SerMosSPSDlg.cpp : Implementierungsdatei

// Beispiel-Anwendung, die die Com-Klasse verwendet.


#include <windows.h>
#include "stdafx.h"
#include "SerMosSPS.h"
#include "SerMosSPSDlg.h"
#include "ThreadTimer.h"
#include "TestTimer.h"
#include "Com.h"
#include "ComThread.h"
#include "Stat.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

// CAboutDlg-Dialogfeld für Anwendungsbefehl "Info"
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

	// Dialogfelddaten
	enum { IDD = IDD_ABOUTBOX };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);  // DDX/DDV-Unterstützung

	// Implementierung
protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD) {
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX) {
	CDialog::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)

END_MESSAGE_MAP()
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------


// CSerMosSPSDlg-Dialogfeld
CSerMosSPSDlg::CSerMosSPSDlg(CWnd* pParent /*=NULL*/)
: CDialog(CSerMosSPSDlg::IDD, pParent)
//	, curTime(0)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);	
}
//---------------------------------------------------------------------------

CSerMosSPSDlg::~CSerMosSPSDlg(void) {
	// Dynamisch erzeugte Objekte löschen
	delete(testTimer);	
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::DoDataExchange(CDataExchange* pDX) {
	CDialog::DoDataExchange(pDX);
}
//---------------------------------------------------------------------------


// Festlegung der Ereignisse
BEGIN_MESSAGE_MAP(CSerMosSPSDlg, CDialog)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	//}}AFX_MSG_MAP
	ON_BN_CLICKED(IDOK, &CSerMosSPSDlg::OnBnClickedOk)
	ON_BN_CLICKED(IDC_BUTTON1, &CSerMosSPSDlg::OnBnClickedButton1)
	ON_BN_CLICKED(IDC_BUTTON2, &CSerMosSPSDlg::OnBnClickedButton2)
	ON_BN_CLICKED(IDC_BUTTON3, &CSerMosSPSDlg::OnBnClickedButton3)
	ON_BN_CLICKED(IDC_BUTTON4, &CSerMosSPSDlg::OnBnClickedButton4)
	ON_BN_CLICKED(IDC_BUTTON5, &CSerMosSPSDlg::OnBnClickedButton5)
	ON_BN_CLICKED(IDC_BUTTON6, &CSerMosSPSDlg::OnBnClickedButton6)
	ON_BN_CLICKED(IDC_BUTTON7, &CSerMosSPSDlg::OnBnClickedButton7)
	ON_BN_CLICKED(IDC_BUTTON8, &CSerMosSPSDlg::OnBnClickedButton8)
	ON_BN_CLICKED(IDC_BUTTON9, &CSerMosSPSDlg::OnBnClickedButton9)
	ON_BN_CLICKED(IDC_BUTTON10, &CSerMosSPSDlg::OnBnClickedButton10)
	ON_BN_CLICKED(IDC_BUTTON11, &CSerMosSPSDlg::OnBnClickedButton11)
	ON_BN_CLICKED(IDC_BUTTON12, &CSerMosSPSDlg::OnBnClickedButton12)
	ON_BN_CLICKED(IDC_BUTTON13, &CSerMosSPSDlg::OnBnClickedButton13)
	ON_BN_CLICKED(IDC_BUTTON14, &CSerMosSPSDlg::OnBnClickedButton14)
	ON_BN_CLICKED(IDC_BUTTON15, &CSerMosSPSDlg::OnBnClickedButton15)
	ON_BN_CLICKED(IDC_BUTTON16, &CSerMosSPSDlg::OnBnClickedButton16)	
	ON_BN_CLICKED(IDC_CHECK1, &CSerMosSPSDlg::OnBnClickedCheck1)	
	ON_BN_CLICKED(IDC_CHECK2, &CSerMosSPSDlg::OnBnClickedCheck2)
	ON_BN_CLICKED(IDC_CHECK5, &CSerMosSPSDlg::OnBnClickedCheck5)	
	ON_MESSAGE(WM_TESTTIMER_FINISHED, OnTestTimerFinished)
	ON_WM_TIMER()
	ON_BN_CLICKED(IDC_BUTTON17, &CSerMosSPSDlg::OnBnClickedButton17)
END_MESSAGE_MAP()
//---------------------------------------------------------------------------

// CSerMosSPSDlg-Meldungshandler

BOOL CSerMosSPSDlg::OnInitDialog() {
	CDialog::OnInitDialog();
	// Hinzufügen des Menübefehls "Info..." zum Systemmenü.
	// IDM_ABOUTBOX muss sich im Bereich der Systembefehle befinden.
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL) {
		CString strAboutMenu;
		strAboutMenu.LoadString(IDS_ABOUTBOX);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Symbol für dieses Dialogfeld festlegen. Wird automatisch erledigt
	//  wenn das Hauptfenster der Anwendung kein Dialogfeld ist
	SetIcon(m_hIcon, TRUE);			// Großes Symbol verwenden
	SetIcon(m_hIcon, FALSE);		// Kleines Symbol verwenden

	// TODO: Hier zusätzliche Initialisierung einfügen
	//Deaktiviere zunächst alle Radio-Buttons
	GetDlgItem(IDC_RADIO1)->EnableWindow(false);
	GetDlgItem(IDC_RADIO2)->EnableWindow(false);
	GetDlgItem(IDC_RADIO3)->EnableWindow(false);
	GetDlgItem(IDC_RADIO4)->EnableWindow(false);

	//Prüfe die vorhanden COM-Schnittstellen
	CString ports[4];
	com.getPorts(ports);
	if(ports[0] != "") 
		GetDlgItem(IDC_RADIO1)->EnableWindow(true);
	if(ports[1] != "") 
		GetDlgItem(IDC_RADIO2)->EnableWindow(true);
	if(ports[2] != "")
		GetDlgItem(IDC_RADIO3)->EnableWindow(true);
	if(ports[3] != "")
		GetDlgItem(IDC_RADIO4)->EnableWindow(true);

	//Variablen-Initialisierungen
	sendOnNextTimer = false;
	//sendTestQueue = false;
	testTimer = NULL;

	//Ein Byte hat max. 3 Ziffern (Dez.)
	((CEdit*)GetDlgItem(IDC_EDIT4))->LimitText(3);

	//Starte Timer mit 1s
	SetTimer(ID_Clock_Timer, 3000, NULL);

	//Zunächst sind unendlich viele Sendeversuche erlaubt
	((CButton*)GetDlgItem(IDC_CHECK5))->SetCheck(true);

	// Geben Sie TRUE zurück, außer ein Steuerelement soll den Fokus erhalten
	return TRUE;  
}
//---------------------------------------------------------------------------



void CSerMosSPSDlg::OnSysCommand(UINT nID, LPARAM lParam) {

	if ((nID & 0xFFF0) == IDM_ABOUTBOX) {
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else {
		CDialog::OnSysCommand(nID, lParam);
	}
}

//---------------------------------------------------------------------------

// Wenn Sie dem Dialogfeld eine Schaltfläche "Minimieren" hinzufügen, benötigen Sie 
//  den nachstehenden Code, um das Symbol zu zeichnen. Für MFC-Anwendungen, die das 
//  Dokument/Ansicht-Modell verwenden, wird dies automatisch ausgeführt.

void CSerMosSPSDlg::OnPaint() {
	if (IsIconic()) {
		CPaintDC dc(this); // Gerätekontext zum Zeichnen

		SendMessage(WM_ICONERASEBKGND, 
			reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// Symbol in Clientrechteck zentrieren
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Symbol zeichnen
		dc.DrawIcon(x, y, m_hIcon);
	}
	else {
		CDialog::OnPaint();
	}
}
//---------------------------------------------------------------------------

// Die System ruft diese Funktion auf, um den Cursor abzufragen, 
//der angezeigt wird, während der Benutzer
//  das minimierte Fenster mit der Maus zieht.
HCURSOR CSerMosSPSDlg::OnQueryDragIcon() {
	return static_cast<HCURSOR>(m_hIcon);
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnTimer(UINT nIDEvent)  {
	Stat stat = com.getStat();
	//CString strTmp;
	char pszNum[100] = {0};
	short response = 0;

	//	int test;
	switch(nIDEvent) {
		//Timer-Test
		case ID_Clock_Timer:	
			//Timer zunächst stoppen
			KillTimer(ID_Clock_Timer);

			//Senden aktiv?
			((CButton*)GetDlgItem(IDC_CHECK3))->SetCheck(stat.isSndActive);

			//Empfang aktiv?
			((CButton*)GetDlgItem(IDC_CHECK4))->SetCheck(stat.isRecvActive);

			//Anzahl der übertragenen Bytes
			_itoa_s(stat.numSndBytes, pszNum, 100, 10);
			GetDlgItem(IDC_EDIT5)->SetWindowTextW(CString(pszNum));

			//Anzahl der empfangen Bytes
			_itoa_s(stat.numRecvBytes, pszNum, 100, 10);
			GetDlgItem(IDC_EDIT6)->SetWindowTextW(CString(pszNum));

			//Anzahl der Sendefehler
			_itoa_s(stat.numSndErrs, pszNum, 100, 10);
			GetDlgItem(IDC_EDIT7)->SetWindowTextW(CString(pszNum));

			//Anzahl der Empfangsfehler
			_itoa_s(stat.numRecvErrs, pszNum, 100, 10);
			GetDlgItem(IDC_EDIT8)->SetWindowTextW(CString(pszNum));

			//Letzter Fehler
			_itoa_s(stat.lastErrStat, pszNum, 100, 10);
			GetDlgItem(IDC_EDIT13)->SetWindowTextW(CString(pszNum));
			GetDlgItem(IDC_EDIT10)->SetWindowTextW(stat.lastErrStatStr);

			//Zuletzt gesendetes Byte
			_itoa_s(stat.lastSndByte, pszNum, 100, 16);
			GetDlgItem(IDC_EDIT11)->SetWindowTextW(_T("0x") + CString(pszNum));

			//Zuletzt empfangenes Byte
			_itoa_s(stat.lastRecvByte, pszNum, 100, 16);
			GetDlgItem(IDC_EDIT12)->SetWindowTextW(_T("0x") + CString(pszNum));
			//Anzahl der Elemente in der Sende-FIFO
			_itoa_s(stat.sizeSndFifo, pszNum, 100, 10);
			GetDlgItem(IDC_EDIT15)->SetWindowTextW(CString(pszNum));

			//Anzahl der Elemente in der Empfangs-FIFO
			_itoa_s(stat.sizeRecvFifo, pszNum, 100, 10);
			GetDlgItem(IDC_EDIT14)->SetWindowTextW(CString(pszNum));

			//Aufbau: 0|0|T0|...|T13 
			response = stat.response;
			((CButton*)GetDlgItem(IDC_CHECK38))->SetCheck(response & 1);
			((CButton*)GetDlgItem(IDC_CHECK35))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK34))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK33))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK32))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK31))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK30))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK29))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK28))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK27))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK26))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK25))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK24))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK23))->SetCheck((response >>= 1) & 1);
			((CButton*)GetDlgItem(IDC_CHECK22))->SetCheck((response >>= 1) & 1);

			//Starte Timer neu
			SetTimer(ID_Clock_Timer, 100, NULL);
			break;
		default:
			break;
	}
}

//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedOk() {
	OnOK();
}

//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton1() {
	if(!testTimer) {

		// Timer-Test wird in einem Thread gestartet
		testTimer = (TestTimer*) AfxBeginThread(RUNTIME_CLASS(TestTimer),
			THREAD_PRIORITY_NORMAL,
			NULL,
			CREATE_SUSPENDED, 
			NULL);
		testTimer->ResumeThread();
	}
	testTimer->startTimerTest(TestTimer::STDTIMERTEST, 
		AfxGetMainWnd()->m_hWnd, 200, Com::TIMEINTERVALL);
}

//---------------------------------------------------------------------------



void CSerMosSPSDlg::OnBnClickedButton3() {

	if(!testTimer) {
		// Timer-Test wird in einem Thread gestartet
		testTimer = (TestTimer*) AfxBeginThread(RUNTIME_CLASS(TestTimer),
			THREAD_PRIORITY_NORMAL,
			NULL,
			CREATE_SUSPENDED, 
			NULL);
		testTimer->ResumeThread();
	}
	testTimer->startTimerTest(TestTimer::THREADTIMERTEST,
		AfxGetMainWnd()->m_hWnd, 200, Com::TIMEINTERVALL);

	//testTimer->PostThreadMessage(WM_THREAD_TERMINATED, 
	//	WM_THREAD_TERMINATED, NULL);
}
//---------------------------------------------------------------------------

LRESULT CSerMosSPSDlg::OnTestTimerFinished(WPARAM wParam, LPARAM lParam) {
	CString strTmp;
	strTmp.Format(L"%f", testTimer->getAvgDiff());
	if(((int)lParam) == TestTimer::THREADTIMERTEST)
		GetDlgItem(IDC_EDIT2)->SetWindowTextW(strTmp + _T(" ms"));
	else
		GetDlgItem(IDC_EDIT1)->SetWindowTextW(strTmp + _T(" ms"));
	return 0;
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton2() {
	int x = GetCheckedRadioButton(IDC_RADIO1, IDC_RADIO4);
	switch(x) {
		case IDC_RADIO1:
			if(!com.openPort(1))
				MessageBox(_T("Konnte Port 1 nicht öffnen!"), 
					_T("Error"), MB_OK);
			else
				comConnected();
			break;
		case IDC_RADIO2:
			if(!com.openPort(2))
				MessageBox(_T("Konnte Port 2 nicht öffnen!"), 
					_T("Error"), MB_OK);
			else
				comConnected();
			break;
		case IDC_RADIO3:
			if(!com.openPort(3))
				MessageBox(_T("Konnte Port 3 nicht öffnen!"), 
					_T("Error"), MB_OK);
			else
				comConnected();
			break;
		case IDC_RADIO4:
			if(!com.openPort(4))
				MessageBox(_T("Konnte Port 4 nicht öffnen!"),
					_T("Error"), MB_OK);
			else
				comConnected();
			break;
	}
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::comConnected(void) {
	GetDlgItem(IDC_EDIT3)->SetWindowTextW(
		_T("Verbindung wurde\r\nhergestellt!"));
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton4() {
	com.closePort();
	GetDlgItem(IDC_EDIT3)->SetWindowTextW(
		_T("Verbindung\r\nwurde getrennt!"));
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedCheck1() {
	bool receiveEnabled = ((CButton*)GetDlgItem(IDC_CHECK1))->GetCheck() == 1;
	if(receiveEnabled)
		com.enableRecv();
	else
		com.disableRecv();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedCheck2() {
	bool sendEnabled = ((CButton*)GetDlgItem(IDC_CHECK2))->GetCheck() == 1;
	if(sendEnabled)
		com.enableSnd();
	else
		com.disableSnd();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedCheck5() {
	bool set = ((CButton*)GetDlgItem(IDC_CHECK5))->GetCheck() == 1;
	if(set) {
		GetDlgItem(IDC_EDIT9)->EnableWindow(false);
		GetDlgItem(IDC_BUTTON16)->EnableWindow(false);
		com.getStat().setMaxSndRetrys(-1);
	}
	else {
		GetDlgItem(IDC_EDIT9)->EnableWindow(true);
		GetDlgItem(IDC_BUTTON16)->EnableWindow(true);

		wchar_t buf[10];
		CEdit* edit = ((CEdit*)GetDlgItem(IDC_EDIT9));	
		edit->GetWindowText(buf, 7);
		int x = _wtoi(buf);
		com.getStat().setMaxSndRetrys(x);
	}
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton5() {
	if(!com.send((BYTE)0x55))
		MessageBox(_T("Sende-FIFO ist voll!!!"), MB_OK);
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton6() {
	int val;
	if((val = com.receive()) != -1) {
		CString strTmp;
		strTmp.Format(L"%x", val);
		MessageBox(_T("Byte (Hex): 0x") + strTmp, 
			_T("Lesen aus Empfangs-Puffer"), MB_OK);
	}		
	else
		MessageBox(_T("FIFO ist leer!!"), _T("Error"), MB_OK);
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton7() {
	int val;
	CComboBox * combo = ((CComboBox *)GetDlgItem(IDC_COMBO1));
	combo->ResetContent();
	bool isFirst = true;
	while((val = com.receive()) != -1) {
		CString strTmp;
		strTmp.Format(L"0x%x", val);
		combo->AddString(strTmp);
		if(isFirst)
			combo->SelectString(0, strTmp);
		isFirst = false;
	}
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton8() {
	for(int i=0;i<MAXQUEUENUM;i++) {
		com.send((BYTE)i);
	}
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton10() {
	//CString str;
	wchar_t buf[10];
	CEdit* button = ((CEdit*)GetDlgItem(IDC_EDIT4));	
	button->GetWindowText(buf, 5);
	int x = _wtoi(buf);
	if(x < 0 || x > 255)
		MessageBox(_T("Zahl nicht im gültigen Bereich!!!"), MB_OK);
	else
		com.send((BYTE)x);
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton11() {
	com.emptyRecvFifo();
	OnBnClickedButton7();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton9() {
	com.emptySndFifo();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton12() {
	com.getStat().resetNumSndBytes();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton13() {
	com.getStat().resetNumRecvBytes();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton14() {
	com.getStat().resetNumSndErrs();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton15() {
	com.getStat().resetNumRecvErrs();
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton16() {
	wchar_t buf[10];
	CEdit* edit = ((CEdit*)GetDlgItem(IDC_EDIT9));	
	edit->GetWindowText(buf, 7);
	int x = _wtoi(buf);
	com.getStat().setMaxSndRetrys(x);
}
//---------------------------------------------------------------------------

void CSerMosSPSDlg::OnBnClickedButton17() {
	//Senden der vorgegebenen Testfolge
	unsigned short testFrame = 0;
	unsigned short bit = 0;
	//Frage die einzelnen Check-Boxen ab
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK6))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK7))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK8))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK9))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK10))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK11))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK12))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK13))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK14))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK15))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK16))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK17))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK18))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK19))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK20))->GetCheck() << bit++;
	testFrame |= ((CButton*)GetDlgItem(IDC_CHECK21))->GetCheck() << bit++;
	
	//Format von testFrame:
	//IDLE|SwapBit|...|D7|...|D0|StartBit|IDLE
	//WICHTIG: Abfragen wie in startSendByte einfügen (zumindest einige)
	if(!com.test(testFrame))
		MessageBox(_T("Konnte Test nicht starten, da noch aktiv!"), MB_OK);
	return;
}