module tdisplay;

import std.stdio;
import std.math;
import std.process;

import codepage;

struct CharInfo {
	wchar ch;
	ubyte attrib;
}

// Components are 0-255
struct TScreenColor
{
	ubyte R,G,B,Alpha;
};

struct TScreenFont256 {
	uint w,h;
	ubyte *data;
};

struct TScreenResolution {
	uint x,y;
};

// Type for the callback called when the driver needs a new font.
alias  TScreenFont256 function(int which, uint w, uint height) TVScreenFontRequestCallBack;

// Type for the callback called when the driver is detected.
// This is called when we know which driver will be used but it isn't
// initilized yet.
	alias void function() TVScreenDriverDetectCallBack;

const int TDisplayDOSModesNum = 18;

/**[txh]********************************************************************

  Description:
  SET: Here I'm writing some implementation details that could help to
understand it.@*
  This class is the low level stuff and is used by TScreen. The user isn't
supposed to call it.@*
  Example: getRows() is needed by TScreen to know the display
rows, but a class (like TDesktop) should use TScreen::getRows(), it will
return a cached data that can additionally have some translation applied to
the value returned by getRows().@*
  It should be posible to split the physical screen in 4 different screens
handled by a special TScreen class. In this case getRows will
return a different value than TScreen, lets say the double. Then calling
TScreen::clearScreen will erase the current "screen" and not the whole
physical screen.@*
  JASC have the idea of making some of the members pointers that can be
changed by the hardware layers. I implemented it but with many
differences.@*
  
***************************************************************************/

class TDisplay {
	// Members defined by original TV library v2.0
	enum VideoModes
	{
		smBW80    = 0x0002,
		smCO80    = 0x0003,
		smCO80x25 = 0x0003,
		smMono    = 0x0007,
		smFont8x8 = 0x0100,
		// Modes defined by Robert
		// Extended
		smCO80x28 = 0x0103,
		smCO80x35 = 0x0203,
		smCO80x40 = 0x0303,
		smCO80x43 = 0x0403,
		smCO80x50 = 0x0503,
		// Tweaked
		smCO80x30 = 0x0703,
		smCO80x34 = 0x0803,
		smCO90x30 = 0x0903,
		smCO90x34 = 0x0A03,
		smCO94x30 = 0x0B03,
		smCO94x34 = 0x0C03,
		smCO82x25 = 0x0D03, // Created by SET to get 8x16 char cells
		// Common VESA text modes
		smCO80x60 = 0x0108,
		smCO132x25= 0x0109,
		smCO132x43= 0x010A,
		smCO132x50= 0x010B,
		smCO132x60= 0x010C
	};

	static int setCrtModeRes(uint w, uint h, int fW=-1, int fH=-1) {
		return setCrtModeRes_p(w,h,fW,fH); 
	}

	static void bell() { 
		beep(); 
	}

	static bool  getShowCursorEver() { 
		return opts1 & Options1.ShowCursorEver ? true : false; 
	}

	static bool  getDontMoveHiddenCursor() { 
		return opts1 & Options1.DontMoveHiddenCursor ? true : false; 
	};

	static const(TScreenColor)[] getDefaultPalette() {
		return PC_BIOSPalette; 
	}

	static int getDrawingMode() { 
		return drawingMode; 
	}

	// Drawing modes:
	// codepage: cells are 8 bits, the first is the character in the current code
	//           page encoding and the next is the colors attribute.
	// unicode16: cells are 16 bits, the first is the 16 bits unicode value and
	//            the next is the colors attribute.
	enum { codepage=0, unicode16=1 };

	enum Options1
	{
		ShowCursorEver=1,  // The main goal of this option is to verify the help
		// for Braille Terminals
		DontMoveHiddenCursor=2 // This option disables the help for Braille
		// Terminals in favor of speed.
	};

	static int dual_display=0;
	
