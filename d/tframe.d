module tframe;

import tview;
import twindow;
import std.algorithm : max, min;
import std.conv;

private immutable ubyte[] cpFrame = [0x01, 0x01, 0x02, 0x02, 0x03];

private immutable TPalette palette = immutable(TPalette)(cpFrame);

private immutable ubyte[] initFrame =	// not active state
[6, 10, 12,
5, 0, 5,
3, 10, 9,
// active state
22, 26, 28,
21, 0, 21,
19, 26, 25];

class TFrame : TView {
	
	//[32, 0x250C, 0x2500,0x2510, // " ┌─┐"
	// 32, 32, 0x2514, 0x2500, 0x2518, 32, 32, // "  └─┘  "
	// 0x2502, 32, 0x2502, 32, 32, // "│ │ " 
	// 0x251C, 0x2500, 0x2524, 32]; // "├─┤ "
	private static immutable wstring frameChars = cast(wstring)[	32, 32, 32, 0x2514, 'a',
									0x2502, 0x250C, 0x251C, 0x251C, 0x2518, 
									0x2500, 'n', 0x2510, 0x251C, 0x252C, 
									0x251C, 'o', 0x251C, 'b', 0x2514, 
									0x2510, 0x2502, 0x250C, 0x251C, 'm', 
									0x2518, 0x2500, 32, 0x2510, 32, 
									0x252C, 0x252C, 32, 0x252C, 'k',
									0x251C, 'l', 0x251C, 'c', 32,
									0x252C, 'j', 0x251C, 'd', 0x251C,
									'g', 0x252C, 'h', 0x252C, 'e',
									 0x251C, 'f', 32];
//		"   À ³ÚÃ ÙÄÁ¿´ÂÅ   È ºÉÇ ¼ÍÏ»¶Ñ "; // for UnitedStates code page
	//static string oframeChars = "   À ³ÚÃ ÙÄÁ¿´ÂÅ   È ºÉÇ ¼ÍÏ»¶Ñ "; // for UnitedStates code page
	// þ  


	private static immutable wstring closeIcon = "[~x~]";
	private static immutable wstring zoomIcon = cast(wstring)['~', 0x2191, '~'];
	private static immutable wstring unZoomIcon = cast(wstring)['~', 0x2193, '~'];
	// Note: Eddie proposed 0xF (WHITE SUN WITH RAYS) but this reduces to * and
	// is the same as 0xFE (BLACK SQUARE) (also reduced to *).
	private static immutable wstring animIcon = "[~+~]";
	private static immutable wstring dragIcon = cast(wstring)['~', 0x2500, 0x2518, '~'];

	bool doAnimation = true;

	this(in TRect bounds) {
		super(bounds);
		growMode = gfGrowHiX + gfGrowHiY;
		eventMask |= evBroadcast | evMouseUp;
	}

	override void draw() {
		ushort cFrame, cTitle;
		int  frameCharOffset;

		if( (state & sfActive) == 0 ) {
			cFrame = 0x0101;
			cTitle = 0x0002;
			frameCharOffset = 0;
        } else {
			if( (state & sfDragging) != 0 ) {
				cFrame = 0x0505;
				cTitle = 0x0005;
				frameCharOffset = 0;
            } else {
				cFrame = 0x0503;
				cTitle = 0x0004;
				frameCharOffset = 9;
            }
		}

		cFrame = getColor(cFrame);
		cTitle = getColor(cTitle);

		int width = size.x;
		int l = width - 10;

		if( ( (cast(TWindow)owner).flags & (wfClose | wfZoom) ) != 0 ) {
			l -= 6;
		}
		TDrawBuffer b;
		frameLine( b, 0, frameCharOffset, cast(ubyte)cFrame );

		int winNumOffset;
		if( (cast(TWindow)owner).number != wnNoNumber ) {
			l -= 4;
			if( ( (cast(TWindow)owner).flags & wfZoom ) != 0 ) {
				winNumOffset = 7;
			} else {
				winNumOffset = 3;
			}
			int number = (cast(TWindow)owner).number;
			if (number > 10) winNumOffset++;
			if (number > 100) winNumOffset++;
			if (number > 1000) winNumOffset++;
			string Number = to!string(number);
			foreach(j, char ch; Number) {
				b.putChar( width-winNumOffset+j, ch);
			}
        }

		drawTitle(b, winNumOffset, l, cTitle);

		if( (state & sfActive) != 0 ) {
			if( ( (cast(TWindow)owner).flags & wfClose ) != 0 ) {
				b.moveCStr( 2, closeIcon, cFrame );
			}
			if( ( (cast(TWindow)owner).flags & wfZoom ) != 0 ) {
				TPoint minSize, maxSize;
				owner.sizeLimits( minSize, maxSize );
				if( owner.size == maxSize ) {
					b.moveCStr( width-5, unZoomIcon, cFrame );
				} else {
					b.moveCStr( width-5, zoomIcon, cFrame );
				}
            }
        }

		writeLine( 0, 0, size.x, 1, b );
		for( int i = 1; i <=  size.y - 2; i++ ) {
			frameLine( b, i, frameCharOffset +  3, cast(ubyte)cFrame );
			writeLine( 0, i, size.x, 1, b );
        }
		frameLine( b, size.y - 1, frameCharOffset +  6, cast(ubyte)cFrame );
		if( (state & sfActive) != 0 ) {
			if( ( (cast(TWindow)owner).flags & wfGrow ) != 0 ) {
				b.moveCStr( width-2, dragIcon, cFrame );
			}
		}
		writeLine( 0, size.y - 1, size.x, 1, b );
	}

