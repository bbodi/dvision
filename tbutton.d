module tbutton;

import std.uni;

import common;
import tview;

private immutable wchar[] shadows = [0x2592, 0x2593, 0x2593];
private static string markers = "[]";

private static const ubyte[] cpButton = cast(ubyte[])"\x0A\x0B\x0C\x0D\x0E\x0E\x0E\x0F";

alias int function(Command command, void *data) TButtonCallBack;
private const int btcbGoOn=0, btcbEndModal=1;

private immutable TPalette palette = immutable(TPalette)( cpButton);

class TButton : TView {

	protected Command command;
    protected int flags;
    protected bool amDefault;
    protected TButtonCallBack callBack;
    protected void *cbData; // SET: Callback data

	private string title;

	this( int x, int y, string aTitle, Command aCommand, int aFlags) {
		this(TRect(x, y, x + aTitle.length+2, y+2), aTitle, aCommand, aFlags);
	}

	this( in TRect bounds, string aTitle, Command aCommand, int aFlags) {
		super(bounds);
		title = aTitle;
		command = aCommand;
		flags = aFlags;
		amDefault =  (aFlags & bfDefault) != 0;
		options |= ofSelectable | ofFirstClick | ofPreProcess | ofPostProcess;
    	eventMask |= evBroadcast;
    	if( !commandEnabled(aCommand) )
        	state |= sfDisabled;
    	callBack = null;
    	// This class can be "Braille friendly"
    	if (TScreen.getShowCursorEver())
       		state |= sfCursorVis;
		assert(size.y >= 2, "Bounds of the TButton must be higher or equal to 2");
	}

	void setCallBack(TButtonCallBack cb, void *aData=null) { 
		callBack=cb; 
		cbData=aData; 
	};

    string getText() { 
    	return title;
    };

    override void draw() {
    	drawState(false);
	}

	void drawState(bool down) {
	    ushort cButton, cShadow;
	    wchar   ch = ' ';
	    int    i;
	    TDrawBuffer b;

	    if( (state & sfDisabled) != 0 )
	        cButton = getColor(0x0404);
	    else {
	        cButton = getColor(0x0501);
	        if( (state & sfActive) != 0 ) {
	            if( (state & sfSelected) != 0 )
	                cButton = getColor(0x0703);
	            else if( amDefault )
	                cButton = getColor(0x0602);
			}
		}
	    cShadow = getColor(8);
	    int s = size.x-1;
	    int T = size.y / 2 - 1;

	    for( int y = 0; y <= size.y-2; y++ ) {
	        b.moveChar( 0, ' ', cButton, size.x );
	        b.putAttribute( 0, cShadow );
	        if( down ) {
	            b.putAttribute( 1, cShadow );
	            i = 2;
			} else {
	            b.putAttribute( s, cShadow );
	            if( showMarkers == false ) {
	                if( y == 0 ) {
	                    b.putChar( s, shadows[0] );
	                } else {
	                    b.putChar( s, shadows[1] );
	                }
	                ch = shadows[2];
				}
	            i =  1;
			}

	        if( y == T && title !is null )
	            drawTitle( b, s, i, cButton, down );

	        if( showMarkers && !down ) {
	            b.putChar( 1, markers[0] );
	            b.putChar( s-1, markers[1] );
			}
	        writeLine( 0, y, size.x, 1, b );
		}
	    b.moveChar( 0, ' ', cShadow, 2 );
	    b.moveChar( 2, ch, cShadow, s-1 );
	    writeLine( 0, size.y-1, size.x, 1, b );
	}

