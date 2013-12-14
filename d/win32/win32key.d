module win32.win32key;

import core.sys.windows.windows;
import std.string;

import tevent;
import tgkey;
import win32.win32scr;


// need // need kernel32.lib

private const eventKeyboardQSize=16;
// Last value recieved for the shift modifiers
__gshared ushort LastControlKeyState;
// Queue
__gshared KeyDownEvent *evKeyboardIn;
__gshared KeyDownEvent *evKeyboardOut;
__gshared KeyDownEvent evKeyboardQueue[eventKeyboardQSize];
__gshared uint evKeyboardLength;
__gshared CRITICAL_SECTION lockKeyboard;

struct TGKeyWin32 {

	static void Init() {
		TGKey.kbhit = &kbHit;
		TGKey.getShiftState = &GetShiftState;
		TGKey.fillTEvent = &FillTEvent;
		
		InitializeCriticalSection(&lockKeyboard);
		evKeyboardLength=0;
		evKeyboardIn = evKeyboardOut = &evKeyboardQueue[0];
	}

	static void DeInit() {
		DeleteCriticalSection(&lockKeyboard);
	}
	
	static int kbHit() {
		return evKeyboardLength > 0;
	}
	
	static void FillTEvent(ref TEvent e) {
		getConsoleKeyboardEvent(e.keyDown);
		e.what=evKeyDown;
	}
	
	static ushort transShiftState(DWORD state) {
		ushort tvstate = 0;
		if (state & (RIGHT_ALT_PRESSED |LEFT_ALT_PRESSED) ) tvstate |= KeyCode.kbAltShift;
		if (state & (RIGHT_CTRL_PRESSED|LEFT_CTRL_PRESSED)) tvstate |= KeyCode.kbCtrlShift;
		if (state & SHIFT_PRESSED) tvstate |= KeyCode.kbLeftShift;
		if (state & NUMLOCK_ON   ) tvstate |= KeyCode.kbNumState;
		if (state & SCROLLLOCK_ON) tvstate |= KeyCode.kbScrollState;
		if (state & CAPSLOCK_ON  ) tvstate |= KeyCode.kbCapsState;
		
		return tvstate;
	}
	
	/* 
  Translate keyboard events to Salvador E. Tropea's key codes
  by Vadim Beloborodov
  Originally in trans.cc
*/
	