	private void drawTitle(ref TDrawBuffer b, int winNumOffset, int l, ushort cTitle) const {
		if( owner !is null ) {
			string title = (cast(TWindow)owner).getTitle(winNumOffset);
			int width = size.x;
			if( title !is null ) {
				int maxLen = max( width - 10, 0);
				int titleLen = title.lenWithoutTides;
				if (titleLen > maxLen) {
					winNumOffset = (width - maxLen) >> 1;
					b.moveBuf( winNumOffset-1, " ..", cTitle, 3 );
					int from = min((titleLen - maxLen + 2), title.length);
					auto part = title[from..$];
					b.moveBuf( winNumOffset+2, part, cTitle, min(maxLen, part.length) );
					b.putChar( winNumOffset+maxLen, ' ' );
					b.putChar( winNumOffset+maxLen+1, ' ' );
				} else {
					maxLen = titleLen;
					winNumOffset = (width - maxLen) >> 1;
					b.putChar( winNumOffset-1, ' ' );
					b.moveBuf( winNumOffset, title, cTitle, maxLen );
					b.putChar( winNumOffset + maxLen, ' ' );
				}
            }
        }
	}

	char FrameMask[maxViewWidth];

	void frameLine( ref TDrawBuffer frameBuf, int y, int n, ubyte color ) {
		int si,ax,cx,dx,di;
		int i=1;
		TView view;
		cx = dx = size.x;
		cx -= 2;
		FrameMask[0] = initFrame[n];
		while (cx--) {
			FrameMask[i++] = initFrame[n+1];
		}
		FrameMask[i] = initFrame[n+2];
		view = owner.last;
		dx--;
	lab1:
		view = view.next;
		if (view is this) goto lab10;
		if (!(view.options & ofFramed)) goto lab1;
		if (!(view.state & sfVisible)) goto lab1;
		ax = y - view.origin.y;
		if (cast(short)(ax) < 0) 
			goto lab3;
		if (ax>view.size.y) goto lab1;
		if (ax<view.size.y) ax = 5;
		else ax = 0x0a03;
		goto lab4;
	lab3:
		ax++;
		if (ax) goto lab1;
		ax = 0x0a06;
	lab4:
		si = view.origin.x;
		di = si + view.size.x;
		if (si>1) goto lab5;
		si = 1;
	lab5:
		if (di<dx) goto lab6;
		di = dx;
	lab6:
		if (si>=di) goto lab1;
		FrameMask[si-1] |= (ax & 0x00ff);
		ax ^= (((ax & 0xff00) >> 8) & 0x00ff);
		FrameMask[di] |= (ax & 0x00ff);
		if (!(ax & 0xff00)) goto lab1;
		cx = di-si;
		while (cx--) FrameMask[si++] |= (((ax & 0xff00) >> 8) & 0x00ff);
		goto lab1;
	lab10:
		dx++;
		{
			wchar[] framechars = new wchar[dx]; //ubyte * framechars = (ubyte *)malloc(dx);
			for ( i = 0; i < dx; i++) {
				auto ch = cast(wchar)(frameChars[cast(uint)FrameMask[i]]);
				framechars[i] = ch;
			}
			frameBuf.moveBuf(0, framechars, color, dx);
		}
	}

	override ref immutable(TPalette) getPalette() const {
		return palette;
	}

