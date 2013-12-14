module teventqueue;

import tevent;
import tgkey;
import tvconfig;
import ticks;

struct TEventQueue {
	static TMouse mouse = null;
	// SET: egcs gets upset if we partially initialize structures and egcs
	// 2.91.66 even crash under Linux (not in DOS, but prints "(null)").
	static TEvent[eventQSize] eventQueue;
	static TEvent* eventQHead;
	static TEvent* eventQTail;
	static this() {
		eventQHead = eventQueue.ptr;
		eventQTail = eventQueue.ptr;
	}
	static bool mouseIntFlag = false;
	
	static ushort eventCount = 0;
	
	static bool mouseEvents  = false;
	static bool mouseReverse = false;
	static int doubleDelay = 8;
	static int repeatDelay = 8;
	static int autoTicks = 0;
	static int autoDelay = 0;
	
	static MouseEventType lastMouse;
	static MouseEventType curMouse;
	static MouseEventType downMouse;
	static int downTicks = 0;

	static int TEventQueue_suspended = 1;

	static void init(int screenCols, int screenRows) {
		eventQueue[] = TEvent();
		resume(screenCols, screenRows);
	}
	
	static void resume(int screenCols, int screenRows) {
		if (!TEventQueue_suspended) 
			return;
		// SET: We resumed, no matters if mouse fails or not
		TEventQueue_suspended = 0;
		TGKey.resume();
		mouseEvents = false;
		if( !mouse )
			mouse = new TMouse();
		if( mouse.present() == false )
			mouse.resume();
		if( mouse.present() == false )
			return;
		mouse.getEvent( curMouse );
		lastMouse = curMouse;
		
		mouseEvents = true;
		//mouse.setRange( TScreen.getCols()-1, TScreen.getRows()-1 );
		mouse.setRange( screenCols-1, screenRows-1 );
	}

	static void suspend() {
		if (TEventQueue_suspended)
			return;
		if (mouse.present())
			mouse.suspend();
		/* RH: I think here is the right place for clearing the
     buffer */
		TGKey.clear();
		TGKey.suspend();
		TEventQueue_suspended = 1;
	}
	
	~this() {
		suspend();
	}
	
	const AUTO_DELAY_VAL = 1;
	
	static void getMouseEvent( ref TEvent ev ) {
		if( mouseEvents == true ) {
			getMouseState( ev );
			if( ev.mouse.buttons == 0 && lastMouse.buttons != 0 ) {
				ev.what = evMouseUp;
				//            int buttons = lastMouse.buttons;
				lastMouse = ev.mouse;
				//            ev.mouse.buttons = buttons;
				return;
			}
			
			if( ev.mouse.buttons != 0 && lastMouse.buttons == 0 ) {
				bool sameButtonPressed = ev.mouse.buttons == downMouse.buttons;
				bool onSamePos = ev.mouse.where == downMouse.where;
				bool inShortTime = ev.what - downTicks <= doubleDelay;
				if( sameButtonPressed && onSamePos && inShortTime) {
					ev.mouse.doubleClick = true;
				}
				
				downMouse = ev.mouse;
				autoTicks = downTicks = ev.what;
				autoDelay = repeatDelay;
				bool wheeled = (ev.mouse.buttons & (mbButton4 | mbButton5)) != 0;
				if (wheeled) {
					ev.what = evMouseWheel;
				} else {
					ev.what = evMouseDown;
				}
				lastMouse = ev.mouse;
				return;
			}
			
			ev.mouse.buttons = lastMouse.buttons;
			
			if( ev.mouse.where != lastMouse.where ) {
				ev.what = evMouseMove;
				lastMouse = ev.mouse;
				return;
			}
			
			auto deltaTick = ev.what - autoTicks;
			if( ev.mouse.buttons != 0 && deltaTick > autoDelay ) {
				autoTicks = ev.what;
				autoDelay = AUTO_DELAY_VAL;
				ev.what = evMouseAuto;
				lastMouse = ev.mouse;
				return;
			}
		}
		
		ev.what = evNothing;
	}
	
	static void getMouseState( ref TEvent ev ) {
		if( eventCount == 0 ) {
			TMouse.getEvent(ev.mouse);
			ev.what = CLY_Ticks();
		}
		else {
			ev = *eventQHead;
			if( ++eventQHead >= eventQueue.ptr + eventQSize )
				eventQHead = eventQueue.ptr;
			eventCount--;
		}
		if( mouseReverse != false && ev.mouse.buttons != 0 && ev.mouse.buttons != 3 )
			ev.mouse.buttons ^= 3;
	}

	version(TVCompf_djgpp) {
		//#include <tv/dos/mouse.h>
	
		static void mouseInt()
		{
			int buttonPress;
			
			if (THWMouseDOS.getRMCB_InfoDraw(buttonPress))
				mouseIntFlag=true;
			if (buttonPress && eventCount<eventQSize) {
				eventQTail.what = CLY_Ticks();
				eventQTail.mouse=curMouse;
				if (++eventQTail>=eventQueue+eventQSize)
					eventQTail=eventQueue;
				eventCount++;
			}
			
			curMouse = THWMouseDOS.intEvent;
		}
	} else {
		static void mouseInt()
		{
		}
	}
}