module win32.win32scr;

import std.string;
import core.sys.windows.windows;
import std.process;

import tscreen;
import tdisplay;
import codepage;
import tvconfig;
import ttypes;
import win32.win32key;
import win32.win32clip;
import win32.win32mouse;


TScreen TV_Win32DriverCheck() {
	TScreenWin32 drv = new TScreenWin32();
	if (!TScreen.initialized) {
		return null;
	}
	return drv;
}

alias void* winHandle;
extern (Windows) winHandle CreateThread(int, int, int, int, int, int);
	

__gshared HANDLE hOut, hIn;
__gshared int ExitEventThread;

// Lock for the WindowSizeChanged variable
private __gshared CRITICAL_SECTION lockWindowSizeChanged;
// Used to indicate a window size change
private __gshared int WindowSizeChanged;

class TScreenWin32 : TScreen {

	static CONSOLE_SCREEN_BUFFER_INFO info;
	
	static HANDLE                     EventThreadHandle;
	static DWORD                      oldConsoleMode, newConsoleMode;
	static uint                   xCurStart, yCurStart;
	static uint                   saveScreenWidth, saveScreenHeight;

	private const int mxTitleSize=256;
	// Variables for this driver
	// Input/output handles
	private static HANDLE hStdOut;
	// Console information
	private static CONSOLE_SCREEN_BUFFER_INFO ConsoleInfo;
	// Cursor information
	private static CONSOLE_CURSOR_INFO ConsoleCursorInfo;
	
	static void SetCursorPos(uint x, uint y)
	{
		COORD pos;
		pos.X = cast(ushort)x;
		pos.Y = cast(ushort)y;
		SetConsoleCursorPosition(hOut,pos);
	}
	
	static void GetCursorPos(out uint x, out uint y)
	{
		GetConsoleScreenBufferInfo(hOut, &ConsoleInfo);
		x=ConsoleInfo.dwCursorPosition.X;
		y=ConsoleInfo.dwCursorPosition.Y;
	}
	
	// by SET
	static void GetCursorShape(out uint start, out uint end)
	{
		GetConsoleCursorInfo(hOut,&ConsoleCursorInfo);
		if (ConsoleCursorInfo.bVisible)
		{// Visible
			// Win32API returns a "percent filled" value.
			start=100-ConsoleCursorInfo.dwSize;
			// Ever upto the end
			end  =100;
			return;
		}
		// Invisible cursor
		start=end=0;
	}
	
	// by SET
	static void SetCursorShape(uint start, uint end)
	{
		if (start>=end && TScreen.getShowCursorEver())
			return;
		
		GetConsoleCursorInfo(hOut,&ConsoleCursorInfo);
		if (start>=end)
			ConsoleCursorInfo.bVisible=FALSE;
		else
		{
			ConsoleCursorInfo.bVisible=true;
			ConsoleCursorInfo.dwSize=end-start;
			if (ConsoleCursorInfo.dwSize>=100)
				ConsoleCursorInfo.dwSize=99;
		}
		SetConsoleCursorInfo(hOut,&ConsoleCursorInfo);
	}
	
	static ushort GetRows()
	{
		return ConsoleInfo.dwSize.Y;
	}
	
	static ushort GetCols()
	{
		return ConsoleInfo.dwSize.X;
	}
	
	static int CheckForWindowSize()
	{
		int SizeChanged=WindowSizeChanged;
		EnterCriticalSection(&lockWindowSizeChanged);
		WindowSizeChanged=0;
		LeaveCriticalSection(&lockWindowSizeChanged);
		if (SizeChanged)
			GetConsoleScreenBufferInfo(hOut,&ConsoleInfo);
		
		return SizeChanged;
	}
	
	static void SetCrtMode(ushort)
	{
		SetCursorShape(0x58,0x64);
	}
	
	static void SetCrtModeExt(string)
	{
		SetCursorShape(0x58,0x64);
	}
	
	/**[txh]********************************************************************

  Description:
  Finds the main window title.

  Return:
  A pointer to a newly allocated string (new[]). Or 0 if fail. by SET.

***************************************************************************/
	
	static string GetWindowTitle()
	{
		wchar buf[mxTitleSize];
		DWORD ret = GetConsoleTitleW(buf.ptr, mxTitleSize);
		if (ret)
		{
			return cast(string)(buf[0..ret]);
			/*char *s=new char[ret+1];
			memcpy(s,buf,ret);
			s[ret]=0;
			return s;*/
		}
		return null;
	}
	
	/**[txh]********************************************************************

  Description:
  Sets the main window title.

  Return:
  non-zero successful. by SET.

***************************************************************************/
	
	static int SetWindowTitle(string name) {
		return SetConsoleTitleW((cast(wstring)(name~0)).ptr);
	}
	
