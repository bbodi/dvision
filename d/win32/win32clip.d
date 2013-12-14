module win32.win32clip;

import core.sys.windows.windows;
import std.conv;
import osclipboard;

// need User32.lib

extern (Windows) HANDLE GetClipboardData( UINT uFormat);
extern (Windows) LPVOID GlobalLock(HGLOBAL hMem);
extern (Windows) BOOL CloseClipboard();
extern (Windows) BOOL OpenClipboard( HWND hWndNewOwner);
extern (Windows) HGLOBAL GlobalAlloc( UINT uFlags, SIZE_T dwBytes);
extern (Windows) BOOL EmptyClipboard();
extern (Windows) HANDLE SetClipboardData(UINT uFormat, HANDLE hMem);


struct TVWin32Clipboard {
	static string[] win32NameError= [ null, null];

	static void Init()
	{
		TVOSClipboard.copy = &copy;
		TVOSClipboard.paste = &paste;
		TVOSClipboard.destroy = &destroy;
		TVOSClipboard.available = 1; // We have 1 clipboard
		TVOSClipboard.name = "Windows";
		// We get the error from windows, so we just change the pointer
		TVOSClipboard.errors = 1;
		TVOSClipboard.nameErrors = win32NameError;
	}
	
	static void getErrorString() {
		if (win32NameError[1])
			LocalFree(cast(LPVOID)win32NameError[1]);
		
		LPVOID lpMsgBuf;
		
		FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		              null,GetLastError(),
		              MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
		              cast(LPTSTR)&lpMsgBuf,0,null);
		win32NameError[1] = to!string(cast(const wchar *)lpMsgBuf);
		TVOSClipboard.error = 1;
	}
	
	static void destroy()
	{
		if (win32NameError[1]) {
			LocalFree(cast(LPVOID)win32NameError[1]);
		}
	}

	static private const CF_TEXT = 1;

	static string paste(int id) {
		if (id!=0) return null;
		
		string p;
		
		if (OpenClipboard(null)) {
			HGLOBAL hMem = GetClipboardData(CF_TEXT);
			if (hMem) {
				wchar *d = cast(wchar*)GlobalLock(hMem);
				if (d !is null) {
					p = to!string(d);
					GlobalUnlock(hMem);
				}
				else {
					getErrorString();
				}
			}
			else {
				getErrorString();
			}
			CloseClipboard();
		}
		else {
			getErrorString();
		}
		
		return p;
	}

	static private const 	GMEM_MOVEABLE = 0x0002;

	static int copy(int id, in char[] buffer) {
		if (id!=0) return 0;
		if (!buffer) return 1;
		
		HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, buffer.length+1);
		if (!hMem) {
			getErrorString();
			return 0;
		}
		
		char *d = cast(char *)GlobalLock(hMem);
		if (!d) {
			getErrorString();
			GlobalFree(hMem);
			return 0;
		}
		//memcpy(d, buffer,len);
		foreach(ch; buffer) {
			*d = cast(char)ch;
		}
		d[buffer.length] = 0;
		GlobalUnlock(hMem);
		
		if (OpenClipboard(null)) {
			EmptyClipboard();
			if (SetClipboardData(CF_TEXT, hMem)) {
				CloseClipboard();
				// Windows now owns the memory, we doesn't have to release it.
				return 1;
			}
			getErrorString();
			CloseClipboard();
		}
		else
			getErrorString();
		GlobalFree(hMem);
		
		return 0;
	}


}


