module tlistbox;

import tvision;

import std.algorithm;

// TODO: T hasMethod toString
class TListBox(T) : TListViewer { 

	protected T[] items;

	struct TListBoxRec {
	    T[] items;
	    ccIndex selection;
	};

	this(in TRect bounds, ushort aNumCols, TScrollBar aScrollBar) {
		this(bounds, aNumCols, null, aScrollBar);
	}

	this( in TRect bounds,
                    ushort aNumCols,
                    TScrollBar aHScrollBar,
                    TScrollBar aVScrollBar,
                    bool aCenterOps = false)  {
		super(bounds, aNumCols, aHScrollBar, aVScrollBar);
	    setRange(0);
	    center = aCenterOps;
	}

	int search(in string key) {
		//return countUntil!("startsWith(toString(a), b)")(items, key);
		foreach(i, T item; items) {
			if (getText(i).startsWith(key)) {
				return i;
			}
		}
		return -1;
	}

	override uint dataSize() {
	    return TListBoxRec.sizeof;
	}

	override void getData( void * rec ) {
	    TListBoxRec *p = cast(TListBoxRec *)rec;
	    p.items = items;
	    p.selection = items == null && items.length == 0 ? -1 : focused;
	}

	override string getText( ccIndex item ) const {
		static enum conversionFunctionName = T.stringof ~ "ToString";
		//static assert(__traits(compiles, toStr(items[item])), "The type " ~ T.stringof ~ " must implement a string toStr(in "~T.stringof~") method!");
		//mixin("return " ~ conversionFunctionName ~ "(items[item]);");
		mixin("return items[item]." ~ conversionFunctionName ~ "();");
	}

	override void setData( void *rec ) {
	    TListBoxRec *p = cast(TListBoxRec *)rec;
	    newList( p.items );
		if (p.items != null && p.items.length > 0 && p.selection < 0) {
			p.selection = 0;
		}
	    if( center )
	        focusItemCentered( p.selection );
	    else
	        focusItem( p.selection );
	    drawView();
	}

	void newList( T[] aList ) {
	    items = aList;
	    if( aList !is null ) {
	        setRange( aList.count );
	    } else {
	        setRange(0);
	    }
	    if( range > 0 )
	        focusItem(0);
	    drawView();
	}
}