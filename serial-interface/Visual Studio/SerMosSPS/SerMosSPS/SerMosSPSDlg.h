// SerMosSPSDlg.h : Headerdatei
//

#include "TestTimer.h"
#include "Com.h"
#include "ComThread.h"

#pragma once

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// CSerMosSPSDlg-Dialogfeld
class CSerMosSPSDlg : public CDialog
{
// Konstruktion
public:
	CSerMosSPSDlg(CWnd* pParent = NULL);	// Standardkonstruktor
	CSerMosSPSDlg::~CSerMosSPSDlg(void); //Destruktor

// Dialogfelddaten
	enum { IDD = IDD_SERMOSSPS_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV-Unterstützung

// Implementierung
protected:
	HICON m_hIcon;

	// Generierte Funktionen für die Meldungstabellen
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	afx_msg void OnTimer(UINT nIDEvent);
	DECLARE_MESSAGE_MAP()
private:
	TestTimer* testTimer;
	Com com;

	bool sendOnNextTimer;
	int nextQueueByte;

	//Konstanten
	static const int MAXQUEUENUM = 100;
public:
	afx_msg void OnBnClickedOk();
	afx_msg void OnBnClickedButton1();
	afx_msg void OnBnClickedButton3();
	afx_msg void OnBnClickedButton2();
	afx_msg void OnBnClickedButton4();
	afx_msg void OnBnClickedButton5();
	afx_msg void OnBnClickedButton6();
	afx_msg void OnBnClickedButton7();
	afx_msg void OnBnClickedButton8();
	afx_msg void OnBnClickedButton9();
	afx_msg void OnBnClickedButton10();
	afx_msg void OnBnClickedButton11();
	afx_msg void OnBnClickedButton12();
	afx_msg void OnBnClickedButton13();
	afx_msg void OnBnClickedButton14();
	afx_msg void OnBnClickedButton15();
	afx_msg void OnBnClickedButton16();
	afx_msg void OnBnClickedCheck1();
	afx_msg void OnBnClickedCheck2();
	afx_msg void OnBnClickedCheck5();
	afx_msg LRESULT OnTestTimerFinished(WPARAM, LPARAM);
	void comConnected(void);
	afx_msg void OnBnClickedButton17();
};

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