	static immutable byte[256] KeyTo=
	[
		/* 00 */                           0,
			/* 01 VK_LBUTTON */                0,
				/* 02 VK_RBUTTON */                0,
				/* 03 VK_CANCEL */                 0,
				/* 04 VK_MBUTTON */                0,
				/* 05 unassigned */                0,
				/* 06 unassigned */                0,
				/* 07 unassigned */                0,
				/* 08 VK_BACK */                   KeyCode.kbBackSpace,
				/* 09 VK_TAB */                    KeyCode.kbTab,
				/* 0A unassigned */                0,
				/* 0B unassigned */                0,
				/* 0C VK_CLEAR ?? */               0,
				/* 0D VK_RETURN */                 KeyCode.kbEnter,
				/* 0E unassigned */                0,
				/* 0F unassigned */                0,
				/* 10 VK_SHIFT */                  0,
				/* 11 VK_CONTROL */                0,
				/* 12 VK_MENU */                   0,
				/* 13 VK_PAUSE */                  0,
				/* 14 VK_CAPITAL */                0,
				/* 15 Kanji systems*/              0,
				/* 16 Kanji systems*/              0,
				/* 17 Kanji systems*/              0,
				/* 18 Kanji systems*/              0,
				/* 19 Kanji systems*/              0,
				/* 1A unassigned */                0,
				/* 1B VK_ESCAPE */                 KeyCode.kbEsc,
				/* 1C Kanji systems*/              0,
				/* 1D Kanji systems*/              0,
				/* 1E Kanji systems*/              0,
				/* 1F Kanji systems*/              0,
				/* 20 VK_SPACE */                  KeyCode.kbSpace,
				/* 21 VK_PRIOR */                  KeyCode.kbPgUp,
				/* 22 VK_NEXT */                   KeyCode.kbPgDn,
				/* 23 VK_END */                    KeyCode.kbEnd,
				/* 24 VK_HOME */                   KeyCode.kbHome,
				/* 25 VK_LEFT */                   KeyCode.kbLeft,
				/* 26 VK_UP */                     KeyCode.kbUp,
				/* 27 VK_RIGHT */                  KeyCode.kbRight,
				/* 28 VK_DOWN */                   KeyCode.kbDown,
				/* 29 VK_SELECT */                 0,
				/* 2A OEM specific */              0,
				/* 2B VK_EXECUTE */                0,
				/* 2C VK_SNAPSHOT */               0,
				/* 2D VK_INSERT */                 KeyCode.kbInsert,
				/* 2E VK_DELETE */                 KeyCode.kbDelete,
				/* 2F VK_HELP */                   0,
				/* 30 VK_0 '0' */                  KeyCode.kb0,
				/* 31 VK_1 '1' */                  KeyCode.kb1,
				/* 32 VK_2 '2' */                  KeyCode.kb2,
				/* 33 VK_3 '3' */                  KeyCode.kb3,
				/* 34 VK_4 '4' */                  KeyCode.kb4,
				/* 35 VK_5 '5' */                  KeyCode.kb5,
				/* 36 VK_6 '6' */                  KeyCode.kb6,
				/* 37 VK_7 '7' */                  KeyCode.kb7,
				/* 38 VK_8 '8' */                  KeyCode.kb8,
				/* 39 VK_9 '9' */                  KeyCode.kb9,
				/* 3A unassigned */                0,
				/* 3B unassigned */                0,
				/* 3C unassigned */                0,
				/* 3D unassigned */                0,
				/* 3E unassigned */                0,
				/* 3F unassigned */                0,
				/* 40 unassigned */                0,
				/* 41 VK_A 'A' */                  KeyCode.kbA,
				/* 42 VK_B 'B' */                  KeyCode.kbB,
				/* 43 VK_C 'C' */                  KeyCode.kbC,
				/* 44 VK_D 'D' */                  KeyCode.kbD,
				/* 45 VK_E 'E' */                  KeyCode.kbE,
				/* 46 VK_F 'F' */                  KeyCode.kbF,
				/* 47 VK_G 'G' */                  KeyCode.kbG,
				/* 48 VK_H 'H' */                  KeyCode.kbH,
				/* 49 VK_I 'I' */                  KeyCode.kbI,
				/* 4A VK_J 'J' */                  KeyCode.kbJ,
				/* 4B VK_K 'K' */                  KeyCode.kbK,
				/* 4C VK_L 'L' */                  KeyCode.kbL,
				/* 4D VK_M 'M' */                  KeyCode.kbM,
				/* 4E VK_N 'N' */                  KeyCode.kbN,
				/* 4F VK_O 'O' */                  KeyCode.kbO,
				/* 50 VK_P 'P' */                  KeyCode.kbP,
				/* 51 VK_Q 'Q' */                  KeyCode.kbQ,
				/* 52 VK_R 'R' */                  KeyCode.kbR,
				/* 53 VK_S 'S' */                  KeyCode.kbS,
				/* 54 VK_T 'T' */                  KeyCode.kbT,
				/* 55 VK_U 'U' */                  KeyCode.kbU,
				/* 56 VK_V 'V' */                  KeyCode.kbV,
				/* 57 VK_W 'W' */                  KeyCode.kbW,
				/* 58 VK_X 'X' */                  KeyCode.kbX,
				/* 59 VK_Y 'Y' */                  KeyCode.kbY,
				/* 5A VK_Z 'Z' */                  KeyCode.kbZ,
				/* 5B unassigned */                0,
				/* 5C unassigned */                0,
				/* 5D unassigned */                0,
				/* 5E unassigned */                0,
				/* 5F unassigned */                0,
				/* 60 VK_NUMPAD0 NumKeyPad '0' */  KeyCode.kb0,
				/* 61 VK_NUMPAD1 NumKeyPad '1' */  KeyCode.kb1,
				/* 62 VK_NUMPAD2 NumKeyPad '2' */  KeyCode.kb2,
				/* 63 VK_NUMPAD3 NumKeyPad '3' */  KeyCode.kb3,
				/* 64 VK_NUMPAD4 NumKeyPad '4' */  KeyCode.kb4,
				/* 65 VK_NUMPAD5 NumKeyPad '5' */  KeyCode.kb5,
				/* 66 VK_NUMPAD6 NumKeyPad '6' */  KeyCode.kb6,
				/* 67 VK_NUMPAD7 NumKeyPad '7' */  KeyCode.kb7,
				/* 68 VK_NUMPAD8 NumKeyPad '8' */  KeyCode.kb8,
				/* 69 VK_NUMPAD9 NumKeyPad '9' */  KeyCode.kb9,
				/* 6A VK_MULTIPLY */               KeyCode.kbAsterisk,
				/* 6B VK_ADD */                    KeyCode.kbPlus,
				/* 6C VK_SEPARATOR */              KeyCode.kbBackSlash,
				/* 6D VK_SUBSTRACT */              KeyCode.kbMinus,
				/* 6E VK_DECIMAL */                KeyCode.kbGrave,
				/* 6F VK_DIVIDE */                 KeyCode.kbSlash,
				/* 70 VK_F1 'F1' */                KeyCode.kbF1,
				/* 71 VK_F2 'F2' */                KeyCode.kbF2,
				/* 72 VK_F3 'F3' */                KeyCode.kbF3,
				/* 73 VK_F4 'F4' */                KeyCode.kbF4,
				/* 74 VK_F5 'F5' */                KeyCode.kbF5,
				/* 75 VK_F6 'F6' */                KeyCode.kbF6,
				/* 76 VK_F7 'F7' */                KeyCode.kbF7,
				/* 77 VK_F8 'F8' */                KeyCode.kbF8,
				/* 78 VK_F9 'F9' */                KeyCode.kbF9,
				/* 79 VK_F10 'F10' */              KeyCode.kbF10,
				/* 7A VK_F11 'F11' */              KeyCode.kbF11,
				/* 7B VK_F12 'F12' */              KeyCode.kbF12,
				/* 7C VK_F13 */                    0,
				/* 7D VK_F14 */                    0,
				/* 7E VK_F15 */                    0,
				/* 7F VK_F16 */                    0,
				/* 80 VK_F17 */                    0,
				/* 81 VK_F18 */                    0,
				/* 82 VK_F19 */                    0,
				/* 83 VK_F20 */                    0,
				/* 84 VK_F21 */                    0,
				/* 85 VK_F22 */                    0,
				/* 86 VK_F23 */                    0,
				/* 87 VK_F24 */                    0,
				/* 88 unassigned */                0,
				/* 89 VK_NUMLOCK */                0,
				/* 8A VK_SCROLL */                 0,
				/* 8B unassigned */                0,
				/* 8C unassigned */                0,
				/* 8D unassigned */                0,
				/* 8E unassigned */                0,
				/* 8F unassigned */                0,
				/* 90 unassigned */                0,
				/* 91 unassigned */                0,
				/* 92 unassigned */                0,
				/* 93 unassigned */                0,
				/* 94 unassigned */                0,
				/* 95 unassigned */                0,
				/* 96 unassigned */                0,
				/* 97 unassigned */                0,
				/* 98 unassigned */                0,
				/* 99 unassigned */                0,
				/* 9A unassigned */                0,
				/* 9B unassigned */                0,
				/* 9C unassigned */                0,
				/* 9D unassigned */                0,
				/* 9E unassigned */                0,
				/* 9F unassigned */                0,
				/* A0 unassigned */                0,
				/* A1 unassigned */                0,
				/* A2 unassigned */                0,
				/* A3 unassigned */                0,
				/* A4 unassigned */                0,
				/* A5 unassigned */                0,
				/* A6 unassigned */                0,
				/* A7 unassigned */                0,
				/* A8 unassigned */                0,
				/* A9 unassigned */                0,
				/* AA unassigned */                0,
				/* AB unassigned */                0,
				/* AC unassigned */                0,
				/* AD unassigned */                0,
				/* AE unassigned */                0,
				/* AF unassigned */                0,
				/* B0 unassigned */                0,
				/* B1 unassigned */                0,
				/* B2 unassigned */                0,
				/* B3 unassigned */                0,
				/* B4 unassigned */                0,
				/* B5 unassigned */                0,
				/* B6 unassigned */                0,
				/* B7 unassigned */                0,
				/* B8 unassigned */                0,
				/* B9 unassigned */                0,
				/* BA OEM specific */              0,
				/* BB OEM specific */              0,
				/* BC OEM specific */              0,
				/* BD OEM specific */              0,
				/* BE OEM specific */              0,
				/* BF OEM specific */              0,
				/* C0 OEM specific */              0,
				/* C1 unassigned */                0,
				/* C2 unassigned */                0,
				/* C3 unassigned */                0,
				/* C4 unassigned */                0,
				/* C5 unassigned */                0,
				/* C6 unassigned */                0,
				/* C7 unassigned */                0,
				/* C8 unassigned */                0,
				/* C9 unassigned */                0,
				/* CA unassigned */                0,
				/* CB unassigned */                0,
				/* CC unassigned */                0,
				/* CD unassigned */                0,
				/* CE unassigned */                0,
				/* CF unassigned */                0,
				/* D0 unassigned */                0,
				/* D1 unassigned */                0,
				/* D2 unassigned */                0,
				/* D3 unassigned */                0,
				/* D4 unassigned */                0,
				/* D5 unassigned */                0,
				/* D6 unassigned */                0,
				/* D7 unassigned */                0,
				/* D8 unassigned */                0,
				/* D9 unassigned */                0,
				/* DA unassigned */                0,
				/* DB OEM specific */              0,
				/* DC OEM specific */              0,
				/* DD OEM specific */              0,
				/* DE OEM specific */              0,
				/* DF OEM specific */              0,
				/* E0 OEM specific */              0,
				/* E1 OEM specific */              0,
				/* E2 OEM specific */              0,
				/* E3 OEM specific */              0,
				/* E4 OEM specific */              0,
				/* E5 unassigned */                0,
				/* E6 OEM specific */              0,
				/* E7 unassigned */                0,
				/* E8 unassigned */                0,
				/* E9 OEM specific */              0,
				/* EA OEM specific */              0,
				/* EB OEM specific */              0,
				/* EC OEM specific */              0,
				/* ED OEM specific */              0,
				/* EE OEM specific */              0,
				/* EF OEM specific */              0,
				/* F0 OEM specific */              0,
				/* F1 OEM specific */              0,
				/* F2 OEM specific */              0,
				/* F3 OEM specific */              0,
				/* F4 OEM specific */              0,
				/* F5 OEM specific */              0,
				/* F6 unassigned */                0,
				/* F7 unassigned */                0,
				/* F8 unassigned */                0,
				/* F9 unassigned */                0,
				/* FA unassigned */                0,
				/* FB unassigned */                0,
				/* FC unassigned */                0,
				/* FD unassigned */                0,
				/* FE unassigned */                0,
				/* FF unassigned */                0
	];
	
