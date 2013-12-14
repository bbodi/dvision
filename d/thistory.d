module thistory;

import std.algorithm;

import tvision;

private immutable ubyte[] cpHistory = [0x16, 0x17];
private immutable string icon = "a~b~c";
private immutable TPalette palette = immutable(TPalette)(cpHistory);

class THistory : TView {

	private TInputLine link;
    private HistoryId historyId;

	this( in TRect bounds, TInputLine aLink, HistoryId aHistoryId) {
	    super(bounds);
	    link = aLink;
	    historyId = aHistoryId;
	    options |= ofPostProcess;
	    eventMask |= evBroadcast;
	}

	override void shutDown() {
	    link = null;
	    TView.shutDown();
	}

	override void draw() {
	    TDrawBuffer b;

	    b.moveCStr( 0, icon, getColor(0x0102) );
	    writeLine( 0, 0, size.x, size.y, b );
	}

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}

	override void handleEvent( ref TEvent event ) {
	    TView.handleEvent( event );
	    if( event.what == evMouseDown ||
	          ( event.what == evKeyDown &&
	            ctrlToArrow( event.keyDown.keyCode ) ==  KeyCode.kbDown &&
	            (link.state & sfFocused) != 0
	          )
	      )
	        {
	        link.select();
	        //historyAdd( historyId, link.getData() );
	        TRect r = link.getBounds();
	        r.a.x--;
	        r.b.x++;
	        r.b.y += 7;
	        r.a.y--;
	        TRect p = owner.getExtent();
	        r.intersect( p );
	        r.b.y--;
	        THistoryWindow historyWindow = initHistoryWindow( r );
	        if( historyWindow !is null ) {
	            Command c = owner.execView( historyWindow );
	            if( c == cm.Ok ) {
	                string rslt = historyWindow.getSelection();
	                link.setDataFromStr( rslt );
	                link.selectAll( Select.All );
	                link.drawView();
	            }
	            CLY_destroy( historyWindow );
			}
	        clearEvent( event );
		} else if( event.what == evBroadcast ) {
			bool linkLostItsFocus = (event.message.command == cm.ReleasedFocus &&
									 cast(TView)event.message.infoPtr is link);
			if( linkLostItsFocus || event.message.command ==  cm.RecordHistory )
				historyAdd( historyId, link.getData() );
		}
	}

	THistoryWindow initHistoryWindow( in TRect bounds ) const {
	    THistoryWindow p = new THistoryWindow( bounds, historyId );
	    p.helpCtx = link.helpCtx;
	    return p;
	}

}

private const MaxHistories = 256;

alias int HistoryId;
private string[][HistoryId] histories;

void initHistory() {
}

void clearHistory() {
}

private string firstItem(HistoryId id) {
	auto arrPtr = id in histories;
	if (arrPtr != null) {
		return (*arrPtr)[0];
	}
	return null;
}

void historyAdd( HistoryId id, string str ) {
	if (str.length == 0) {
		return;
	}
	if (str == firstItem(id)) {
		return;
	}
    insertString( id, str );
}

void insertString( HistoryId id, string str ) {
	if (id !in histories) {
		histories[id] = new string[0];
	}
	string[] strArr = histories[id];
	int len = min(MaxHistories, strArr.length);
	histories[id] = str ~ strArr[0..len];
}

uint historyCount( HistoryId id ) {
	auto arrPtr = id in histories;
	if (arrPtr != null) {
		return (*arrPtr).length;
	}
	return 0;
}

string historyStr( HistoryId id, int index ) {
	return histories[id][index];
}