	static void Beep()
	{
		MessageBeep(0xFFFFFFFF);
	}
	
	static void Init() {
		TScreen.setCursorPos = &SetCursorPos;
		TScreen.getCursorPos = &GetCursorPos;
		TScreen.getCursorShape = &GetCursorShape;
		TScreen.setCursorShape = &SetCursorShape;
		TScreen.getRows = &GetRows;
		TScreen.getCols = &GetCols;
		TScreen.checkForWindowSize = &CheckForWindowSize;
		TScreen.setWindowTitle = &SetWindowTitle;
		TScreen.getWindowTitle = &GetWindowTitle;
		TScreen.setCrtMode = &SetCrtMode;
		TScreen.setCrtModeExt = &SetCrtModeExt;
		TScreen.beep = &Beep;
	}

	this() {
		if (InitConsole() == false)  {
			return;
		}
		flags0 = Capabilities1.CodePageVar | Capabilities1.CursorShapes | Capabilities1.CanSetVideoSize;
		startupMode=getCrtMode();
		startupCursor = getCursorType();
		saveScreenWidth = GetCols();
		saveScreenHeight = GetRows();
		
		uint maxX=saveScreenWidth, maxY=saveScreenHeight;
		long aux;
		if (optSearch("ScreenWidth",aux))
			maxX = cast(uint)aux;
		if (optSearch("ScreenHeight",aux))
			maxY = cast(uint)aux;
		if (maxX!=saveScreenWidth || maxY!=saveScreenHeight) {
			setCrtModeRes(maxX,maxY);
			// Update cached values
			GetConsoleScreenBufferInfo(hOut, &ConsoleInfo);
		}
		
		cursorLines = getCursorType();
		screenWidth = GetCols();
		screenHeight = GetRows();
		
		screenBuffer = new CharInfo[screenHeight * screenWidth];
		
		GetCursorPos(xCurStart,yCurStart);
		suspended = 0;
		setCrtData();
	}

