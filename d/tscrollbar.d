module tscrollbar;

import tview;
import std.algorithm : max, min;

alias wchar[5] TScrollChars;

const ubyte[] cpScrollBar = cast(ubyte[])"\x04\x05\x05";

private TScrollChars vChars = [0x25B2, 0x25BC, ' ', '*', ' ']; 
private TScrollChars hChars = [0x2190, 0x2192, ' ', '*', ' '];

// Constants for the scroll bar components
private const int csbUp=0,
          csbDown=1,
          csbDark=2,
          csbMark=3,
          csbBright=4;

private immutable TPalette palette = immutable(TPalette)(cpScrollBar);

class TScrollBar : TView {

	int value;

    const TScrollChars chars;
    int minVal;
    int maxVal;
    int pgStep;
    int arStep;
    TPoint mouse;
	int p, s;
	TRect extent;

    this( in TRect bounds ) {
		pgStep = 1;
		arStep = 1;
		super(bounds);
	    if( size.x == 1 ) {
	        growMode = gfGrowLoX | gfGrowHiX | gfGrowHiY;
	        chars = vChars;
		} else {
	        growMode = gfGrowLoY | gfGrowHiX | gfGrowHiY;
	        chars = hChars;
		}
	    // This class can be "Braille friendly"
	    if (TScreen.getShowCursorEver()) {
	       state |= sfCursorVis;
		}
	}

	override void draw() {
	    drawPos(getPos());
	}

