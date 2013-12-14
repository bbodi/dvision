module tevent;

//import tview;
import teventqueue;
import tpoint;
import tgkey;
import codepage;
import tview;

const ushort evMouseDown = 0x0001;
const ushort evMouseUp   = 0x0002;
const ushort evMouseMove = 0x0004;
const ushort evMouseAuto = 0x0008;
const ushort evKeyDown   = 0x0010;
const ushort evCommand   = 0x0100;
const ushort evBroadcast = 0x0200;
const ushort evMouseWheel = 0x0400;
const positionalEvents    = evMouse;
const focusedEvents       = evKeyboard | evCommand;


struct CharScanType {
	ubyte charCode;        // The character encoded in the application code page
	ubyte scanCode;
};

struct KeyDownEvent {
	CharScanType charScan;
	KeyCode keyCode;        // Internal code, used for special keys (i.e. arrows)
	ushort shiftState;
	ubyte  raw_scanCode;
	uint charCode;       // The Unicode16 of the key when the driver is in
	// Unicode16 mode. 0xFFFF if no character is associated.
};

struct MessageEvent {
	Command command;
	union
	{
		void *infoPtr;
		long infoLong;
		ushort infoWord;
		short infoInt;
		ubyte infoByte;
		char infoChar;
	};
};

struct TEvent {
	int what;
	union
	{
		MouseEventType mouse;
		KeyDownEvent keyDown;
		MessageEvent message;
	};

	void getMouseEvent() {
		TEventQueue.getMouseEvent( this );
	}

	void getKeyEvent() {
		if (TGKey.kbhit()) {
			TGKey.fillTEvent(this);
			// SET: That's a special case, when the keyboard indicates the event
			// is mouse up it means the keyboard forced an event in the mouse module.
			if (what == evMouseUp) {
				getMouseEvent();
			}
		}
		else {
			what=evNothing;
		}
	}
};


import tprogram;
void *message(T)( TView receiver, int what, Command command, T infoPtr) {
	if( receiver is null ) {
		receiver = TProgram.deskTop;
	}
	if (receiver is null) {
		return null;
	}
	
	TEvent event;
	event.what = what;
	event.message.command = command;
	event.message.infoPtr = cast(void*)infoPtr;
	receiver.handleEvent( event );
	if( event.what == evNothing )
		return event.message.infoPtr;
	else
		return null;
}

void *messageToDesktop(T)( int what, Command command, T infoPtr) {
	return message(null, what, command, infoPtr);
}


/* Event masks */

const ushort evNothing   = 0x0000;
const ushort evMouse     = 0x000f;
const ushort evKeyboard  = 0x0010;
const ushort evMessage   = 0xFF00;

/* Mouse button state masks */
/* SET: Note that I redefined them to make it coherent with most UNIX systems
   where the left button is the first, the middle one the second, etc. But safe
   code shouldn't rely on it. */
const ushort mbLeftButton  = 0x01;
const ushort mbMiddleButton= 0x02;
const ushort mbRightButton = 0x04;
const ushort mbButton4     = 0x08;
const ushort mbButton5     = 0x10;

struct MouseEventType {
	ubyte buttons;
	bool doubleClick;
	TPoint where;
};

// This class is the base hardware interface with the mouse and shouldn't
// be used directly. You should use TMouse instead which is derived from
// it. That's why most members are protected.
// See thwmouse.cc
class THWMouse {

	
public
	// This indicates how many buttons have the mouse. Is also used to determine
	// if the mouse is present, a value of 0 is mouse not available. See the
	// present() member.
	static ubyte buttonCount;
	// SET: Suspend sets buttonCount to 0 to disable the mouse. The default
	// resume behavior is to restore this value.
	static ubyte oldButtonCount;
	// SET: Just to avoid redundant calls
	static byte  visible;
	// SET: Data used to force an event externally
	static MouseEventType forcedME;
	static byte forced;
	static ubyte btBeforeForce;
	
	// SET: Moved to the protected section
	static bool handlerInstalled;
	static bool noMouse;
	// The following counter is incremented when the mouse pointer is updated
	// by the driver. Only useful when done asynchronically.
	static uint drawCounter; // volatile