	static void        function(ushort, ushort) clearScreen = &defaultClearScreen;
	static ushort       function() getRows                =&defaultGetRows;
	static ushort       function() getCols                =&defaultGetCols;
	static void         function(ushort mode) setCrtMode  =&defaultSetCrtMode;
	static ushort       function() getCrtMode             =&defaultGetCrtMode;
	static void         function(out uint x, out uint y) getCursorPos =&defaultGetCursorShape;
	static void         function(uint  x, uint  y) setCursorPos =&defaultSetCursorShape;
	static void         function(uint start, uint end) setCursorShape =&defaultSetCursorShape;
	static void         function(out uint start, out uint end) getCursorShape =&defaultGetCursorShape;
	static void         function(string mode) setCrtModeExt = &defaultSetCrtModeExt;
	static int          function() checkForWindowSize =&defaultCheckForWindowSize;
	static string 		function() getWindowTitle     =&defaultGetWindowTitle;
	static int          function(string name) setWindowTitle =&defaultSetWindowTitle;
	static int          function() getBlinkState          =&defaultGetBlinkState;
	static void         function(int from, int number, TScreenColor[] colors) getDisPaletteColors =&defaultGetDisPaletteColors;
	static int          function(int from, int number, TScreenColor[] colors) setDisPaletteColors =&defaultSetDisPaletteColors;
	static int          function(uint w, uint h, int fW, int fH) setCrtModeRes_p =&defaultSetCrtModeRes;
	static bool      function(bool state) showBusyState =&defaultShowBusyState;
	static void         function() beep                   =&defaultBeep;
	static int           argc                      =0;
	static char        **argv                      =null;
	static char        **environment               =null;
	static TScreenColor[16]  OriginalPalette;
	static TScreenColor[16]  ActualPalette;
	static char          paletteModified           =0;
	static char          avoidMoire                =0;
	static uint        opts1                     =0;
	//static TVCodePage   codePage                  =null;
	static bool       busyState                 =false;
	static int           drawingMode               = unicode16;
	static TVScreenDriverDetectCallBack dCB        = null;
	static TScreenResolution[TDisplayDOSModesNum] dosModesRes=
	[
		{  80,25 },
		{  80,28 },
		{  80,30 },
		{  80,34 },
		{  80,35 },
		{  80,40 },
		{  80,43 },
		{  80,50 },
		{  80,60 },
		{  82,25 },
		{  90,30 },
		{  90,34 },
		{  94,30 },
		{  94,34 },
		{ 132,25 },
		{ 132,43 },
		{ 132,50 },
		{ 132,60 }
	];
	static TScreenResolution[TDisplayDOSModesNum] dosModesCell=
	[
		{ 9,16 },
		{ 9,14 },
		{ 9,16 },
		{ 9,14 },
		{ 9,10 },
		{ 9,10 },
		{ 9, 8 },
		{ 9, 8 },
		{ 9, 8 },
		{ 8,16 },
		{ 9,16 },
		{ 9,14 },
		{ 9,16 },
		{ 9,14 },
		{ 9,14 },
		{ 9,11 },
		{ 9,10 },
		{ 9, 8 }
	];
	static int[TDisplayDOSModesNum]           dosModes=
	[
		VideoModes.smCO80x25,
			VideoModes.smCO80x28,
				VideoModes.smCO80x30,
				VideoModes.smCO80x34,
				VideoModes.smCO80x35,
				VideoModes.smCO80x40,
				VideoModes.smCO80x43,
				VideoModes.smCO80x50,
				VideoModes.smCO80x60,
				VideoModes.smCO82x25,
				VideoModes.smCO90x30,
				VideoModes.smCO90x34,
				VideoModes.smCO94x30,
				VideoModes.smCO94x34,
				VideoModes.smCO132x25,
				VideoModes.smCO132x43,
				VideoModes.smCO132x50,
				VideoModes.smCO132x60
	];
	
/*****************************************************************************

 Default actions for TDisplay.
    
*****************************************************************************/
	
/**[txh]********************************************************************
  Description: Number of columns of the physical screen.
***************************************************************************/
	
	static ushort defaultGetCols() {
		return 80;
	}
	
/**[txh]********************************************************************
  Description: Number of rows of the physical screen.
***************************************************************************/
	
	static ushort defaultGetRows() {
		return 25;
	}
	
	/**[txh]********************************************************************
  Description: Erase the screen using this width and height.
***************************************************************************/
	
	static void defaultClearScreen( ushort, ushort ) {
	}
	
	/**[txh]********************************************************************
  Description: Sets the cursor shape, values in percent.
***************************************************************************/
	
