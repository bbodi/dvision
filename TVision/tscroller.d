module tscroller;

import tview;
import tscrollbar;

const ubyte[] cpScroller = cast(ubyte[])"\x06\x07";

private immutable TPalette palette = immutable(TPalette)( cpScroller);

class TScroller : TView {

	

	static int defaultWheelStep = 5;
	int wheelStep;

	protected ubyte drawLock;
    protected bool drawFlag;
    protected TScrollBar hScrollBar;
    protected TScrollBar vScrollBar;
    protected TPoint delta;
    protected TPoint limit;

	this( in ref TRect bounds, TScrollBar aHScrollBar, TScrollBar aVScrollBar) {
		super(bounds);
		drawLock = 0;
		drawFlag = false;
		hScrollBar = aHScrollBar;
		vScrollBar = aVScrollBar;
		delta.x = delta.y = limit.x = limit.y = 0;
		options |= ofSelectable;
		eventMask |= evBroadcast;
		wheelStep = defaultWheelStep;
		// This class can be "Braille friendly"
		if (TScreen.getShowCursorEver())
			state |= sfCursorVis;
	}

	override void shutDown() {
		hScrollBar = null;
		vScrollBar = null;
		TView.shutDown();
	}

	override void changeBounds( in TRect bounds ) {
		setBounds(bounds);
		drawLock++;
		setLimit(limit.x, limit.y);
		drawLock--;
		drawFlag = false;
		drawView();
	}

	private void checkDraw() {
		if( drawLock == 0 && drawFlag != false ) {
			drawFlag = false;
			drawView();
        }
	}

	override ref immutable(TPalette) getPalette() const {
		return palette;
	}

	override void handleEvent(ref TEvent event) {
		TView.handleEvent(event);

		if( event.what == evBroadcast &&
		   event.message.command == cm.ScrollBarChanged &&
		   ( cast(TScrollBar)event.message.infoPtr is hScrollBar ||
            cast(TScrollBar)event.message.infoPtr is vScrollBar )
		   )
			scrollDraw();
		else if( vScrollBar && event.what == evMouseWheel) {
			if( event.mouse.buttons == mbButton4 ) {
				vScrollBar.setValue( vScrollBar.value - wheelStep );
				clearEvent( event );
			} else if( event.mouse.buttons==mbButton5 ) {
				vScrollBar.setValue( vScrollBar.value + wheelStep );
				clearEvent( event );
			}
		}
	}

	void scrollDraw() {
		TPoint  d;

		if( hScrollBar !is null ) {
			d.x = hScrollBar.value;
		} else {
			d.x = 0; 
		}

		if( vScrollBar !is null )
			d.y = vScrollBar.value;
		else
			d.y = 0;

		if( d.x != delta.x || d.y != delta.y ) {
			setCursor( cursor.x + delta.x - d.x, cursor.y + delta.y - d.y );
			delta = d;
			if( drawLock != 0 )
				drawFlag = true;
			else
				drawView();
        }
	}

	void scrollTo( int x, int y ) {
		drawLock++;
		if( hScrollBar !is null )
			hScrollBar.setValue(x);
		if( vScrollBar !is null )
			vScrollBar.setValue(y);
		drawLock--;
		checkDraw();
	}

	void setLimit( int x, int y ) {
		limit.x = x;
		limit.y = y;
		drawLock++;
		if( hScrollBar !is null )
			hScrollBar.setParams( hScrollBar.value,
								  0,
								  x - size.x,
								  size.x,
								  1
								  );
		if( vScrollBar !is null )
			vScrollBar.setParams( vScrollBar.value,
								  0,
								  y - size.y,
								  size.y,
								  1
								  );
		drawLock--;
		checkDraw();
	}

	void showSBar( TScrollBar sBar ) {
		if( sBar !is null ) {
			if( getState(sfActive | sfSelected) != 0 ) {
				sBar.show();
			} else {
				sBar.hide();
			}
        }
	}

	override void setState( ushort aState, bool enable ) {
		TView.setState(aState, enable);
		if( (aState & (sfActive | sfSelected)) != 0 ) {
			showSBar(hScrollBar);
			showSBar(vScrollBar);
        }
	}

}