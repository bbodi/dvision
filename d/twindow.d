module twindow;

import tview;
import tframe;
import tscrollbar;

private const TPoint minWinSize = {16, 6};


private const ubyte[] cpBlueWindow  = cast(ubyte[])"\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F";
private const ubyte[] cpCyanWindow  = cast(ubyte[])"\x10\x11\x12\x13\x14\x15\x16\x17";
private const ubyte[] cpGrayWindow  = cast(ubyte[])"\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F";

private immutable TPalette blue = immutable(TPalette)( cpBlueWindow);
private immutable TPalette cyan = immutable(TPalette)( cpCyanWindow);
private immutable TPalette gray = immutable(TPalette)( cpGrayWindow);
private immutable(TPalette)*[] palettes;
static this() {
	palettes = [&blue, &cyan, &gray];
}

class TWindow : TGroup {

	string title;
	int number;
	ubyte flags;
    TRect zoomRect;
    short palette;
    TFrame frame;

	string getTitle( int ) {
    	return title;
	}

	this(in TRect bounds, string aTitle, short aNumber) {
		super(bounds);
		flags =  wfMove | wfGrow | wfClose | wfZoom;
		zoomRect = getBounds();
		palette = wpBlueWindow;
		number = aNumber;
		title = aTitle;
	    state |= sfShadow;
	    options |= ofSelectable | ofTopSelect;
	    growMode = gfGrowAll | gfGrowRel;
	    eventMask |= evMouseUp; //for TFrame
	    frame = createFrame(getExtent());
	    if( frame !is null ) {
			insert( frame );
	    }
	}

	TFrame createFrame( in TRect r ) {
	    return new TFrame(r);
	}

	void close() {
	    if( valid( cm.Close ) ) { // SET: tell the application we are closing
			message( null/*TProgram.application*/, evBroadcast, cm.ClosingWindow, this );
			frame = null;  // so we don't try to use the frame after it's been deleted
			CLY_destroy( this );
		}
	}

	override void shutDown() {
	    frame = null;
	    TGroup.shutDown();
	}

	override ref immutable(TPalette) getPalette() const {
	    return *(palettes[palette]);
	}

	override void handleEvent( ref TEvent event ) {
		TRect  limits;
		TPoint min, max;

	    TGroup.handleEvent(event);
	    if( event.what== evCommand ) {
			bool sendToThisWindow =  cast(TWindow)event.message.infoPtr is this;
			Command cmd = event.message.command;
			if (cmd == cm.Resize) {
				if( (flags & (wfMove | wfGrow)) != 0 ) {
					limits = owner.getExtent();
					sizeLimits(min, max);
					dragView( event, dragMode | (flags & (wfMove | wfGrow)),
							 limits, min, max);
					clearEvent(event);
				}
			} else if (cmd == cm.Close) {
				if( (flags & wfClose) != 0 && ( event.message.infoPtr == null || sendToThisWindow)) {
					if( (state & sfModal) == 0 ) {
						close();
					} else {
						event.what = evCommand;
						event.message.command = cm.Cancel;
						putEvent( event );
					}
					clearEvent( event );
				}
			} else if (cmd == cm.Zoom) {
				if( (flags & wfZoom) != 0 && (event.message.infoPtr == null || sendToThisWindow) ) {
					zoom();
					clearEvent(event);
				}
			}
	    } else if( event.what == evKeyDown ) {
	            switch (event.keyDown.keyCode) {
	                case  KeyCode.kbTab:
	                case  KeyCode.kbDown:
	                case  KeyCode.kbRight:
	                    selectNext(false);
	                    clearEvent(event);
	                    break;
	                case  KeyCode.kbShTab:
	                case  KeyCode.kbUp:
	                case  KeyCode.kbLeft:
	                    selectNext(true);
	                    clearEvent(event);
	                    break;
					default:
	                    break;
	                } 
		} else if( event.what == evBroadcast && 
	             event.message.command == cm.SelectWindowNum &&
	             event.message.infoInt == number && 
	             (options & ofSelectable) != 0
	           ) {
	            select();
	            clearEvent(event);
			   }
	}

	override void setState( ushort aState, bool enable ) {
		//#define C(x) if (enable == true) enableCommand(x); else disableCommand(x)
		template EnableOrDisableCommand(string cmd) {
			const char[] EnableOrDisableCommand = "if (enable == true) enableCommand("~cmd~"); else disableCommand("~cmd~");";
		}
	    TGroup.setState(aState, enable);
	    if( (aState & sfSelected) != 0 ) {
	        setState(sfActive, enable);
	        if( frame !is null)
	            frame.setState(sfActive,enable);
	        mixin(EnableOrDisableCommand!("cm.Next"));
	        mixin(EnableOrDisableCommand!("cm.Prev"));
	        if( (flags & (wfGrow | wfMove)) != 0 ) {
	            mixin(EnableOrDisableCommand!("cm.Resize"));
	        }
	        if( (flags & wfClose) != 0 ) {
	            mixin(EnableOrDisableCommand!("cm.Close"));
	        }
	        if( (flags & wfZoom) != 0 ) {
	            mixin(EnableOrDisableCommand!("cm.Zoom"));
	        }
		}
	}

	TScrollBar standardScrollBar( ushort aOptions ) {
	    TRect r = getExtent();
	    if( (aOptions & sbVertical) != 0 )
	        r = TRect( r.b.x-1, r.a.y+1, r.b.x, r.b.y-1 );
	    else
	        r = TRect( r.a.x+2, r.b.y-1, r.b.x-2, r.b.y );

	    TScrollBar s;
	    insert( s = new TScrollBar(r) );
	    if( (aOptions & sbHandleKeyboard) != 0 )
	        s.options |= ofPostProcess;
	    return s;
	}

	override void sizeLimits( out TPoint min, out TPoint max ) const {
	    TView.sizeLimits(min, max);
	    min = minWinSize;
	}

	void zoom() {
	    TPoint minSize, maxSize;
	    sizeLimits( minSize, maxSize );
	    if( size != maxSize ) {
	        zoomRect = getBounds();
	        TRect r = TRect( 0, 0, maxSize.x, maxSize.y );
	        locate(r);
		} else {
	        locate( zoomRect );
	    }
	}

}