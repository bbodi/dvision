module tprogram;

//import core.stdc.time;
import std.datetime;
import core.thread;

import tvision;

version(TVOS_Win32) {
	static private void CLY_ReleaseCPU() {
		Thread.sleep( dur!("msecs")( 50 ) );  // sleep for 50 
	}
}

const apColor      = 0;
const apBlackWhite = 1;
const apMonochrome = 2;

private static const ubyte[] cpColor = cast(ubyte[])"\x71\x70\x78\x74\x20\x28\x24\x17\x1F\x1A\x31\x31\x1E\x71\x00"
    "\x37\x3F\x3A\x13\x13\x3E\x21\x00\x70\x7F\x7A\x13\x13\x70\x7F\x00" 
    "\x70\x7F\x7A\x13\x13\x70\x70\x7F\x7E\x20\x2B\x2F\x78\x2E\x70\x30" 
    "\x3F\x3E\x1F\x2F\x1A\x20\x72\x31\x31\x30\x2F\x3E\x31\x13\x38\x00";

private static const ubyte[] cpBlackWhite = cast(ubyte[])"\x70\x70\x78\x7F\x07\x07\x0F\x07\x0F\x07\x70\x70\x07\x70\x00"
"\x07\x0F\x07\x70\x70\x07\x70\x00\x70\x7F\x7F\x70\x07\x70\x07\x00"
"\x70\x7F\x7F\x70\x07\x70\x70\x7F\x7F\x07\x0F\x0F\x78\x0F\x78\x07"
"\x0F\x0F\x0F\x70\x0F\x07\x70\x70\x70\x07\x70\x0F\x07\x07\x07\x00";

private static const ubyte[] cpMonochrome = cast(ubyte[])"\x70\x07\x07\x0F\x70\x70\x70\x07\x0F\x07\x70\x70\x07\x70\x00"
"\x07\x0F\x07\x70\x70\x07\x70\x00\x70\x70\x70\x07\x07\x70\x07\x00" 
"\x70\x70\x70\x07\x07\x70\x70\x70\x0F\x07\x07\x0F\x70\x0F\x70\x07" 
"\x0F\x0F\x07\x70\x07\x07\x70\x07\x07\x07\x70\x0F\x07\x07\x07\x00";

private immutable TPalette color = immutable(TPalette)( cpColor );
private immutable TPalette blackwhite = immutable(TPalette)( cpBlackWhite );
private immutable TPalette monochrome = immutable(TPalette)( cpMonochrome );
private immutable(TPalette)*[] palettes =  [&color, &blackwhite, &monochrome];

abstract class TProgram : TGroup {

	static TProgram application;
	static TDesktop deskTop;
	static TStatusLine statusLine;
	static TMenuBar  menuBar;
	static int appPalette = apColor;
	static TEvent pending;
	static TickDuration lastIdleClock = TickDuration.zero;
	static TickDuration inIdleTime = TickDuration.zero;
	static bool inIdle;
	static byte    doNotReleaseCPU = 0;
	static byte    doNotHandleAltNumber = 0;

	// Indicates that we are in idle, a mouse or 
	// keyboard event resets it    

	static void resetIdleTime() { inIdle=false; };

	private TScreen screen;

	TStatusLine createStatusLine(TRect r) const {
    	r.a.y = r.b.y - 1;
    	return new TStatusLine( r,
							   [TStatusDef( 0, 0xFFFF, [
            	TStatusItem( "~Alt-X~ Exit", KeyCode.kbAltX, cm.Quit ),
				TStatusItem( "~Alt-3~ Close", KeyCode.kbAltF3, cm.Close ),
				TStatusItem( "~F5~ Zoom", KeyCode.kbF5, cm.Zoom ),
				TStatusItem( "~Ctrl-F5~ Resize", KeyCode.kbCtrlF5, cm.Resize ),
				TStatusItem( "~F6~ Next", KeyCode.kbF6, cm.Next ),
          ]
    	)]);
	}

	TMenuBar createMenuBar(TRect r) const {
		r.b.y = r.a.y + 1;
		TSubMenu sub1 = new TSubMenu("~-~", KeyCode.kbNoKey, hcNoContext);
		sub1.add(new TMenuItem("~A~bout...", cm.About, KeyCode.kbNoKey, hcNoContext));
		return new TMenuBar(r, sub1);
	}

