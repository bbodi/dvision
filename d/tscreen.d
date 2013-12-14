module tscreen;

import std.string;
import std.algorithm;
import std.process;
import std.stdio;
import std.c.stdlib;
import std.array;

import tdisplay;
import tgkey;
import ttypes;
import configfile;

class TScreen : TDisplay {

	/***
	extern TScreen *TV_DOSDriverCheck();
	extern TScreen *TV_LinuxDriverCheck();
	extern TScreen *TV_QNXRtPDriverCheck();
	extern TScreen *TV_QNX4DriverCheck();
	extern TScreen *TV_UNIXDriverCheck();
	extern TScreen *TV_WinGrDriverCheck();
	extern TScreen *TV_Win32DriverCheck();
	extern TScreen *TV_WinNTDriverCheck();
	extern TScreen *TV_XDriverCheck();
	extern TScreen *TV_XTermDriverCheck();
	extern TScreen *TV_AlconDriverCheck();
	***/

	// SET: flags capabilities flags
	enum Capabilities1
	{
		CodePageVar=1,
		CanSetPalette=2,    // We can change colors
		CanReadPalette=4,   // We have reliable information about the original colors.
		// If this value isn't present the user can set the palette,
		// but the original colors want be restored at exit. We will
		// try to let them as default for the used display.
		PalNeedsRedraw=8,   // Indicates we must redraw after changing the palette.
		CursorShapes=16,    // When the cursor shape is usable.
		UseScreenSaver=32,  // Does screen saver have any sense for this driver?
		CanSetBFont=64,     // We can set the primary bitmap font
		CanSetSBFont=128,   // We can set the secondary bitmap font
		CanSetFontSize=256, // We can set the width and height of the font
		CanSetVideoSize=512,// We can set the video size (window size or video mode)
		NoUserScreen=0x400  // No user screen exists i.e. we are in a window we draw
	};

	static bool codePageVariable() { return flags0 & Capabilities1.CodePageVar     ? true : false; };
	static bool canSetPalette()    { return flags0 & Capabilities1.CanSetPalette   ? true : false; };
	static bool canReadPalette()   { return flags0 & Capabilities1.CanReadPalette  ? true : false; };
	static bool palNeedsRedraw()   { return flags0 & Capabilities1.PalNeedsRedraw  ? true : false; };
	static bool cursorShapes()     { return flags0 & Capabilities1.CursorShapes    ? true : false; };
	static bool useScreenSaver()   { return flags0 & Capabilities1.UseScreenSaver  ? true : false; };
	static bool canSetBFont()      { return flags0 & Capabilities1.CanSetBFont     ? true : false; };
	static bool canSetSBFont()     { return flags0 & Capabilities1.CanSetSBFont    ? true : false; };
	static bool canSetFontSize()   { return flags0 & Capabilities1.CanSetFontSize  ? true : false; };
	static bool canSetVideoSize()  { return flags0 & Capabilities1.CanSetVideoSize ? true : false; };
	static bool noUserScreen()     { return flags0 & Capabilities1.NoUserScreen    ? true : false; };
	
/*****************************************************************************
  Data members initialization
*****************************************************************************/
	
	static ushort   startupMode=0;
	static ushort   screenMode=0;
	static ushort   startupCursor=0;
	static ushort   cursorLines=0;
	static ushort    screenWidth=80;
	static ushort    screenHeight=25;
	static bool  hiResScreen=false;
	static bool  checkSnow=false;
	static CharInfo[]  screenBuffer=null;
	static char     suspended=1;
	static char     initialized=0;
	static char     initCalled=0;
	static char     useSecondaryFont=0;
	static uint   flags0=0;
	static stDriver driver;
	static TScreen screen = null;
	static string currentDriverShortName = null;
	static TVScreenFontRequestCallBack frCB=null;
	static long     forcedAppCP=-1;
	static long forcedScrCP=-1;
	static long forcedInpCP=-1;
	static int      maxAppHelperHandlers = 8;
	static string windowClass="XTVApp";
	