	int InitConsole() {
		DWORD flags;
		// Check if we are running in a console
		if (!GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), &flags))
			return 0;
		// Get handles to access Standard Input and Output
		hIn     = GetStdHandle(STD_INPUT_HANDLE);
		hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
		// Create a new buffer, it have their own content and cursor
		hOut = CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE, 0, null, CONSOLE_TEXTMODE_BUFFER, null);
		if (hStdOut == INVALID_HANDLE_VALUE || hOut==INVALID_HANDLE_VALUE) {
			return 0; // Something went wrong
		}
		// Make the new one the active
		if (!SetConsoleActiveScreenBuffer(hOut)) {
			return 0;
		}
		// If we are here this driver will be used
		initialized = 1;
		if (dCB) {
			dCB();
		}
		
		// Enable mouse input
		GetConsoleMode(hIn,&oldConsoleMode);
		newConsoleMode = oldConsoleMode | ENABLE_MOUSE_INPUT|ENABLE_WINDOW_INPUT;
		newConsoleMode &=~ (ENABLE_LINE_INPUT|ENABLE_ECHO_INPUT|ENABLE_PROCESSED_INPUT);
		SetConsoleMode(hIn,newConsoleMode);
		SetConsoleCtrlHandler(&ConsoleEventHandler, true);
		
		GetConsoleScreenBufferInfo(hOut, &ConsoleInfo);
		
		InitializeCriticalSection(&lockWindowSizeChanged);
		
		Init();
		
		TScreen.clearScreen = &clearScreen;
		TScreen.setCharacter = &setCharacter;
		TScreen.setCharacters = &setCharacters;
		TScreen.System_p = &System;
		TScreen.Resume = &Resume;
		TScreen.Suspend = &Suspend;
		TScreen.setCrtModeRes_p = &SetCrtModeRes;
		TScreen.setVideoModeRes_p = &SetVideoModeRes;
		TScreen.setVideoMode = &SetVideoMode;
		TScreen.setVideoModeExt = &SetVideoModeExt;
		
		TVWin32Clipboard.Init();
		TGKeyWin32.Init();
		THWMouseWin32.Init();
		
		DWORD EventThreadID;
		//EventThreadHandle = CreateThread(0, 0, cast(int)&HandleEvents, cast(int)hIn, 0, cast(int)&EventThreadID);
		import std.concurrency;
		spawn(&HandleEvents);
		
		UINT outCP = GetConsoleOutputCP();
		UINT  inCP = GetConsoleCP();
		// Look for user settings
		TScreen.optSearch("AppCP", forcedAppCP);
		TScreen.optSearch("ScrCP", forcedScrCP);
		TScreen.optSearch("InpCP", forcedInpCP);
		// User settings have more priority than detected settings
		SetDefaultCodePages(outCP,outCP,inCP);
		SetConsoleOutputCP(65001); // 437
		SetConsoleCP(65001); // 437
		return 1;
	}

	const CTRL_C_EVENT = 0,
		CTRL_BREAK_EVENT = 1,
		CTRL_CLOSE_EVENT = 2,
		CTRL_LOGOFF_EVENT = 5,
			CTRL_SHUTDOWN_EVENT = 6;

	static extern (Windows) BOOL ConsoleEventHandler(DWORD dwCtrlType) nothrow {
		if (dwCtrlType==CTRL_C_EVENT || dwCtrlType==CTRL_BREAK_EVENT)
			return true;
		return false;
	}

	static void clearScreen() {
		COORD coord ={0,0};
		DWORD read;
		uint size = GetRows()*GetCols();
		FillConsoleOutputAttribute(hOut,0x07,size,coord,&read);
		FillConsoleOutputCharacterA(hOut,' ',size,coord,&read);
	}

	static void setCharacter(uint offset, wchar ch, int attrib) {
		setCharacters(offset, [CharInfo(ch, cast(ubyte)attrib)]);
	}


	private static int sameCharCount(in CharInfo[] a, in CharInfo[] b) {
		int i = 0;
		while(i < a.length && i < b.length && a[i] == b[i]) {
			++i;
		}
		return i;
	}

	static void setCharacters(uint offset, const(CharInfo)[] src) {
		CharInfo[] old = screenBuffer[offset..$];
		int len = src.length;
		const(CharInfo) *oldRight = old.ptr + len-1;
		const(CharInfo) *srcRight = src.ptr + len-1;


		int sameCharCount = sameCharCount(old, src);
		offset += sameCharCount;
		len -= sameCharCount;
		src = src[sameCharCount..$];
		old = old[sameCharCount..$];
		
		/* remove unchanged characters from right to left */
		while (len > 0 && *oldRight == *srcRight) {
			len--;
			oldRight--;
			srcRight--;
		}
		
		/* write only middle changed characters */
		string asd = "être\u03bb\u20AC20";
		if (len > 0) {
			CHAR_INFO ch[maxViewWidth];
			assert(maxViewWidth >= len);
			short i = 0;
			for (; i < len; i++) {
				old[i] = src[i];
				wchar writtenChar = src[i].ch;
				ubyte writtenAttrib = src[i].attrib;
				ch[i].Attributes = writtenAttrib;
				ch[i].UnicodeChar = writtenChar;
			}
			
			ushort x = offset % screenWidth;
			ushort y = cast(ushort)(offset / screenWidth);
			
			SMALL_RECT to={x, y, cast(short)(x + i-1), y};
			COORD bsize = {i,1};
			static COORD from = {0,0};
			WriteConsoleOutputW(hOut, ch.ptr, bsize, from, &to);
		}
	}

	static int System(string command, pid_t *pidChild, int _in,
	                         int _out, int err) {
		// fork mechanism not implemented, indicate the child finished
		if (pidChild)
			*pidChild=0;
		// If the caller asks for redirection replace the requested handles
		/***if (_in!=-1)
			dup2(_in,STDIN_FILENO);
		if (_out!=-1)
			dup2(_out,STDOUT_FILENO);
		if (err!=-1)
			dup2(err,STDERR_FILENO);***/
		return system(command);
	}

	static void Resume() {
		// First switch to our handle
		SetConsoleActiveScreenBuffer(hOut);
		// Now we can save the current window size
		GetConsoleScreenBufferInfo(hOut,&ConsoleInfo);
		saveScreenWidth =ConsoleInfo.dwSize.X;
		saveScreenHeight=ConsoleInfo.dwSize.Y;
		// Restore our window size
		SetCrtModeRes(screenWidth, screenHeight);
		GetConsoleScreenBufferInfo(hOut,&ConsoleInfo);
		setCrtData();
		// Invalidate the cache to force a redraw
		screenBuffer[] = CharInfo(0, 0);
		
		GetConsoleMode(hIn,&oldConsoleMode);
		SetConsoleMode(hIn,newConsoleMode);
		SetConsoleCtrlHandler(&ConsoleEventHandler, true);
	}

	static int SetCrtModeRes(uint w, uint h, int fW = -1, int fH = -1) {
		CONSOLE_SCREEN_BUFFER_INFO info;
		// Find current size
		if (!GetConsoleScreenBufferInfo(hOut,&info))
		{
			return 0;
		}
		// Is the same used?
		if (info.dwSize.X == cast(int)w && info.dwSize.Y == cast(int)h)
		{
			return 0;
		}
		// Find the max. size, depends on the font and screen size.
		COORD max=GetLargestConsoleWindowSize(hOut);
		COORD newSize = {cast(short)w, cast(short)h};
		if (newSize.X>max.X) newSize.X=max.X;
		if (newSize.Y>max.Y) newSize.Y=max.Y;
		// The buffer must be large enough to hold both modes (current and new)
		COORD newBufSize=newSize;
		if (info.dwMaximumWindowSize.X>newBufSize.X)
			newBufSize.X=info.dwMaximumWindowSize.X;
		if (info.dwMaximumWindowSize.Y>newBufSize.Y)
			newBufSize.Y=info.dwMaximumWindowSize.Y;
		// Enlarge the buffer size. It fails if not windowed.
		if (!SetConsoleScreenBufferSize(hOut,newBufSize))
		{
			return 0;
		}
		// Resize the window.
		SMALL_RECT r={0,0,cast(short)(newSize.X-1), cast(short)(newSize.Y-1)};
		if (!SetConsoleWindowInfo(hOut,TRUE,&r)) {// Revert buffer size
			newSize.X=info.dwMaximumWindowSize.X;
			newSize.Y=info.dwMaximumWindowSize.Y;
			SetConsoleScreenBufferSize(hOut,newSize);
			return 0;
		}
		// Now we can shrink the buffer to the needed size
		SetConsoleScreenBufferSize(hOut, newSize);
		// Ok! we did it.
		return fW!=-1 || fH!=-1 || newSize.X!=cast(int)w || newSize.Y!=cast(int)h ? 2 : 1;
	}
	
	static void Suspend() {
		// Restore window size (using our handle!)
		SetCrtModeRes(saveScreenWidth,saveScreenHeight);
		// Switch to the original handle
		SetConsoleActiveScreenBuffer(hStdOut);
		SetConsoleMode(hIn,oldConsoleMode);
		SetConsoleCtrlHandler(&ConsoleEventHandler,false);
	}

	static int SetVideoModeRes(uint w, uint h, int fW = -1, int fH = -1) {// Set the screen mode
		int ret=setCrtModeRes(w,h,fW,fH);
		if (ret) {// Memorize new values:
			// Cache the values for TDisplay
			GetConsoleScreenBufferInfo(hOut,&ConsoleInfo);
			screenWidth =ConsoleInfo.dwSize.X;
			screenHeight=ConsoleInfo.dwSize.Y;
			screenBuffer=new CharInfo[screenHeight * screenWidth];
			// This is something silly TV code spects: after a video mode change the
			// cursor should go to the "default" state.
			setCursorType(cursorLines);
			// Cache the data about it and initialize related stuff
			setCrtData();
		}
		return ret;
	}

	static void SetVideoMode(ushort mode) {
		int oldWidth = screenWidth;
		int oldHeight = screenHeight;
		
		TScreen.defaultSetVideoMode(mode);
		CheckSizeBuffer(oldWidth, oldHeight);
	}

	static void CheckSizeBuffer(int oldWidth, int oldHeight) {
		screenBuffer = new CharInfo[screenWidth * screenHeight];
	}

	static void SetVideoModeExt(string mode) {
		int oldWidth = screenWidth;
		int oldHeight = screenHeight;
		
		TScreen.defaultSetVideoModeExt(mode);
		CheckSizeBuffer(oldWidth, oldHeight);
	}
	
	static void deInit() {
		Suspend();
		suspended = 1;
		setCursorType(startupCursor);
		DoneConsole();
		if (screenBuffer) {
			screenBuffer=null;
		}
	}

	static void DoneConsole() {
		INPUT_RECORD ir;
		DWORD written;
		
		// Stop the events thread
		//ZeroMemory(&ir,sizeof(ir));
		ExitEventThread = 1;
		ir.EventType=KEY_EVENT;
		WriteConsoleInputA(hIn, &ir, 1, &written);
		WaitForSingleObject(EventThreadHandle,INFINITE);
		CloseHandle(EventThreadHandle);
		
		DeleteCriticalSection(&lockWindowSizeChanged);
		THWMouseWin32.DeInit();
		TGKeyWin32.DeInit();
	}
}

static private void HandleEvents() {
	INPUT_RECORD ir;
	DWORD dwRead;
	while (!ExitEventThread) {
		WaitForSingleObject(hIn,INFINITE);
		if (!ExitEventThread) {
			if (PeekConsoleInputA(hIn,&ir,1,&dwRead) && dwRead>0) {
				switch (ir.EventType) {
					case MOUSE_EVENT:
						THWMouseWin32.HandleMouseEvent();
						break;	
					case KEY_EVENT:
						TGKeyWin32.HandleKeyEvent();
						break;	
					case WINDOW_BUFFER_SIZE_EVENT:
						EnterCriticalSection(&lockWindowSizeChanged);
						WindowSizeChanged = 1;
						LeaveCriticalSection(&lockWindowSizeChanged);
						goto default;
					default:
						ReadConsoleInputA(hIn,&ir,1,&dwRead);
						break;
				}
			}
		}
		else {
			ReadConsoleInputA(hIn,&ir,1,&dwRead);
		}
	}
}