	TDesktop createDeskTop(in TRect extent) const {
		TRect r = extent;
		if (menuBar)
			r.a.y += menuBar.size.y;
		else
			r.a.y++;
		if (statusLine)
			r.b.y -= statusLine.size.y;
		else
			r.b.y--;
		return new TDesktop( r );
	}

	this()  {
		super(TRect( 0, 0, TScreen.screenWidth, TScreen.screenHeight ));
		progInit();
		changeBounds(TRect( 0, 0, TScreen.screenWidth, TScreen.screenHeight ));
		application = this;
		initScreen();
		state = sfVisible | sfSelected | sfFocused | sfModal | sfExposed;
		options = 0;
		syncScreenBuffer();
		
		if( TScreen.noUserScreen() )
			disableCommand( cm.CallShell );

		statusLine = createStatusLine(getExtent());
		if (statusLine !is null) {
			insert(statusLine);
		}
		menuBar = createMenuBar(getExtent());
		if (menuBar !is null) {
			insert(menuBar);
		}
		deskTop = createDeskTop(getExtent());
		if (deskTop !is null) {
			insert(deskTop);
		}
	}

	import win32.win32scr;
	import tscreen;
	static this() {
		version(TVOS_DOS) {
			Drivers ~= stDriver( TV_DOSDriverCheck, 100, "DOS" );
		}
		version(TVOS_UNIX) {
			version(HAVE_X11) {
				Drivers ~= stDriver( TV_XDriverCheck, 100, "X11" );
			}
			version(TVOSf_Linux) {
				Drivers ~= stDriver( TV_LinuxDriverCheck, 90, "Linux" );
			}
			version(TVOSf_QNXRtP) {
				Drivers ~= stDriver( TV_QNXRtPDriverCheck, 90, "QNX" );
			} else {
				version(TVOSf_QNX4) {
					Drivers ~= stDriver( TV_QNX4DriverCheck, 90, "QNX4" );
				} // TVOSf_QNX4
				Drivers ~= stDriver( TV_XTermDriverCheck, 60, "XTerm" );
				version(HAVE_NCURSES) {
					Drivers ~= stDriver( TV_UNIXDriverCheck, 10, "UNIX" );
				}
			} // TVOSf_QNXRtP
		}

		version(TVOS_Win32) {
			version(HAVE_X11) {
				// This is experimental, but believe it or not Cygwin have X11 support
				//Drivers ~= stDriver( TV_XDriverCheck,     100, "X11" );
			} // HAVE_X11
			version(TVOSf_NT) {
				//Drivers ~= stDriver( &TV_WinNTDriverCheck,  90, "WinNT" );
				version(TV_Disable_WinGr_Driver) {
					// Nothing
				} else{
					//Drivers ~= stDriver( &TV_WinGrDriverCheck,  80, "WinGr" );
				}
				Drivers ~= stDriver( &TV_Win32DriverCheck,  50, "Win32" );
			} else {
				TScreen.registerDriver(TScreen.stDriver( &TV_Win32DriverCheck, &TScreenWin32.deInit, 90, "Win32" ));
				version(TV_Disable_WinGr_Driver) {
					// Nothing
				} else{
					//	Drivers ~= stDriver( &TV_WinGrDriverCheck,  80, "WinGr" );
				}
				//Drivers ~= stDriver( &TV_WinNTDriverCheck,  50, "WinNT" );
			}
		}

		version(HAVE_ALLEGRO) {
			Drivers ~= stDriver( TV_AlconDriverCheck,  30, "AlCon" );
		}
	//	nDrivers = Drivers.length;
	}

	private void progInit() {
		// Load the configuration file
		//config.Load();
		// Read common settings
		long aux;
		/*if (config.Search("ShowCursorEver",aux))
			TScreen.setShowCursorEver(aux ? true : false);
		if (config.Search("DontMoveHiddenCursor",aux))
			TScreen.setDontMoveHiddenCursor(aux ? true : false);*/
		TScreen.setShowCursorEver(true);
		screen = new TScreen();
	}