	static void defaultSetCursorShape(uint /*start*/, uint /*end*/) {
	}
	
	/**[txh]********************************************************************
  Description: Gets the cursor shape, values in percent.
***************************************************************************/
	
	static void defaultGetCursorShape(out uint start, out uint end) {
		start = end = 0;
	}
	
/**[txh]********************************************************************
  Description:
  Returns information about a legacy DOS mode.
  Return: true if the mode is known.
***************************************************************************/
	
	static bool searchDOSModeInfo(ushort mode, out uint w, out uint h, out int fW, out int fH) {
		int i;
		for (i=0; i<TDisplayDOSModesNum; i++) {
			if (dosModes[i]==mode) {
				w = dosModesRes[i].x;
				h = dosModesRes[i].y;
				fW = dosModesCell[i].x;
				fH = dosModesCell[i].y;
				return true;
			}
		}
		return false;
	}
	
	/**[txh]********************************************************************
  Description: Sets the video mode.
***************************************************************************/
	
	static void defaultSetCrtMode(ushort mode) {
		uint w, h;
		int fW, fH;
		if (searchDOSModeInfo(mode,w,h,fW,fH))
			setCrtModeRes(w,h,fW,fH);
		setCursorShape(86,99);
	}
	
/**[txh]********************************************************************
  Description: Sets the video mode using a string. It could be an external
program or other information that doesn't fit in an ushort.
***************************************************************************/
	
	static void defaultSetCrtModeExt(string command) {
		setCursorShape(86,99);
		system(command);
	}

/**[txh]********************************************************************
  Description: Selects the mode that's closest to the sepcified width and
height. The optional font size can be specified.
  Return: 0 no change done, 1 change done with all the requested parameters,
2 change done but just to get closer.
***************************************************************************/
	
	static int defaultSetCrtModeRes(uint /*w*/, uint /*h*/, int /*fW*/, int /*fH*/) {
		return 0;
	}
	
	/**[txh]********************************************************************
  Description: Returns current video mode.
***************************************************************************/
	
	static ushort defaultGetCrtMode() {
		return VideoModes.smCO80;
	}
	
	/**[txh]********************************************************************
  Description: Returns !=0 if the screen size changed externally. Usually
when we are in a window, but isn't the only case.
***************************************************************************/
	
	static int defaultCheckForWindowSize() {
		return 0;
	}
	
	/**[txh]********************************************************************
  Description: Gets the visible title of the screen, usually the window
title.
***************************************************************************/
	
	static string defaultGetWindowTitle() {
		return "";
	}
	
	/**[txh]********************************************************************
  Description: Sets the visible title of the screen, usually the window
title.
  Return: !=0 success.
***************************************************************************/
	
	static int defaultSetWindowTitle(string) {
		return 0;
	}
	
	/**[txh]********************************************************************
  Description: Finds if the MSB of the attribute is for blinking.
  Return: 0 no, 1 yes, 2 no but is used for other thing.
***************************************************************************/
	
	static int defaultGetBlinkState() {
		return 2;
	}
	
	/*****************************************************************************
  Description: Shows/hides something to indicate the application is busy.
  Return: the previous state.
*****************************************************************************/
	
	static bool defaultShowBusyState(bool state) {
		bool ret=busyState;
		busyState=state;
		return ret;
	}
	
	/**[txh]********************************************************************
  Description:
  Makes an audible indication.
***************************************************************************/
	
	static void defaultBeep() {
		writeln("\\x7");
	}
	
	this() {
	}

	
	/**[txh]********************************************************************

  Description:
  Sets the cursor shape. I take the TV 2.0 convention: the low 8 bits is
the start and the high 8 bits the end. Values can be between 0 and 99. To
disable the cursor a value of 0 is used.

***************************************************************************/
	
	static void setCursorType(ushort val) {
		setCursorShape(val & 0xFF,val>>8);
		version(DEBUG_CURSOR) {
			fprintf(stderr,"Seteando 0x%0X => %X %X\n",val,val & 0xFF,val>>8);
		}
	}
	
	static ushort getCursorType() {
		uint start,end;
		getCursorShape(start,end);
		version(DEBUG_CURSOR) {
			fprintf(stderr,"Obteniendo: start %X end %X => 0x%0X\n",start,end,(start | (end<<8)));
		}
		return cast(ushort)(start | (end<<8));
	}
	
