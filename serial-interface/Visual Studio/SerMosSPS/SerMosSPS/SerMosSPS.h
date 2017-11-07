// SerMosSPS.h : Hauptheaderdatei für die SerMosSPS-Anwendung

// Von Visual-C++ generiert



#pragma once



#ifndef __AFXWIN_H__

	#error "\"stdafx.h\" vor dieser Datei für PCH einschließen"

#endif



#include "resource.h"		// Hauptsymbole





// CSerMosSPSApp:

// Siehe SerMosSPS.cpp für die Implementierung dieser Klasse

//



class CSerMosSPSApp : public CWinApp

{

public:

	CSerMosSPSApp();



// Überschreibungen

	public:

	virtual BOOL InitInstance();



// Implementierung



	DECLARE_MESSAGE_MAP()

};

//---------------------------------------------------------------------------



extern CSerMosSPSApp theApp;