	void initScreen() {
		if( !TDisplay.dual_display && (TScreen.screenMode & 0x00FF) != TDisplay.VideoModes.smMono ) {
			if( (TScreen.screenMode & TDisplay.VideoModes.smFont8x8) != 0 )
				shadowSize.x = 1;
			else
				shadowSize.x = 2;
			shadowSize.y = 1;
			showMarkers = false;
			if( (TScreen.screenMode & 0x00FF) == TDisplay.VideoModes.smBW80 )
				appPalette = apBlackWhite;
			else
				appPalette = apColor;
		} else {
			shadowSize.x = 0;
			shadowSize.y = 0;
			showMarkers = true;
			appPalette = apMonochrome;
		}
	}

	void syncScreenBuffer() {
		buffer = TScreen.screenBuffer;
	}

	void run() {
		execute();
		deInit();
	}

	private void deInit() {
		TScreen.deInit();
	}

	override void putEvent( ref TEvent event ) {
    	pending = event;
	}

	private TickDuration Clock() const {
		return TickDuration.currSystemTick();
	}

	override void getEvent(ref TEvent event) {
		if( pending.what != evNothing ) {
			event = pending;
			pending.what = evNothing;
			inIdle=false;
		} else {
			event.getMouseEvent();
			if( event.what == evNothing ) {
				event.getKeyEvent();
				if( event.what == evNothing ) {
					if( inIdle ) {
						TickDuration t = Clock();
						inIdleTime += t - lastIdleClock;
						lastIdleClock = t;
					} else {
						inIdleTime = TickDuration.zero;
						lastIdleClock = Clock();
						inIdle = true;
					}
					if (TScreen.checkForWindowSize()) {
						event.getKeyEvent();

						setScreenMode(0xFFFF);
						CLY_Redraw();
					}
					idle();
				}
				else {
					inIdle=false;
				}
			} else {
				inIdle=false;
			}
		}
		
		if( statusLine !is null ) {
			if( (event.what & evKeyDown) != 0 || ( (event.what & evMouseDown) != 0)) {
				if (firstThat( &hasMouse, &event ) == statusLine) {
					statusLine.handleEvent( event );
				}
			}
		}
	}

	void setScreenMode( ushort mode, string command = null ) {
		TRect  r;
		TMouse.hide();
		if (!TDisplay.dual_display) {
			if (mode == 0xFFFF && command)
				TScreen.setVideoModeExt( command );
			else
				TScreen.setVideoMode( mode );
		}
		initScreen();
		syncScreenBuffer();
		r = TRect( 0, 0, TScreen.screenWidth, TScreen.screenHeight );
		changeBounds( r );
		setState( sfExposed, false);
		redraw();
		setState(sfExposed, true);
		TMouse.show();
	}

	void idle() {
		if( statusLine !is null )
			statusLine.update();
		
		if( commandSetChanged == true ) {
			message( this, evBroadcast, cm.CommandSetChanged, 0 );
			commandSetChanged = false;
		}
		// SET: Release the CPU unless the user doesn't want it.
		if( !doNotReleaseCPU ) {
			CLY_ReleaseCPU(); // defined in ticks.cc
		}
	}

	private static bool hasMouse( TView p, void *s ) {
    	return (p.state & sfVisible) != 0 &&
                     p.mouseInView( (cast(TEvent *)s).mouse.where );	
    }

    override ref immutable(TPalette) getPalette() const {
    	return *(palettes[appPalette]);
	}

	override void handleEvent( ref TEvent event ) {
    	if( !doNotHandleAltNumber && event.what == evKeyDown ){
	        char c = TGKey.GetAltChar( event.keyDown.keyCode, event.keyDown.charScan.charCode );
	        if( c >= '1' && c <= '9' ) {
				if (current.valid(cm.ReleasedFocus)) {
					auto selectedWindow = message( deskTop, evBroadcast, cm.SelectWindowNum, cast(void *)(c - '0'));
					if(  selectedWindow !is null ) {
	                   clearEvent( event );
	               }
				}
			}
		}
	    TGroup.handleEvent( event );
	    if( event.what == evCommand && event.message.command == cm.Quit ) { 
	    	endModal( cm.Quit ); 
	    	clearEvent( event );
		}
	}

	TView validView(TView p) {
    	if( p is null )
        	return null;
    	if( !p.valid( cm.Valid ) ) {
        	CLY_destroy( p );
        	return null;
        }
    	return p;
	}
}