	/*****************************************************************************
  Function pointer members initialization
*****************************************************************************/

	enum AppHelper { FreeHandler, ImageViewer, PDFViewer };
	alias ccIndex appHelperHandler;

	static void dummy() {}

	static void    function(ushort mode) setVideoMode    =&defaultSetVideoMode;
	static void    function(string mode) setVideoModeExt  =&defaultSetVideoModeExt;
	static void    function() clearScreen                =&defaultClearScreen;
	static void    function() setCrtData                 =&defaultSetCrtData;
	static ushort  function(ushort mode) fixCrtMode      =&defaultFixCrtMode;
	static void    function() Suspend                    =&dummy;
	static void    function() Resume                     =&dummy;
	static ushort  function(uint offset) getCharacter=&defaultGetCharacter;
	static void    function(uint offset, CharInfo[] buf, uint count) getCharacters =&defaultGetCharacters;
	static void    function(uint offset, wchar ch, int attrib) setCharacter =&defaultSetCharacter;
	static void    function(uint offset, const(CharInfo)[] values) setCharacters =&defaultSetCharacters;
	static int     function(string command, pid_t *pidChild, int, int, int err) System_p =&defaultSystem;
	static int     function(out uint w, out uint h) getFontGeometry =&defaultGetFontGeometry;
	static int     function(out uint wmin, out uint hmin, out uint umax, out uint hmax) getFontGeometryRange = &defaultGetFontGeometryRange;
	static int     function(int changeP, TScreenFont256 *fontP, int changeS, TScreenFont256 *fontS, int fontCP, int appCP) setFont_p = &defaultSetFont;
	static void    function() restoreFonts               =&defaultRestoreFonts;
	static int     function(uint w, uint h, int fW, int fH) setVideoModeRes_p = &defaultSetVideoModeRes;
	static appHelperHandler  function(AppHelper kind) openHelperApp = &defaultOpenHelperApp;
	static bool  function(appHelperHandler id) closeHelperApp = &defaultCloseHelperApp;
	static bool  function(appHelperHandler id, string file, void *extra) sendFileToHelper = &defaultSendFileToHelper;
	static string function() getHelperAppError     =&defaultGetHelperAppError;
	
	
/*****************************************************************************
  Default behaviors for the members
*****************************************************************************/
	
	static void defaultSetVideoMode(ushort mode) {// Set the screen mode
		setCrtMode(fixCrtMode(mode));
		// Cache the data about it and initialize related stuff
		setCrtData();
	}
	
	static void defaultSetVideoModeExt(string mode) {// Set the screen mode
		setCrtModeExt(mode);
		// Cache the data about it and initialize related stuff
		setCrtData();
	}
	
	static int  defaultSetVideoModeRes(uint w, uint h, int fW, int fH) {// Set the screen mode
		int ret=setCrtModeRes(w,h,fW,fH);
		if (ret)
			// Cache the data about it and initialize related stuff
			setCrtData();
		return ret;
	}
	
	static void defaultClearScreen() {
		TDisplay.clearScreen(screenWidth, screenHeight);
	}
	
	static void defaultSetCrtData()
	{
		screenMode  	= getCrtMode();
		screenWidth 	= getCols();
		screenHeight	= getRows();
		hiResScreen 	= screenHeight > 25;
		cursorLines 	= getCursorType();
		setCursorType(0);
	}
	
	static ushort defaultFixCrtMode(ushort mode) {
		return mode;
	}
	
	static ushort defaultGetCharacter(uint offset) {
		return screenBuffer[offset].ch;
	}
	
	static void defaultGetCharacters(uint offset, CharInfo[] buf, uint count) {
		int fromIndex = offset;
		int length = count;
		int toIndex = fromIndex + length;
		buf[] = screenBuffer[fromIndex..toIndex];
	}
	