	void dragWindow( ref TEvent event, ubyte mode ) {
		TRect  limits;
		TPoint min, max;

		limits = owner.owner.getExtent();
		owner.sizeLimits( min, max );
		owner.dragView( event, owner.dragMode | mode, limits, min, max );
		clearEvent( event );
	}

	const int ciClose=0, ciZoom=1;

	void drawIcon( int bNormal, const int ciType ) {
		ushort cFrame;

		if( (state & sfActive) == 0 ) {
			cFrame = 0x0101;
		} else {
			if( (state & sfDragging) != 0 ) {
				cFrame = 0x0505;
			} else {
				cFrame = 0x0503;
			}
		}

		cFrame = getColor(cFrame);

		switch( ciType ) {
			// Close icon
			case ciClose:
				{
					TDrawBuffer drawBuf;
					drawBuf.moveCStr( 0, bNormal ? closeIcon : animIcon, cFrame );
					writeLine( 2, 0, 3, 1, drawBuf );
				}
				break;
				// Zoom icon
				//case ciZoom:
			default:
				{
					TPoint minSize, maxSize;
					owner.sizeLimits( minSize, maxSize );

					TDrawBuffer drawBuf;
					drawBuf.moveCStr( 0, bNormal ? ( (owner.size == maxSize) ? unZoomIcon : zoomIcon ) : animIcon, cFrame );
					writeLine( size.x - 5, 0, 3, 1, drawBuf );
				}
				break;
        }
	}

	private bool mouseOverClose(in TPoint mouse) const {
		return mouse.y == 0 && mouse.x >= 2 && mouse.x <= 4;
	}

	private bool mouseOverZoom(in TPoint mouse) const {
		return mouse.y == 0 && ( mouse.x >= size.x - 5 ) && ( mouse.x <= size.x - 3 );
	}

	private bool mouseOverGrow(in TPoint mouse) const {
		return (mouse.x >= size.x - 2 ) && ( mouse.y >= size.y - 1);
	}

	override void handleEvent( ref TEvent event ) {
		TView.handleEvent(event);
		int ownerFlags = (cast(TWindow)owner).flags;
		// This version incorporates Eddie changes to "animate" the close and zoom icons.
		if( (event.what & (evMouseDown | evMouseUp)) && (state & sfActive) ) {
			TPoint mouse = makeLocal( event.mouse.where );
			if( mouse.y == 0 ) {   // Close icon
				if( ( ownerFlags & wfClose ) && mouseOverClose(mouse) ) {
					if( doAnimation ) {   // Animated version, capture the focus until the button is released
						do {
							mouse = makeLocal( event.mouse.where );
							drawIcon( !mouseOverClose(mouse), ciClose );
						} while( mouseEvent( event, evMouseMove ) );

						if( event.what == evMouseUp  && mouseOverClose(mouse) ) {
							createEvent( evCommand, cm.Close, owner );
							clearEvent( event );
							drawIcon( 1, ciClose );
						}
					}
					else {   // Not animated
						if( event.what == evMouseUp )
							createEvent( evCommand, cm.Close, owner );
						clearEvent( event );
					}
				} else {   // Double click on the upper line or zoom icon
					if ( event.mouse.doubleClick || ( ( ownerFlags & wfZoom ) && mouseOverZoom(mouse) ) ) {
						if ( event.mouse.doubleClick ) {
							createEvent( evCommand, cm.Zoom, owner );
							clearEvent( event );
						} else {
							if( doAnimation ) {   // Animated version, capture the focus until the button is released
								do {
									mouse = makeLocal( event.mouse.where );
									drawIcon( !mouseOverZoom(mouse), ciZoom );

								} while( mouseEvent( event, evMouseMove ) );

								if( ( event.what == evMouseUp ) && mouseOverZoom(mouse) ) {
									createEvent( evCommand, cm.Zoom, owner );
									clearEvent( event );
									drawIcon( 1, ciZoom );
								}
							} else {   // Not animated
								if( event.what == evMouseUp ) {
									createEvent( evCommand, cm.Zoom, owner );
								}
								clearEvent( event );
							}
						}
					} else {
						// Click on the upper line (move)
						if( (ownerFlags & wfMove) && (event.what & evMouseDown) )
							dragWindow( event, dmDragMove );
					}
				}
			} else if( (event.what & evMouseDown) && mouseOverGrow(mouse) ) {   // Click on the grow corner
				if( ownerFlags & wfGrow )
					dragWindow( event, dmDragGrow );
			}
		}
	}

	override void setState( ushort aState, bool enable ) {
		TView.setState( aState, enable );
		if( (aState & (sfActive | sfDragging)) != 0 )
			drawView();
	}
}