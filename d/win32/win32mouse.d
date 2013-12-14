module win32.win32mouse;

import core.sys.windows.windows;

import tevent;
import teventqueue;
import win32.win32key;
import win32.win32scr;

private static const eventMouseQSize = 300;

__gshared CRITICAL_SECTION lockMouse;
__gshared MouseEventType *evMouseIn;
__gshared MouseEventType *evLastMouseIn;
__gshared MouseEventType *evMouseOut;
__gshared MouseEventType evMouseQueue[eventMouseQSize];
__gshared uint evMouseLength;

struct THWMouseWin32 {

	static void Init() {
		THWMouse.GetEvent = &THWMouseWin32.GetEvent;
		THWMouse.Resume = &THWMouseWin32.Resume;
		InitializeCriticalSection(&lockMouse);
		evMouseLength = 0;
		evMouseIn = evMouseOut=&evMouseQueue[0];
		Resume();
	}
	
	static void Resume() {
		// SET: This is supposed to report if mouse is present and how many buttons
		// have. I put a detailed comment in winnt driver.
		THWMouse.buttonCount = cast(ubyte)GetSystemMetrics(SM_CMOUSEBUTTONS);
	}
	
	static void DeInit()
	{
		DeleteCriticalSection(&lockMouse);
	}
	
	static void putConsoleMouseEvent(ref MouseEventType mouse)
	{
		EnterCriticalSection(&lockMouse);
		if (evMouseLength<eventMouseQSize)
		{// Compress mouse events
			if (evLastMouseIn && evMouseLength && (evLastMouseIn.buttons==mouse.buttons))
				*evLastMouseIn=mouse;
			else
			{
				evMouseLength++;
				*evMouseIn=mouse;
				evLastMouseIn=evMouseIn;
				if (++evMouseIn >= (evMouseQueue.ptr+eventMouseQSize))
					evMouseIn=&evMouseQueue[0];
			}
		}
		LeaveCriticalSection(&lockMouse);
	}
	
	static void GetEvent(ref MouseEventType me) {
		EnterCriticalSection(&lockMouse);
		int hasmouseevent=evMouseLength>0;
		if (hasmouseevent) {
			evMouseLength--;
			me = *evMouseOut;
			if (++evMouseOut >= (evMouseQueue.ptr+eventMouseQSize))
				evMouseOut=&evMouseQueue[0];
		}
		else {
			// If no event is available use the last values so TV reports no changes
			me=TEventQueue.curMouse;
		}
		LeaveCriticalSection(&lockMouse);
	}
	
	static void HandleMouseEvent() {
		INPUT_RECORD ir;
		DWORD dwRead;
		ReadConsoleInputA(hIn,&ir,1,&dwRead);
		if ((dwRead==1) && (ir.EventType==MOUSE_EVENT)) {
			MouseEventType mouse;
			mouse.where.x = ir.MouseEvent.dwMousePosition.X;
			mouse.where.y = ir.MouseEvent.dwMousePosition.Y;
			mouse.buttons = 0;
			mouse.doubleClick = false;
			if (ir.MouseEvent.dwButtonState & FROM_LEFT_1ST_BUTTON_PRESSED) {
				mouse.buttons |= mbLeftButton;
			}
			if (ir.MouseEvent.dwButtonState & RIGHTMOST_BUTTON_PRESSED) {
				mouse.buttons |= mbRightButton;
			}
			if (ir.MouseEvent.dwButtonState & FROM_LEFT_2ND_BUTTON_PRESSED) {
				mouse.buttons |= mbMiddleButton;
			}
			const MOUSE_WHEELED = 0x004;
			if (ir.MouseEvent.dwEventFlags & MOUSE_WHEELED) {
				short deltaWheel = (ir.MouseEvent.dwButtonState >> 16) & 0xFFFF;
				if (deltaWheel > 0) {
					mouse.buttons |= mbButton4;
				} else {
					mouse.buttons |= mbButton5;
				}
				
			}
			putConsoleMouseEvent(mouse);
			TGKeyWin32.ProcessControlKeyState(&ir);
		}
	}

}