	void drawPos( int pos ) {
	    TDrawBuffer b;

	    int s = getSize() - 1;
	    b.moveChar( 0, chars[csbUp], getColor(2), 1 );
	    if( maxVal == minVal ) {
	        wchar unFilled = TScreen.avoidMoire ? TView.noMoireUnFill : chars[csbDark];
	        b.moveChar( 1, unFilled, getColor(1), s-1 );
		} else {
			wchar filled  = TScreen.avoidMoire ? TView.noMoireFill   : chars[csbBright];
	        b.moveChar( 1, filled, getColor(1), s-1 );
	        b.moveChar( pos, chars[csbMark], getColor(3), 1 );
	        if( state & sfFocused ) { 
	        	setCursor( pos , 0 );
	        	resetCursor();
	    	}
	    }

	    b.moveChar( s, chars[csbDown], getColor(2), 1 );
	    writeBuf( 0, 0, size.x, size.y, b );
	}

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}

	int getPos() {
	    int r = maxVal - minVal;
	    if( r == 0 ) {
			return 1;
	    } else {
			return  cast(int)(( ((cast(long)(value - minVal) * (getSize() - 3)) + (r >> 1)) / r) + 1);
		}
	}

	int getSize() {
	    int s;

	    if( size.x == 1 )
			s = size.y;
	    else
			s = size.x;

	    return max( 3, s );
	}

	int getPartCode() {
	    int part= - 1;
	    if( extent.contains(mouse) ) {
			int mark = (size.x == 1) ? mouse.y : mouse.x;

			if (mark == p)
			    part = sbIndicator;
			else {
			    if( mark < 1 )
					part = sbLeftArrow;
			    else if( mark < p )
					part= sbPageLeft;
			    else if( mark < s )
					part= sbPageRight;
			    else
					part= sbRightArrow;

			    if ( size.x == 1 )
					part += 4;
			}
		}
	    return part;
	}

	override void handleEvent( ref TEvent event ) {
	    bool Tracking;
	    int i=0, clickPart;

	    TView.handleEvent(event);
	    switch( event.what ) {
			case evMouseDown:
			    message(owner, evBroadcast, cm.ScrollBarClicked,this); // Clicked()
			    mouse = makeLocal( event.mouse.where );
			    extent = getExtent();
			    extent.grow(1, 1);
			    p = getPos();
			    s = getSize() - 1;
			    clickPart = getPartCode();
			    if( clickPart != sbIndicator ) {
					do  {
				    	mouse = makeLocal( event.mouse.where );
				    	if( getPartCode() == clickPart )
							setValue(value + scrollStep(clickPart) );
				    } while( mouseEvent(event, evMouseAuto) );
				} else {
					do  {
						mouse = makeLocal( event.mouse.where );
						Tracking = extent.contains(mouse);
						if( Tracking ) {
							if( size.x == 1 )
		                    	i = mouse.y;
		                    else
		                    	i = mouse.x;
		                    i = max( i, 1 );
		                    i = min( i, s-1 );
		                } else {
							i = getPos();
						}
						if(i != p ) {
							drawPos(i);
							p = i;
						}
					} while( mouseEvent(event,evMouseMove) );
					if( Tracking && s > 2 ) {
						s -= 2;
						setValue( cast(int)(((cast(long)(p - 1) * (maxVal - minVal) + (s >> 1)) / s) + minVal));
					}
				}
		        clearEvent(event);
		        break;
	        case  evKeyDown:
	            if( (state & sfVisible) != 0 ) {
	                clickPart = sbIndicator;
	                if( size.y == 1 ) {
	                    switch( ctrlToArrow(event.keyDown.keyCode) ) {
	                        case KeyCode.kbLeft:
	                            clickPart = sbLeftArrow;
	                            break;
	                        case KeyCode.kbRight:
	                            clickPart = sbRightArrow;
	                            break;
	                        case KeyCode.kbCtrlLeft:
	                            clickPart = sbPageLeft;
	                            break;
	                        case KeyCode.kbCtrlRight:
	                            clickPart = sbPageRight;
	                            break;
	                        case KeyCode.kbHome:
	                            i = minVal;
	                            break;
	                        case KeyCode.kbEnd:
	                            i = maxVal;
	                            break;
	                        default:
	                            return;
	                        }
	                } else {
	                    switch( ctrlToArrow(event.keyDown.keyCode) ) {
	                        case KeyCode.kbUp:
	                            clickPart = sbUpArrow;
	                            break;
	                        case KeyCode.kbDown:
	                            clickPart = sbDownArrow;
	                            break;
	                        case KeyCode.kbPgUp:
	                            clickPart = sbPageUp;
	                            break;
	                        case KeyCode.kbPgDn:
	                            clickPart = sbPageDown;
	                            break;
	                        case KeyCode.kbCtrlPgUp:
	                            i = minVal;
	                            break;
	                        case KeyCode.kbCtrlPgDn:
	                            i = maxVal;
	                            break;
	                        default:
	                            return;
						}
					}
	                message(owner,evBroadcast,cm.ScrollBarClicked,this); // Clicked
	                if( clickPart != sbIndicator )
	                    i = value + scrollStep(clickPart);
	                setValue(i);
	                clearEvent(event);
				}
				goto default;
		default: 
		break;
		}
	}

	void scrollDraw() {
	    message(owner, evBroadcast, cm.ScrollBarChanged,this);
	}

	int scrollStep( int part ) {
	    int  step;

	    if( !(part & 2) )
	        step = arStep;
	    else
	        step = pgStep;
	    if( !(part & 1) )
	        return -step;
	    else
	        return step;
	}

	void setParams( int aValue, int aMin, int aMax, int aPgStep, int aArStep ) {
	    int  sValue;

	    aMax = max( aMax, aMin );
	    aValue = max( aMin, aValue );
	    aValue = min( aMax, aValue );
	    sValue = value;
	    if( sValue != aValue || minVal != aMin || maxVal != aMax ) {
	        value = aValue;
	        minVal = aMin;
	        maxVal = aMax;
	        drawView();
	        if( sValue != aValue )
	            scrollDraw();
		}
	    pgStep = aPgStep;
	    arStep = aArStep;
	}

	void setRange( int aMin, int aMax ) {
	    setParams( value, aMin, aMax, pgStep, arStep );
	}

	void setStep( int aPgStep, int aArStep ) {
	    setParams( value, minVal, maxVal, aPgStep, aArStep );
	}

	void setValue( int aValue ) {
	    setParams( aValue, minVal, maxVal, pgStep, arStep );
	}
}