	static bool present() {
		return buttonCount != 0;
	}

	void inhibit() {
		noMouse = true;
	}

	/*****************************************************************************
  Function pointer members initialization
*****************************************************************************/
	
	static void  function() Show                               =&defaultShow;
	static void  function() Hide                               =&defaultHide;
	static void  function(int, int) setRange             =&defaultSetRange;
	static void  function(ref MouseEventType) GetEvent         =&defaultGetEvent;
	static void  function(uint, void function()) registerHandler	=&defaultRegisterHandler;
	static void  function() Suspend                            =&defaultSuspend;
	static void  function() Resume                             =&defaultResume;
	static int   function(int x, int y) drawMouse              =&defaultDrawMouse;
	
/*****************************************************************************
  Default behaviors for the members
*****************************************************************************/
	
	static void defaultShow() {
		visible = 1;
	}
	
	static void defaultHide() {
		visible=0;
	}
	
	static void defaultSuspend() {}
	static void defaultResume() { buttonCount=oldButtonCount; }
	static void defaultSetRange(int /*rx*/, int /*ry*/) {}
	static int  defaultDrawMouse(int /*x*/, int /*y*/) { return 0; }
	
	static void defaultRegisterHandler(uint, void function()) {}
	
	static void defaultGetEvent(ref MouseEventType me) {
		me.where.x = TEventQueue.curMouse.where.x;
		me.where.y = TEventQueue.curMouse.where.y;
		me.buttons = TEventQueue.curMouse.buttons;
		me.doubleClick=false;
	}
	
/*****************************************************************************
  Real members
*****************************************************************************/
	
	this() {
		resume();
	}
	
	~this() {
		suspend();
	}
	
	static void show() {
		if (!present() || visible) return;
		Show();
	}
	
	static void hide() {
		if (!present() || !visible) return;
		Hide();
	}
	
	static void suspend() {
		if (!present())
			return;
		if (visible)
			Hide();
		oldButtonCount=buttonCount;
		buttonCount=0;
		Suspend();
	}
	
	static void resume() {
		if (present())
			return;
		Resume();
		if (!visible)
			Show();
	}
	
	static void forceEvent(int x, int y, int buttons) {
		forced = 0;
		if (TEventQueue.curMouse.where.x!=x || TEventQueue.curMouse.where.y!=y)
			forced++;
		if (TEventQueue.curMouse.buttons!=buttons)
			forced++;
		forcedME.where.x = x;
		forcedME.where.y = y;
		forcedME.doubleClick=false;
		btBeforeForce = forcedME.buttons;
		forcedME.buttons = cast(ubyte)buttons;
	}
	
	static void getEvent(ref MouseEventType me) {
		if (!present()) {
			me = TEventQueue.curMouse;
			return;
		}
		if (forced) {
			me = forcedME;
			if (forced == 2) {
				me.buttons = btBeforeForce;
			}
			TEventQueue.curMouse = me;
			drawMouse(forcedME.where.x,forcedME.where.y);
			forced--;
		} else if (handlerInstalled) {
			me = TEventQueue.curMouse;
		} else {
			GetEvent(me);
			TEventQueue.curMouse = me;
		}
	}
}

// This class exposses the mouse interface.
class TMouse : THWMouse {

	this()
	{
		show();
	}
	
	~this()
	{
		hide();
	}

	static void show()
	{
		THWMouse.show();
	}

	static void hide()
	{
		THWMouse.hide();
	}

	static void suspend()
	{
		THWMouse.suspend();
	}

	static void resume()
	{
		THWMouse.resume();
	}

	static void setRange(int rx, int ry) {
		THWMouse.setRange(rx,ry);
	}

	static void getEvent(ref MouseEventType me)
	{
		THWMouse.getEvent(me);
	}

	static void registerHandler(uint mask, void  function() func)
	{
		THWMouse.registerHandler(mask, func);
	}

	static bool present()
	{
		return THWMouse.present();
	}

	static void resetDrawCounter() {
		synchronized {
			drawCounter=0;
		}
	}

	static uint getDrawCounter() {
		synchronized {
			return drawCounter;
		}
	}
}
/****************************************************************************************/


