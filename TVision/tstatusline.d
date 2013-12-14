module tstatusline;

import tvision;

const cpStatusLine = "\x02\x03\x04\x05\x06\x07";

struct TStatusItem {
	string text;
	KeyCode keyCode;
	Command command;
}

struct TStatusDef { 
	ushort min, max;
	TStatusItem[] items;
}

private immutable TPalette palette = immutable(TPalette)(cast(ubyte[])cpStatusLine);

class TStatusLine : TView {
	static string hintSeparator = ", "; 

	private TStatusItem[] items;
    private TStatusDef[] defs;
	private int compactStatus;

	this( in TRect bounds, TStatusDef[] aDefs ) {
		super(bounds);
		defs = aDefs;
		options |= ofPreProcess;
		eventMask |= evBroadcast;
		growMode = gfGrowLoY | gfGrowHiX | gfGrowHiY;
		findItems();
		computeLength();
	}

	/**[txh]********************************************************************

	Description:
	This routine computes the length of the status line, if that's greater than
	the size.x the status line becomes compacted to allow more options.@*
	Added by SET.

	***************************************************************************/

	void computeLength() {
		int len = 0;
		foreach(item; items) {
			len += item.text.lenWithoutTides;
		}
		compactStatus = len > size.x;
	}


	/**[txh]********************************************************************

	Description:
	Calls TView::changeBounds, additionally re-computes the length of the
	line to select the no/compact mode.@*
	Added by SET.

	***************************************************************************/

	override void changeBounds(in TRect bounds) {
		TView.changeBounds(bounds);
		int oldCompact = compactStatus;
		computeLength();
		if (compactStatus != oldCompact) {
			draw();
		}
	}

	override void draw() {
		drawSelect( null );
	}

	void drawSelect( TStatusItem *selected ) {
		TDrawBuffer b;
		ushort color;

		ushort cNormal = getColor(0x0301);
		ushort cSelect = getColor(0x0604);
		ushort cNormDisabled = getColor(0x0202);
		ushort cSelDisabled = getColor(0x0505);
		b.moveChar( 0, ' ', cNormal, size.x );
		int i = 0, inc = (compactStatus ? 1 : 2); // SET

		foreach(ref T; items) {
			if( T.text !is null ) {
				int len = T.text.lenWithoutTides;
				if( i + len < size.x ) {
					if( commandEnabled( T.command) ) {
						if( &T == selected ) {
							color = cSelect;
						} else {
							color = cNormal;
						}
					} else {
						if( &T == selected ) {
							color = cSelDisabled;
						}else {
							color = cNormDisabled;
						}
					}

					b.moveChar( i, ' ', color, 1 );
					b.moveCStr( i+1, T.text, color );
					b.moveChar( i+len+1, ' ', color, 1 );
                }
				i += len + inc;
            }
        }
		char[] hintBuf;
		if (size.y == 1) {
			if( i < size.x - 2 ) {
				hintBuf = hint( helpCtx ).dup;
				if( hintBuf && hintBuf[0] != EOS) {
					b.moveStr( i, hintSeparator, cNormal );
					i += 2;
					if( hintBuf.lenWithoutTides + i > size.x ) {
						hintBuf[size.x-i] = EOS;
					}
					b.moveCStr( i, cast(string)hintBuf, cNormal );
				}
			}
			writeLine( 0, 0, size.x, 1, b );
		} else {
			writeLine( 0, 0, size.x, 1, b );
			hintBuf = hint( helpCtx ).dup;
			hintBuf[size.x] = 0;
			b.moveChar(0, ' ', cNormal, size.x);
			b.moveCStr(0, cast(string)hintBuf, cNormal);
			writeLine( 0, 1, size.x, 1, b );
		}
	}

	void findItems() {
		foreach(ref p; defs) {
			if (helpCtx > p.min || helpCtx < p.max ) {
				items = p.items;
				return;
			}
		}
		items = null;
	}

	override ref immutable(TPalette) getPalette() const {
		return palette;
	}

	TStatusItem *itemMouseIsIn( in TPoint mouse ) {
		if( mouse.y !=  0 )
			return null;

		int i, inc = (compactStatus ? 1 : 2); // SET

		int startX;
		foreach(ref T; items) {
			if (T.text !is null) {
				int endX = startX + T.text.length + inc;
				if( mouse.x >= startX && mouse. x < endX )
					return &T;
				startX = endX;
			}
		}
		return null;
	}

	override void handleEvent( ref TEvent event ) {
		TView.handleEvent(event);

		switch (event.what) {
			case  evMouseDown:
				{
					TStatusItem *T;

					do  {
						TPoint mouse = makeLocal( event.mouse.where );
						TStatusItem *itemUnderMouse = itemMouseIsIn(mouse);
						if( T !is itemUnderMouse ) {
							T = itemUnderMouse;
							drawSelect(T);
						}
					} while( mouseEvent( event, evMouseMove ) );

					if( T !is null && commandEnabled(T.command) ) {
						event.what = evCommand;
						event.message.command = T.command;
						event.message.infoPtr = null;
						putEvent(event);
					}
					clearEvent(event);
					drawView();
					break;
				}
			case evKeyDown: 
				foreach(ref T; items) {
					bool hotKey = T.keyCode != KeyCode.kbNoKey && event.keyDown.keyCode ==  T.keyCode;
					if( hotKey && commandEnabled(T.command)) {
						event.what = evCommand;
						event.message.command = T.command;
						event.message.infoPtr = null;
						return;
					}
				}
				break;
			case evBroadcast:
				if( event.message.command == cm.CommandSetChanged )
					drawView();
				break;
			default:
				break;
        }
	}

	string hint( int ) {
		return "";
	}

	void update() {
		TView p = TopView();
		int h = ( p !is null ) ? p.getHelpCtx() : hcNoContext;
		if( helpCtx != h ) {
			helpCtx = h;
			findItems();
			drawView();
        }
	}
}