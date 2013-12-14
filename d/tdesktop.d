module tdesktop;

import std.math;

import tgroup;
import tscreen;
import tview;
import trect;
import tevent;
import tbackground;
import tpoint;

class TDesktop : TGroup {

	static char defaultBkgrnd = '\xB0';
	static char odefaultBkgrnd = '\xB0';
	static short cascadeNum;
	static TView lastView;

	const dsktTileVertical=1, dsktTileHorizontal=0;

	private TBackground background;
	private uint flagsOptions;

	this(in TRect bounds ) {
		super(bounds);
		growMode = gfGrowHiX | gfGrowHiY;
		
		TScreen.setCursorPos( bounds.a.x , bounds.b.y );
		background = createBackground(getExtent());
		if (background !is null) {
			insert(background);
		}
	}

	TBackground createBackground(in TRect r) const {
		return new TBackground( r, defaultBkgrnd );
	}

	override void shutDown() {
		background = null;
		TGroup.shutDown();
	}

	static bool Tileable( in TView p ) {
		return (p.options & ofTileable) != 0 && (p.state & sfVisible) != 0 ;
	}

	void cascade( in TRect r ) {
		TPoint min, max;
		cascadeNum = 0;
		forEach( &doCount, null );
		if( cascadeNum > 0 ) {
			lastView.sizeLimits( min, max );
			if( (min.x > r.b.x - r.a.x - cascadeNum) || 
			   (min.y > r.b.y - r.a.y - cascadeNum) )
				tileError();
			else {
				cascadeNum--;
				lock();
				forEach( &doCascade, cast(void *)&r );
				unlock();
			}
		}
	}

	static private void doCount( TView p, void * ) {
		if( Tileable( p ) ) {
			cascadeNum++;
			lastView = p;
		}
	}
	
	static private void doCascade( TView p, void *r ) {
		if( Tileable( p ) && cascadeNum >= 0 ) {
			TRect NR = *cast(TRect *)r;
			NR.a.x += cascadeNum;
			NR.a.y += cascadeNum;
			p.locate( NR );
			cascadeNum--;
		}
	}

	override void handleEvent(ref TEvent event) {
		if( (event.what == evBroadcast) && (event.message.command == cm.ReleasedFocus) ) {
			// SET: Move the cursor away, hopefully we will have a status bar.
			// Helps Braille Terminals to know the object lost the focus. 
			TScreen.setCursorPos( origin.x , origin.y + size.y );
		}
		TGroup.handleEvent( event );
		if( event.what == evBroadcast && event.message.command == cm.UpdateCodePage &&
		   background ) { {

				//background.changePattern(TVCodePage.RemapChar(TDesktop.odefaultBkgrnd, (cast(ushort*)event.message.infoPtr)[0..256]));
		   }
		}
		
		if( event.what == evCommand ) {
			if (event.message.command == cm.Next) {
				if (valid(cm.ReleasedFocus))
					selectNext( false );
			} else if (event.message.command == cm.Prev) {
				if (valid(cm.ReleasedFocus))
					current.putInFrontOf( background );
			} else {
				return;
			}
			clearEvent( event );
		}
	}

	uint getOptions() { return flagsOptions; }
	void setOptions(uint aFlags) { flagsOptions=aFlags; }
	
	void tile( in TRect r ) {
		numTileable =  0;
		forEach( &doCountTileable, null );
		if( numTileable > 0 ) {
			// SET: This trick makes the partitions in the reverse order
			if( getOptions() & dsktTileVertical )
				mostEqualDivisors( numTileable, numRows, numCols );
			else
				mostEqualDivisors( numTileable, numCols, numRows );
			if( ( (r.b.x - r.a.x)/numCols ==  0 ) || 
			   ( (r.b.y - r.a.y)/numRows ==  0) )
				tileError();
			else
			{
				leftOver = numTileable % numCols;
				tileNum = numTileable - 1;
				lock();
				forEach( &doTile, cast(void *)&r );
				unlock();
			}
		}
	}
	
	void  tileError() {
	}
	
	// SET: TViews will ask us if that's good time to draw cursor changes
	override bool canShowCursor() const {
		return lockFlag ? false : true;
	}
	
	// SET: If nobody will recover the focus move the cursor to the status line
	override Command execView( TView p ) {
		Command ret = TGroup.execView(p);
		if (p && !current)
			TScreen.setCursorPos(0, TScreen.screenHeight-1);
		return ret;
	}

	private static uint iSqr( uint i ) {
		uint res1 = 2;
		uint res2 = i/res1;
		while( abs( res1 - res2 ) > 1 ) {
			res1 = (res1 + res2)/2;
			res2 = i/res1;
		}
		return res1 < res2 ? res1 : res2;
	}


	private static void mostEqualDivisors(int n, out int x, out int y) {
		int i = iSqr( n );
		if( n % i != 0 ) {
			if( n % (i+1) == 0 ) {
				i++;
			}
		}
		if( i < (n/i) ) {
			i = n/i;
		}
		
		x = n/i;
		y = i;
	}
	
	// SET: All to ints, they are the best type for any compiler
	static int numCols, numRows, numTileable, leftOver, tileNum;
	
	private static void doCountTileable( TView p, void * ) {
		if( Tileable( p ) )
			numTileable++;
	}
	
	private static int dividerLoc( int lo, int hi, int num, int pos) {
		return cast(int)(cast(long)(hi-lo)*pos/cast(long)(num)+lo);
	}
	
	private static TRect calcTileRect( int pos, in TRect r ) {
		int x, y;
		TRect nRect;
		
		int d = (numCols - leftOver) * numRows;
		if( pos <  d ) {
			x = pos / numRows;
			y = pos % numRows;
		} else {
			x = (pos-d)/(numRows+1) + (numCols-leftOver);
			y = (pos-d)%(numRows+1);
		}
		nRect.a.x = dividerLoc( r.a.x, r.b.x, numCols, x );
		nRect.b.x = dividerLoc( r.a.x, r.b.x, numCols, x+1 );
		if( pos >= d ) {
			nRect.a.y = dividerLoc(r.a.y, r.b.y, numRows+1, y);
			nRect.b.y = dividerLoc(r.a.y, r.b.y, numRows+1, y+1);
		}
		else {
			nRect.a.y = dividerLoc(r.a.y, r.b.y, numRows, y);
			nRect.b.y = dividerLoc(r.a.y, r.b.y, numRows, y+1);
		}
		return nRect;
	}
	
	private static void doTile( TView p, void *lR )
	{
		if( Tileable( p ) ) {
			TRect r = calcTileRect( tileNum, *cast(const TRect *)lR );
			p.locate(r);
			tileNum--;
		}
	}
}