	static int transKeyEvent(ref KeyDownEvent dst, ref KEY_EVENT_RECORD src) {
		if (src.wVirtualKeyCode!=VK_MENU && src.wVirtualKeyCode!=VK_CONTROL && src.wVirtualKeyCode!=VK_SHIFT) {
			auto srcKeyCode = src.wVirtualKeyCode;
			dst.keyCode = cast(KeyCode)KeyTo[srcKeyCode];
			dst.charScan.charCode = src.AsciiChar;
			dst.charScan.scanCode = cast(ubyte)src.wVirtualScanCode;
			dst.raw_scanCode = cast(ubyte)src.wVirtualScanCode;
			dst.shiftState = transShiftState(src.dwControlKeyState);
			if (dst.shiftState&KeyCode.kbAltShift)  dst.keyCode|= KeyCode.kbAltLCode;
			if (dst.shiftState&KeyCode.kbCtrlShift) dst.keyCode|= KeyCode.kbCtrlCode;
			if (dst.shiftState&KeyCode.kbShift)     dst.keyCode|= KeyCode.kbShiftCode;
			return 1;
		}
		return 0;   
	}
	
	/* 
  Win32 console events handlers
  by Vadim Beloborodov
  Originally in console.cc
*/
	// Table used to Translate keyboard events
	// Table for ASCII printable values
	static immutable string testChars =
	"`1234567890-="
	"~!@#$%^&*()_+"
	"qwertyuiop[]"
	"QWERTYUIOP{}"
	"asdfghjkl;'\\"
	"ASDFGHJKL:\"|"
	"zxcvbnm,./"
	"ZXCVBNM<>?";

	

