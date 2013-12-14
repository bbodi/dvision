module thistoryviewer;

import tvision;

class THistoryViewer : TListViewer {
	private HistoryId historyId;

	this( in TRect bounds, TScrollBar aHScrollBar, TScrollBar aVScrollBar, HistoryId aHistoryId) {
		super(bounds, 1, aHScrollBar, aVScrollBar);
		historyId = aHistoryId;
	    setRange( historyCount( aHistoryId ) );
	    if( range > 1 )
	        focusItem( 1 );
	    hScrollBar.setRange( 0, historyWidth() - size.x + 3 );
	}

	override ref immutable(TPalette) getPalette() const {
		mixin DefinePalette!([0x06, 0x06, 0x07, 0x06, 0x06]);
	    return myPalette;
	}

	override string getText( ccIndex item) const {
		return historyStr( historyId, item );
	}

	override void handleEvent( ref TEvent event ) {
	    if( (event.what == evMouseDown && event.mouse.doubleClick) ||
	        (event.what == evKeyDown && event.keyDown.keyCode == KeyCode.kbEnter)
	      ) {
	        endModal( cm.Ok );
	        clearEvent( event );
		} else if( (event.what ==  evKeyDown && event.keyDown.keyCode == KeyCode.kbEsc) ||
	            (event.what ==  evCommand && event.message.command ==  cm.Cancel)
	          ) {
	            endModal( cm.Cancel );
	            clearEvent( event );
		} else {
			TListViewer.handleEvent( event );
		}
	}

	private int historyWidth() {
	    int width = 0;
	    int count = historyCount( historyId );
	    for( int i = 0; i < count; i++ ) {
	        int T = historyStr( historyId, i ).length;
	        width = max( width, T );
		}
	    return width;
	}

}