#pragma once

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
class ThreadTimer : public CWinThread
{
private:
	//HWND parentHWND;
	CWinThread* parent;
	float waitTime;
public:
    ThreadTimer();
    virtual ~ThreadTimer();
    virtual BOOL InitInstance() ;
    virtual int Run() ;
	//void SethWnd(HWND hWnd);
	void setWaitTime(float time);
	void setParent(CWinThread* parent);
    CString sName ;
} ;
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