	static uint GetShiftState() {
		return LastControlKeyState;
	}
	
	static void putConsoleKeyboardEvent(ref KeyDownEvent key)
	{
		EnterCriticalSection(&lockKeyboard);
		if (evKeyboardLength<eventKeyboardQSize) {
			evKeyboardLength++;
			*evKeyboardIn=key;
			if (++evKeyboardIn >= (evKeyboardQueue.ptr+eventKeyboardQSize))
				evKeyboardIn=&evKeyboardQueue[0];
		}
		LeaveCriticalSection(&lockKeyboard);
	}
	
	static int getConsoleKeyboardEvent(ref KeyDownEvent key) {
		EnterCriticalSection(&lockKeyboard);
		int haskeyevent = evKeyboardLength > 0;
		if (haskeyevent)
		{
			evKeyboardLength--;
			key = *evKeyboardOut;
			if (++evKeyboardOut >= (evKeyboardQueue.ptr+eventKeyboardQSize))
				evKeyboardOut=&evKeyboardQueue[0];
		}
		LeaveCriticalSection(&lockKeyboard);
		return haskeyevent;
	}
	
	static void HandleKeyEvent() {
		INPUT_RECORD ir;
		DWORD dwRead;
		PeekConsoleInputA(hIn, &ir,1,&dwRead);
		if ((dwRead==1) && (ir.EventType==KEY_EVENT)) {
			if (ir.KeyEvent.bKeyDown) {
				//support for non US keyboard layout on Windows95
				if (((ir.KeyEvent.dwControlKeyState & (RIGHT_ALT_PRESSED|LEFT_ALT_PRESSED|RIGHT_CTRL_PRESSED|LEFT_CTRL_PRESSED))==0) &&
				    (ir.KeyEvent.AsciiChar) &&
				    (testChars.indexOf(ir.KeyEvent.AsciiChar)!=-1))
				{
					ubyte chr;
					ReadConsoleA(hIn,&chr,1,&dwRead, null);
					ir.KeyEvent.AsciiChar = chr;
					dwRead=0;
				}
				else
				{
					ReadConsoleInputW(hIn, &ir,1, &dwRead);
					dwRead = 0;
				}
				//translate event
				KeyDownEvent key;
				if (transKeyEvent(key,ir.KeyEvent))
					putConsoleKeyboardEvent(key);
			}
			ProcessControlKeyState(&ir);
		}
		if (dwRead==1)
			ReadConsoleInputA(hIn,&ir,1,&dwRead);
	}
	
	static void ProcessControlKeyState(INPUT_RECORD *ir) {
		LastControlKeyState = transShiftState(ir.KeyEvent.dwControlKeyState);
	}
}