	static void defaultSetCharacter(uint offset, wchar ch, int attrib) {
		setCharacters(offset, [CharInfo(ch, cast(ubyte)attrib)]);
	}
	
	static void defaultSetCharacters(uint offset, const(CharInfo)[] values) {
		int fromIndex = offset;
		int length = values.length;
		int toIndex = fromIndex + length;
		screenBuffer[fromIndex..toIndex] = values[];
	}
	
	static int defaultSystem(string command, pid_t *pidChild, int in_, int out_, int err) {
		import std.exception;
		enforce(false, "Not implemented!");
		/*
		// fork mechanism not available
		if (pidChild)
			*pidChild = 0;
		// If the caller asks for redirection replace the requested handles
		if (in_ != -1) {

			dup2(in_, STDIN_FILENO);
		}
		if (out_!=-1)
			dup2(out_, STDOUT_FILENO);
		if (err!=-1)
			dup2(err, STDERR_FILENO);
		return system(command);
		*/
		return 0;
	}
	
	static int  defaultGetFontGeometry(out uint, out uint) { return 0; }
	static int  defaultGetFontGeometryRange(out uint, out uint ,
	                                          out uint , out uint) { return 0; }
	static int  defaultSetFont(int , TScreenFont256 *, int , TScreenFont256 *,
	                             int, int) { return 0; }
	static void defaultRestoreFonts() {}
	
	static appHelperHandler defaultOpenHelperApp(AppHelper) {
		return -1; 
	}

	static bool defaultCloseHelperApp(appHelperHandler) { return false; }
	static bool defaultSendFileToHelper(appHelperHandler, string, void *)
	{ return false; }
	static string defaultGetHelperAppError()
	{
		return "This feature isn't implemented by the current driver.";
	}
	
/*****************************************************************************
  Real members
*****************************************************************************/
	
	struct stDriver {
		// Test function for this driver
		TScreen function() initFunc;
		void function() deInitFunc;
		// The drivers with more priority are tried first
		int         priority;
		// Configuration section name for this driver
		string name;
	};

	static stDriver[] Drivers;
	//static const int nDrivers;

	static void registerDriver(stDriver driver) {
		Drivers ~= driver;
	}

	static bool cmpDrivers(in ref stDriver v1, in ref stDriver v2) { 
		int p1=v1.priority;
		int p2=v2.priority;
		return (p1<p2)-(p1>p2) == 0;
	}
	
	/**[txh]********************************************************************

  Description:
  This constructor is called when the TApplication object is created. The
TProgramInit constructor creates a dynamic copy instance of a TScreen
object.@*
  Actually it calls the detection routines to determine the best driver
available. If non is found prints and error to the stderr output and aborts
the execution.
  
***************************************************************************/

	this() {
		// When the real drivers creates a derived class they will call this
		// constructor so we must avoid getting in an infinite loop.
		// I know that's tricky but it helps to maintain compatibility with the
		// old class structure.
		if (initCalled)
			return;
		initCalled = 1;
		
		// Check if the user changed priorities
		int changed=0;
		long priority;
		for (int i=0; i < Drivers.length; i++) {
//			if (TVMainConfigFile.Search(Drivers[i].name, "Priority", priority)) {
//				Drivers[i].priority=cast(int)priority;
//				changed++;
//			}
		}
		// Sort the list if needed
		if (changed) {
			Drivers.sort!cmpDrivers();
			//qsort(Drivers,nDrivers,sizeof(stDriver),cmpDrivers);
		}
		// Now call the initializations
		for (int i=0; i < Drivers.length; i++) {
			currentDriverShortName = Drivers[i].name;
			screen = Drivers[i].initFunc();
			if (screen !is null) {
				driver = Drivers[i];
				break;
			}
		}
		if (screen is null) {
			currentDriverShortName = null;
			exit(1);
		}
		long val = 0;
		if (optSearch("AvoidMoire", val)) {
			avoidMoire = cast(char)val;
		}
		val=0;
		if (optSearch("AltKeysSetting", val)) {
			TGKey.SetAltSettings(val);
		}
	}

