module thistorywindow;

import tvision;

private immutable ubyte[] cpHistoryWindow = [0x13, 0x13, 0x15, 0x18, 0x17, 0x13, 0x14];
private immutable TPalette myPalette = immutable(TPalette)( cpHistoryWindow );

class THistoryWindow : TWindow {
	private TListViewer viewer;

	this( in TRect bounds, HistoryId historyId ) {
		super(bounds, null, wnNoNumber);
	    flags = wfClose;
	    viewer = createListViewer( getExtent(), this, historyId );
	    if( viewer !is null )
	        insert( viewer );
	}

	override ref immutable(TPalette) getPalette() const {
	    return myPalette;
	}

	string getSelection() const {
		return viewer.getText( viewer.focused );
	}

	TListViewer createListViewer( TRect r, TWindow win, HistoryId historyId ) {
	    r.grow( -1, -1 );
	    return new THistoryViewer( r,
	        win.standardScrollBar( sbHorizontal | sbHandleKeyboard ),
	        win.standardScrollBar( sbVertical | sbHandleKeyboard ),
	        historyId);
	}
}