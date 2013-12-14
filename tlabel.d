module tlabel;

import std.uni;

import tvision;
import tstatictext;

private immutable ubyte[] cpLabel = [0x07, 0x08, 0x09, 0x09, 0x0D, 0x0D];
private immutable TPalette palette = immutable (TPalette)( cpLabel );

class TLabel : TStaticText {
	private TView link;
	private bool light;

	this( in TRect bounds, string aText, TView aLink) {
		super(bounds, aText);
		init( aLink );
	}

	this( int x, int y, string aText, TView aLink) {
		this(TRect(x, y, x, y), aText, aLink);
		growTo(aText.lenWithoutTides+1, 1); 
	}

	void init( TView aLink ) {
		link = aLink;
		light = false;
		options |= ofPreProcess | ofPostProcess;
		eventMask |= evBroadcast;
		// This class can be "Braille friendly"
		if (TScreen.getShowCursorEver())
			state |= sfCursorVis;
	}

	override void shutDown() {
		link = null;
		TStaticText.shutDown();
	}

	// SET: Now labels propagate the disabled state.
	override void setState( ushort aState, bool enable ) {
		TView.setState( aState, enable );
		if( aState == sfDisabled ) {
			link.setState( aState, enable );
			drawView();
		}
	}

	override void draw() {
		ushort color;
		ubyte scOff;

		if( state & sfDisabled ) {// SET: Now disabled labels shows it
			color = getColor(0x0605);
			scOff = 4;
		} else {
			if( light ) {
				color = getColor(0x0402);
				scOff = 0;
			} else {
				color = getColor(0x0301);
				scOff = 4;
			}
		}

		TDrawBuffer b;
		b.moveChar( 0, ' ', color, size.x );
		if( text !is null )	{
			b.moveCStr( 1, text, color );
			if( light ) {// Usually this will do nothing because the focus is in the linked
				// object
				setCursor( 1 , 0 );
				resetCursor();
			}
		}
		if( showMarkers )
			b.putChar( 0, specialChars[scOff] );
		writeLine( 0, 0, size.x, 1, b );
	}

	override ref immutable(TPalette) getPalette() const {
		return palette;
	}

	private bool validLink() {
		return link && (link.options & ofSelectable) &&
			!(link.state & sfDisabled);
	}

	override void handleEvent( ref TEvent event ) {
		TStaticText.handleEvent(event);
		if( event.what == evMouseDown ) {
			if( validLink() )
				link.select();
			clearEvent( event );
		} else if( event.what == evKeyDown ) {
			char c = hotKey( text );
			if( TGKey.GetAltCode(c) == event.keyDown.keyCode ||
			   ( c != 0 && owner.phase == phaseType.phPostProcess &&
				CompareUpperASCII(event.keyDown.charScan.charCode, c) )
			   )
			{
				if( validLink() )
					link.select();
				clearEvent( event );
			}
		} else if( event.what == evBroadcast &&
				( event.message.command == cm.ReceivedFocus ||
				 event.message.command == cm.ReleasedFocus )
				) {
			light = (link.state & sfFocused) != 0 ;
			drawView();
		}
	}

}