    private void drawTitle( ref TDrawBuffer b, int s, int i, ushort cButton, bool down ) {
    	int l, scOff;
    	string theTitle = getText();
    	if( (flags & bfLeftJust) != 0 ) {
        	l = 1;
    	} else {
        	l = (s - cast(int)theTitle.length - 1)/2;
        	if( l < 1 )
            	l = 1;
        }
    	b.moveCStr( i+l, theTitle, cButton );

    	if( showMarkers == true && !down ) {
        	if( (state & sfSelected) != 0 )
            	scOff = 0;
        	else if( amDefault )
            	scOff = 2;
        	else
            	scOff = 4;
        	b.putChar( 0, specialChars[scOff] );
        	b.putChar( s, specialChars[scOff+1] );
        }
    	if( (state & sfActive) && (state & sfSelected) ) {
        	setCursor( i+l-1 , 0 );
        	resetCursor();
        }
    }

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}

	override void handleEvent( ref TEvent event ) {
	    bool down = false;
	    char c = hotKey( getText() );

	    TRect clickRect = getExtent();
	    clickRect.a.x++;
	    clickRect.b.x--;
	    clickRect.b.y--;

	    if( event.what == evMouseDown ) {
	        TPoint mouse = makeLocal( event.mouse.where );
	        if( !clickRect.contains(mouse) )
	            clearEvent( event );
		}
	    TView.handleEvent(event);

	    switch( event.what ) {
	        case evMouseDown:
	            clickRect.b.x++;
	            do  {
	                TPoint mouse = makeLocal( event.mouse.where );
	                if( down != clickRect.contains( mouse ) ) {
	                    down = !down;
	                    drawState( down );
					}
				} while( mouseEvent( event, evMouseMove ) );
	            if( down ) {
	                press();
	                drawState( false );
				}
	            clearEvent( event );
	            break;

	        case evKeyDown:
	            if( event.keyDown.keyCode == TGKey.GetAltCode(c) ||
	                ( owner.phase == phaseType.phPostProcess &&
	                  c != 0 &&
	                  CompareUpperASCII(event.keyDown.charScan.charCode, c)
	                  //uctoupper(event.keyDown.charScan.charCode) == c
	                ) ||
	                ( (state & sfFocused) != 0 &&
	                  event.keyDown.charScan.charCode == ' '
	                )
	              ) {
	                press();
	                clearEvent( event );
				}
	            break;

	        case evBroadcast:
				Command cmd = event.message.command;
				if (cmd == cm.Default) {
					if( amDefault && !(state & sfDisabled) ) {
						press();
						clearEvent(event);
					}
				}
					
				if (cmd == cm.GrabDefault || cmd == cm.ReleaseDefault) {
					if( (flags & bfDefault) != 0 ) {
						amDefault = event.message.command == cm.ReleaseDefault;
						drawView();
					}
				}
				if (cmd == cm.CommandSetChanged) {
					if (((state & sfDisabled) && commandEnabled(command)) ||
						(!(state & sfDisabled) && !commandEnabled(command))) {
						setState(sfDisabled, !commandEnabled(command));
						drawView();
					}
				}
				break;
			default:
				break;
	        }
	}

	void makeDefault( bool enable ) {
	    if( (flags & bfDefault) == 0 ) {
	        message( owner,
	                 evBroadcast,
	                 (enable == true) ? cm.GrabDefault : cm.ReleaseDefault,
	                 this
	               );
	        amDefault = enable;
	        drawView();
		}
	}

	override void setState( ushort aState, bool enable ) {
	    TView.setState(aState, enable);
	    if( aState & (sfSelected | sfActive) ) {
	        if(!enable) {                           // BUG FIX - EFW - Thu 10/19/95
	            state &= ~sfFocused;
	            makeDefault(false);
	        }
	        drawView();
	    }
	    if( (aState & sfFocused) != 0 )
	        makeDefault( enable );
	}

	void press() {
		message(owner, evBroadcast, cm.RecordHistory,0);
		if (flags & bfBroadcast)
		   message(owner, evBroadcast, command,this);
		else {
			if (callBack) {
				int ret=callBack(command,cbData);
				if (ret==btcbEndModal && owner)
					owner.endModal(command);
			} else {
				TEvent e;
				e.what=evCommand;
				e.message.command = command;
				e.message.infoPtr = cast(void*)this;
				putEvent(e);
			}
		}
	}
}