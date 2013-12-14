module tbackground;

import tview;
import trect;
import tdrawbuffer;
import tpalette;
import tscreen;
import tdesktop;

private const ubyte[] cpBackground = [1];//cast(ubyte[])"\x01";      // background palette
private immutable TPalette palette = immutable(TPalette)( cpBackground );

class TBackground : TView {

	private char pattern;

	this( const TRect bounds, char aPattern ) {
		super(bounds);
		pattern = aPattern;
		growMode = gfGrowHiX | gfGrowHiY;
	}

	void changePattern(char newP) { 
		pattern = newP; 
		draw(); 
	}

	wchar getPattern() {
		return pattern; 
	}

	override void draw() {
		TDrawBuffer b;
		
		wchar ch = pattern;
		if( TScreen.avoidMoire && ch == TDesktop.defaultBkgrnd )
			ch = TView.noMoireFill;
		b.moveChar( 0, ch, getColor(0x01), size.x );
		writeLine( 0, 0, size.x, size.y, b );
	}
	
	override ref immutable(TPalette) getPalette() const {
		return palette;
	}
}