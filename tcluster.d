module tcluster;

import std.uni;

import tvision;
import tview;
import tsitem;
import tstringcollection;

immutable ubyte[] cpCluster = [0x10, 0x11, 0x12, 0x12, 0x1F];
immutable TPalette palette = immutable(TPalette)( cpCluster);

class TCluster : TView {

	// SET: To report the movedTo and press as broadcasts, set it to 0 if you
	// don't like it.
	static uint extraOptions=ofBeVerbose;

    protected uint value;
    protected int sel;
    // SET: i18n cache
    //protected TStringCollectionCIntl *intlStrings;
    protected TStringCollection strings;

    this( in TRect bounds, TSItem *aStrings ) { 
		super(bounds);
		value = sel  = 0;
	    options |= ofSelectable | ofFirstClick | ofPreProcess | ofPostProcess |
	               extraOptions;
	    int stringCount = 0;
	    for( TSItem *p = aStrings; p != null; p = p.next )
	        stringCount++;

	    strings = new TStringCollection( stringCount, 0 );

	    while( aStrings != null ) {
	        strings.atInsert( strings.getCount(), aStrings.value );
	        aStrings = aStrings.next;
		}

	    setCursor( 2, 0 );
	    showCursor();
	}

	string getItemText( ccIndex item ) {
	    string key = strings.at( item );
	    return key;
	}

	override uint dataSize() {
	 // I have changed value from ushort to uint, but to be compatible
	 // I set dataSize to 2.
	 // SET: I added TRadioButtons32 and TCheckBox32
	 	return uint.sizeof;
	}

	void drawBox( string icon, wchar marker) {
	    TDrawBuffer b;
	    ushort color;

	    ushort cNorm = state & sfDisabled ? getColor( 0x0505 ) : getColor( 0x0301 );
	    ushort cSel = getColor( 0x0402 );
	    for( int i = 0; i <= size.y; i++ ) {
	        for( int j = 0; j <= (strings.getCount()-1)/size.y + 1; j++ ) {
	            int cur = j * size.y + i;
	            int col = column( cur );
	            if ( ( cur < strings.getCount() ) &&
	                (col+getItemText(cur).length+5 < maxViewWidth) &&
	                (col<size.x) ) {
	                if( (cur == sel) && (state & sfSelected) != 0 )
	                    color = cSel;
	                else
	                    color = cNorm;
	                b.moveChar( col, ' ', color, size.x - col );
	                b.moveCStr( col, icon, color );
	                if( mark(cur) )
	                    b.putChar( col+2, marker );
	                b.moveCStr( col+5, getItemText(cur), color );
	                if( showMarkers && (state & sfSelected) != 0 && cur == sel ) {
	                    b.putChar( col, specialChars[0] );
	                    b.putChar( column(cur+size.y)-1, specialChars[1] );
					}
				}
			}
	        writeBuf( 0, i, size.x, 1, b );
		}
	    setCursor( column(sel)+2, row(sel) );
	}

	override void getData(void * rec) {
		*(cast(ushort*)rec) = cast(ushort)value;
	    //memcpy(rec, &value, dataSize());
	}