	static void setArgv(int aArgc, char **aArgv, char **aEnvir)
	{
		argc=aArgc;
		argv=aArgv;
		environment=aEnvir;
	}
	
	static bool searchClosestRes(TScreenResolution *res, uint x, uint y, uint cant, out uint pos) {
		uint minDif, indexMin, dif;
		int firstXMatch = -1;
		// Look for an exact match of width
		for (uint i=0; i<cant && res[i].x<x; i++)
		{
			if (res[i].x==x)
			{
				if (firstXMatch==-1) firstXMatch=i;
				if (res[i].y==y)
				{// Exact match
					pos = i;
					return true;
				}
			}
		}
		if (firstXMatch!=-1)
		{// Return the closest y that match x
			uint i = indexMin=firstXMatch;
			minDif = abs(res[i].y-y);
			while (++i<cant && res[i].x==x)
			{
				dif=abs(res[i].y-y);
				if (dif<minDif)
				{
					minDif=dif;
					indexMin=i;
				}
			}
			pos=indexMin;
			return false;
		}
		// No x match, looks the one with minimum differences
		indexMin=0;
		minDif=abs(res[0].y-y)+abs(res[0].x-x);
		uint i = 1;
		while (i<cant) {
			dif=abs(res[i].y-y)+abs(res[i].x-x);
			if (dif<minDif)
			{
				minDif=dif;
				indexMin=i;
			}
			i++;
		}
		pos=indexMin;
		return false;
	}
	
	/*****************************************************************************

  These should set/get the palette values at low level. The TScreen driver
must indicate if they work. The dummies help to know the PC BIOS palette.

*****************************************************************************/
	
	// Default PC BIOS palette
	static TScreenColor PC_BIOSPalette[16]=
	[
		{ 0x00, 0x00, 0x00 },
		{ 0x00, 0x00, 0xA8 },
		{ 0x00, 0xA8, 0x00 },
		{ 0x00, 0xA8, 0xA8 },
		{ 0xA8, 0x00, 0x00 },
		{ 0xA8, 0x00, 0xA8 },
		{ 0xA8, 0x54, 0x00 },
		{ 0xA8, 0xA8, 0xA8 },
		{ 0x54, 0x54, 0x54 },
		{ 0x54, 0x54, 0xFC },
		{ 0x54, 0xFC, 0x54 },
		{ 0x54, 0xFC, 0xFC },
		{ 0xFC, 0x54, 0x54 },
		{ 0xFC, 0x54, 0xFC },
		{ 0xFC, 0xFC, 0x54 },
		{ 0xFC, 0xFC, 0xFC }
	];
	
	// This is the palette parsed from the tvrc file or the application
	static TScreenColor[16] UserStartPalette;
	
	static void defaultGetDisPaletteColors(int from, int number, TScreenColor[] colors) {
		int to = from + number;
		colors[] = PC_BIOSPalette[from..to];
		//while (number-- && from < 16) {
		//	*(colors++)=PC_BIOSPalette[from++];
		//}
	}
	
	static int defaultSetDisPaletteColors(int , int number, TScreenColor[]) {
		return number;
	}
	
	static TVScreenDriverDetectCallBack setDetectCallBack(TVScreenDriverDetectCallBack aCB)
	{
		TVScreenDriverDetectCallBack ret=dCB;
		dCB=aCB;
		return ret;
	}
	
	static void SetDefaultCodePages(int idScr, int idApp, int idInp) {
		//TVCodePage.SetDefaultCodePages(idScr,idApp,idInp);
	}
	
	/*****************************************************************************

  Options routines, they are created to isolate the internal aspects.

*****************************************************************************/
	
	static bool setShowCursorEver(bool value)
	{
		bool ret=getShowCursorEver();
		if (value)
			opts1 |= Options1.ShowCursorEver;
		else
			opts1 &= ~ Options1.ShowCursorEver;
		return ret;
	}
	
	static bool setDontMoveHiddenCursor(bool value)
	{
		bool ret=getDontMoveHiddenCursor();
		if (value)
			opts1 |=  Options1.DontMoveHiddenCursor;
		else
			opts1 &= ~Options1.DontMoveHiddenCursor;
		return ret;
	}
	

}