	static void deInit() {
		if (initCalled && screen) {
			initCalled = 0; // Avoid actions in farther calls
			//delete driver;
			driver.deInitFunc();
		} else {
			//  When we destroy the "driver" member it will call the specific destructor
			// and it will call this destructor again (is a child class). This time we
			// will have initCalled=0 and this suspend will be executed.
			//  The specific destructor should set suspended=1 if this suspend should be
			// disabled.
			suspend();
		}
	}
	
	static void suspend() {
		if (suspended) return;
		suspended = 1;
		Suspend();
	}
	
	static void resume() {
		if (!suspended) return;
		suspended = 0;
		Resume();
	}
	
	static void getPaletteColors(int from, int number, TScreenColor *colors) {
		while (number-- && from<16) {
			*(colors++)=ActualPalette[from++];
		}
	}
	
	static void setPaletteColors(int from, int number, TScreenColor[] colors) {
		int num = setDisPaletteColors(from, number, colors);
		if (num) {
			//memcpy(ActualPalette + from, colors, num*sizeof(TScreenColor));
			int to = from + num;
			ActualPalette[from..to] = colors[];
			paletteModified=1;
		}
	}
	
	static void resetPalette()
	{
		setDisPaletteColors(0,16,OriginalPalette);
		paletteModified=0;
	}
	
	private static string separatorChars=",;";
	
	static bool parseUserPalette() {
		string sPal = optSearch("ScreenPalette");
		//printf("parseUserPalette():  %s\n",sPal ? sPal : "None");
		if (sPal is null || sPal.length == 0) {
			return false;
		}
		//memcpy(UserStartPalette, PC_BIOSPalette,sizeof(UserStartPalette));
		UserStartPalette[] = PC_BIOSPalette[];

		string[] tokens = array(map!("a.strip()")(sPal.split(separatorChars)));
		// [MUST-TEST]
		/*char *s=strtok(b,sep),*end;
		int index=0, R, G, B;
		bool ret=false;
		while (s) {
			for (;*s && isspace(*s); s++);
			R=*s ? strtol(s,&end,0) : UserStartPalette[index].R;
			
			s=strtok(null,sep);
			if (!s) break;
			for (;*s && isspace(*s); s++);
			G=*s ? strtol(s,&end,0) : UserStartPalette[indexnull
			
			s=strtok(null,sep);
			if (!s) break;
			for (;*s && isspace(*s); s++);
			B=*s ? strtol(s,&end,0) : UserStartPalette[indexnull
			
			UserStartPalette[index].R=R;
			UserStartPalette[index].G=G;
			UserStartPalette[index].B=B;
			//printf("%d: %d,%d,%d\n",index,R,G,B);
			index++;
			ret=true;
			
			s = strtok(null,sep);
		}
		return ret;*/
		return true;
	}
	
	static bool optSearch(string variable, out long val) {
		val = -1; // átmenetileg
		return false;
		/*
		if (TVMainConfigFile.Search(currentDriverShortName, variable, val))
			return true;
		// If not found in the driver specific section search in the TV section
		return TVMainConfigFile.Search(variable, val);*/
	}
	

	static string optSearch(string variable) {
		string val = null;//TVMainConfigFile.Search(currentDriverShortName, variable);
		if (val !is null)
			return val;
		// If not found in the driver specific section search in the TV section
		//return TVMainConfigFile.Search(variable);
		return null;
	}
	
	static TVScreenFontRequestCallBack setFontRequestCallBack(TVScreenFontRequestCallBack cb) {
		TVScreenFontRequestCallBack old = frCB;
		frCB=cb;
		return old;
	}
}