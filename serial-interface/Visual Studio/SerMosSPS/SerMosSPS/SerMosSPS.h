// SerMosSPS.h : Hauptheaderdatei f�r die SerMosSPS-Anwendung

// Von Visual-C++ generiert



#pragma once



#ifndef __AFXWIN_H__

	#error "\"stdafx.h\" vor dieser Datei f�r PCH einschlie�en"

#endif



#include "resource.h"		// Hauptsymbole





// CSerMosSPSApp:

// Siehe SerMosSPS.cpp f�r die Implementierung dieser Klasse

//



class CSerMosSPSApp : public CWinApp

{

public:

	CSerMosSPSApp();



// �berschreibungen

	public:

	virtual BOOL InitInstance();



// Implementierung



	DECLARE_MESSAGE_MAP()

};

//---------------------------------------------------------------------------



extern CSerMosSPSApp theApp;