	override int getHelpCtx() const {
	    if( helpCtx == hcNoContext )
	        return hcNoContext;
	    else
	        return helpCtx + sel;
	}

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}

	override void handleEvent( ref TEvent event ) {
	    TView.handleEvent(event);
	    if( event.what == evMouseDown ) {
	        TPoint mouse = makeLocal( event.mouse.where );
	        int i = findSel(mouse);
	        if( i != -1 )
	            sel = i;
	        drawView();
	        do  {
	            mouse = makeLocal( event.mouse.where );
	            if( findSel(mouse) == sel )
	                showCursor();
	            else
	                hideCursor();
			} while( mouseEvent(event,evMouseMove) );
	        showCursor();
	        mouse = makeLocal( event.mouse.where );
	        if( findSel(mouse) == sel ) {
	            press(sel);
	            drawView();
			}
	        clearEvent(event);
		} else if( event.what == evKeyDown )
	        switch (ctrlToArrow(event.keyDown.keyCode)) {
	            case KeyCode.kbUp:
	                if( (state & sfFocused) != 0 ) {
	                    if( --sel < 0 )
	                        sel = strings.getCount()-1;
	                    movedTo(sel);
	                    drawView();
	                    clearEvent(event);
					}
	                break;

	            case KeyCode.kbDown:
	                if( (state & sfFocused) != 0 ) {
	                    if( ++sel >= strings.getCount() )
	                        sel = 0;
	                    movedTo(sel);
	                    drawView();
	                    clearEvent(event);
					}
	                break;
	            case KeyCode.kbRight:
	                if( (state & sfFocused) != 0 ) {
	                    sel += size.y;
	                    if( sel >= strings.getCount() ) {
	                        sel = (sel +  1) % size.y;
	                        if( sel >= strings.getCount() )
	                            sel =  0;
						}
	                    movedTo(sel);
	                    drawView();
	                    clearEvent(event);
					}
	                break;
	            case KeyCode.kbLeft:
	                if( (state & sfFocused) != 0 ) {
	                    if( sel > 0 ) {
	                        sel -= size.y;
	                        if( sel < 0 ) {
	                            sel = ((strings.getCount()+size.y-1) /size.y)*size.y + sel - 1;
	                            if( sel >= strings.getCount() )
	                                sel = strings.getCount()-1;
							}
						} else
	                        sel = strings.getCount()-1;
	                    movedTo(sel);
	                    drawView();
	                    clearEvent(event);
					}
	                break;
	            default:
	                for( int i = 0; i < strings.getCount(); i++ ) {
	                    char c = hotKey( getItemText(i) );
	                    if( TGKey.GetAltCode(c) == event.keyDown.keyCode ||
	                        ( ( owner.phase == phaseType.phPostProcess ||
	                            (state & sfFocused) != 0
	                          ) &&
	                          c != 0 &&
	                          CompareUpperASCII(event.keyDown.charScan.charCode, c)
	                        )
	                      ) {
	                        select();
	                        sel =  i;
	                        movedTo(sel);
	                        press(sel);
	                        drawView();
	                        clearEvent(event);
	                        return;
						}
					}
	                if( event.keyDown.charScan.charCode == ' ' &&
	                    (state & sfFocused) != 0
	                  ) {
	                    press(sel);
	                    drawView();
	                    clearEvent(event);
					}
			}
	}

	override void setData(void * rec) {
		value = *(cast(ushort*)rec);
	    //memcpy(&value,rec,dataSize());
	    drawView();
	}

	override void setState( ushort aState, bool enable ) {
	    TView.setState( aState, enable );
	    if( aState == sfSelected || aState == sfDisabled )
	        drawView();
	}

	bool mark( int ) {
	    return false;
	}

	void movedTo( int /*item*/ ) {
	 if (owner && (options & ofBeVerbose))
	    message(owner,evBroadcast,cm.ClusterMovedTo,this);
	}

	void press( int /*item*/ ) {
	 if (owner && (options & ofBeVerbose))
	    message(owner,evBroadcast,cm.ClusterPress,this);
	}

   private int column( int item ) {
		if( item < size.y ) {
	        return 0;
	    } else {
	        int width = 0;
	        int col = -6;
	        int l = 0;
	        for( int i = 0; i <= item; i++ ) {
	            if( i % size.y == 0 ) {
	                col += width + 6;
	                width = 0;
				}

	            if( i < strings.getCount() )
	                l = getItemText(i).length;
	            if( l > width )
	                width = l;
			}
	        return col;
		}
	}

	private int findSel( TPoint p ) {
	    TRect r = getExtent();
	    if( !r.contains(p) ) {
	        return -1;
	    } else  {
	        int i = 0;
	        while( p.x >= column( i + size.y ) )
	            i += size.y;
	        int s = i + p.y;
	        if( s >= strings.getCount() )
	            return -1;
	        else
	            return s;
		}
	}

	private int row( int item ) {
	    return item % size.y;
	}


}