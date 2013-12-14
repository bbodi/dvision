module tsortedlistbox;

import std.algorithm;
import std.uni;

import tvision;

class TSortedListBox(T) : TListBox!T {

	private ubyte shiftState;
	private int searchPos;

	this(in TRect bounds, ushort aNumCols, TScrollBar aScrollBar) {
		super(bounds, aNumCols, aScrollBar);
    	searchPos = ushort.max;
    	showCursor();
    	setCursor(1, 0);
	}

	this( in TRect bounds, ushort aNumCols, TScrollBar aHScrollBar, TScrollBar aVScrollBar, bool aCenterOps) {
		super(bounds, aNumCols, aHScrollBar, aVScrollBar, aCenterOps);
		searchPos = ushort.max;
	    showCursor();
    	setCursor(1, 0);
	}

	override void handleEvent(ref TEvent event) {
		byte shiftKeys = (event.keyDown.shiftState & 0xFF);
		string curString, newString;
	    void* k;
	    int value, oldPos;

	    int oldValue = focused;
	    TListBox!T.handleEvent( event );
	    if( oldValue != focused ) {
	        searchPos = ushort.max;
	    }
	    if (event.what == evBroadcast &&
	        event.message.command == cm.ListItemSelected &&
	        event.message.infoPtr is items.ptr) {
	      /* When the item was selected, reset the search feature */
			searchPos = ushort.max;
			clearEvent(event);
			return;
	    }
	    if( event.what == evKeyDown ) {
	        if( event.keyDown.keyCode != KeyCode.kbEnter &&
	            ( event.keyDown.charScan.charCode != 0 ||
	              event.keyDown.keyCode == KeyCode.kbBackSpace ) ) {
	            value = focused;
	            if( value < range )
	                curString = getText( value );
	            else
	                curString = "";
	            oldPos = searchPos;
	            if( event.keyDown.keyCode == KeyCode.kbBackSpace ) {
	                if( searchPos == ushort.max )
	                    return;
	                // SET: 1) Avoid accessing curString[USHRT_MAX], 2) Do in the right order
					curString = curString[0..$-1];
	                if( searchPos == ushort.max ) {
	                    shiftState = shiftKeys;
	                }
				} else if( (event.keyDown.charScan.charCode == '.') ) {
					int from = searchPos==ushort.max ? 0 : searchPos;
					int index = std.string.indexOf(curString[from..$], ".");
	                if( index != -1 ) {
	                   searchPos = index + from;
	                   if (oldPos == ushort.max) {
	                      oldPos = 0;
	                  }
					} else {
						if (searchPos == ushort.max) {
							searchPos = 0;
							curString = ".";
							oldPos = 0;
						}
					}
				} else {
	                searchPos++;
	                if( searchPos == 0 ) {
	                    shiftState = shiftKeys;
	                    oldPos = 0;
					}
					int to = min(searchPos, curString.length);
					curString = curString[0..to] ~ event.keyDown.charScan.charCode;
				}
	            value = search(curString);//list()->search( k, value );
	            if( value < range && value > -1) {
	                newString = getText(value);
					// TVision_equal( curString, newString, searchPos+1 )
	                if( newString.startsWith(curString) ) {
	                    if( value != oldValue ) {
	                        focusItem(value);
	                        setCursor( cursor.x+searchPos, cursor.y );
						} else {
	                        setCursor(cursor.x+(searchPos-oldPos), cursor.y );
	                    }
	                } else {
	                	searchPos = oldPos;
	                }
				} else
	                searchPos = oldPos;
	            if ( searchPos != oldPos || isAlpha( event.keyDown.charScan.charCode ) )
	                clearEvent(event);
	            }
	        }
	}

	void *getKey( string s ) {
	    return cast(void *)s.ptr;
	}

	override void newList( T[] aList ) {
	    TListBox!T.newList( aList );
	    searchPos = ushort.max;
	}
}