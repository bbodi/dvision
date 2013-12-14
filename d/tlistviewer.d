module tlistviewer;

import tvision;

private wchar columnSeparator = 0x179;
private immutable ubyte[] cpListViewer = [0x1A, 0x1A, 0x1B, 0x1C, 0x1D];
private immutable TPalette palette = immutable(TPalette)( cpListViewer);

class TListViewer : TView {

	static uint extraOptions = ofBeVerbose;

	bool center;
	TScrollBar hScrollBar;
    TScrollBar vScrollBar;
    int numCols;
    ccIndex topItem;
    ccIndex focused;
    ccIndex range;
    bool handleSpace;

    uint getExtraOptions() { return extraOptions; }
    void setExtraOptions(uint ops) { extraOptions=ops; }

    this(in TRect bounds, int aNumCols, TScrollBar aHScrollBar, TScrollBar aVScrollBar) {
    	super(bounds);
    	handleSpace = true;
    	options |= ofFirstClick | ofSelectable | extraOptions;
	    eventMask |= evBroadcast;

	    hScrollBar = aHScrollBar;
	    vScrollBar = aVScrollBar;
	    center = false;
	    setNumCols(aNumCols);
    }

    protected final void setNumCols(int aNumCols) {
		int arStep,pgStep;

		numCols=aNumCols;
		// Compute the scroll bar changes.
		if (vScrollBar !is null) {
	    	if (numCols == 1) {
	       		pgStep = size.y-1;
	       		arStep = 1;
			} else {
				pgStep = size.y*numCols;
				arStep = size.y;
			}
			vScrollBar.setStep(pgStep,arStep);
		}
		if (hScrollBar)
	    	hScrollBar.setStep(size.x/numCols,1);
	}

	override void changeBounds( in TRect bounds ) {
	    TView.changeBounds( bounds );
	    if( hScrollBar !is null )
	        hScrollBar.setStep( size.x / numCols, 1 );
	}

	override void draw() {
		ushort  focusedColor=0;
		TDrawBuffer b;
		ubyte scOff;

		int normalColor, selectedColor;
		if( (state&(sfSelected | sfActive)) == (sfSelected | sfActive)) {
	        normalColor = getColor(1);
	        focusedColor = getColor(3);
	        selectedColor = getColor(4);
		} else {
			normalColor = getColor(2);
	        selectedColor = getColor(4);
		}

		int indent = hScrollBar !is null ? hScrollBar.value : 0;

		int color;
	    int colWidth = size.x / numCols + 1;
	    for( int i = 0; i < size.y; i++ ) {
	        for( int j = 0; j < numCols; j++ ) {
	            int width;
	            ccIndex item =  j * size.y + i + topItem;
	            int curCol = j * colWidth;
	            if (j == numCols-1) 
	            	width = size.x - curCol + 1; 
	            else 
	            	width = colWidth;
	            if( (state & (sfSelected | sfActive)) == (sfSelected | sfActive) &&
	                focused == item &&
	                range > 0) {
	                color = focusedColor;
	                setCursor( curCol + 1, i );
	                scOff = 0;
				} else if( item < range && isSelected(item) ) {
	                color = selectedColor;
	                scOff = 2;
				} else {
	                color = normalColor;
	                scOff = 4;
				}

	            b.moveChar( curCol, ' ', color, width );
	            drawLine(color, item, b, curCol, width, indent, scOff);

	            // It was a really nasty thing, this call used 179 instead of
	            // a configurable value like now.
	           b.moveChar( curCol+width-1, columnSeparator, getColor(5), 1 );
			}
	        writeLine( 0, i, size.x, 1, b );
		}
	}

	void drawLine(int color, int item, ref TDrawBuffer b, int curCol, int width, int indent, int scOff) {
		if( item < range && item != -1 ) {
			string text = getText( item );
			int to = indent + min(width, text.length);
			string buf = text.length <= indent ? "" : text[indent..to];
			b.moveStr( curCol+1, buf, color );
			if( showMarkers ) {
				b.putChar( curCol, specialChars[scOff] );
				b.putChar( curCol+width-2, specialChars[scOff+1] );
			}
		} else {
			b.moveStr( curCol+1, _("<empty>"), getColor(1) );
		}
	}

	void focusItem( ccIndex item ) {
	    focused = item;

	    if( item < topItem ) {
	        if( numCols == 1 )
	            topItem = item;
	        else
	            topItem = item - item % size.y;
	    } else {
	        if( item >= topItem + size.y*numCols ) {
	            if( numCols == 1 )
	                topItem = item - size.y + 1;
	            else
	                topItem = item - item % size.y - (size.y * (numCols-1));
	        }
	    }
	    if( vScrollBar !is null )
	        vScrollBar.setValue( item );
	    else
	        drawView();
	    if (owner && (options & ofBeVerbose))
	       message(owner,evBroadcast,cm.ListItemFocused,this);
	}


	/**[txh]********************************************************************

	  Description:
	  That's a variant of focusItem that tries to center the focused item when
	the list have only one column.
	  
	***************************************************************************/

	void focusItemCentered( ccIndex item ) {
	    if( numCols != 1 ) {
	        focusItem( item );
	        return;
		}
	    center = true;
	    focused = item;

	    if( item < topItem ) {
	        topItem = item - size.y/2;
	        if( topItem < 0)
	            topItem = 0;
		} else {
	        if( item >= topItem + size.y*numCols ) {
	            topItem = item - size.y/2;
	            if( topItem + size.y >= range && range > size.y)
	                topItem = range - size.y;
			}
		}
	    if( vScrollBar !is null )
	        vScrollBar.setValue( item );
	    else
	        drawView();
	    if (owner && (options & ofBeVerbose))
	       message(owner,evBroadcast,cm.ListItemFocused,this);
	    center = false;
	}

	void focusItemNum( ccIndex item ) {
	    if( item < 0 )
	        item = 0;
	    else if( item >= range && range > 0 )
			item = range - 1;

	    if( range !=  0 ) {
	        if( center )
	            focusItemCentered( item );
	        else
	            focusItem( item );
		}
	}

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}

	string getText( ccIndex ) const {
	    return "";
	}

	bool isSelected( ccIndex item ) const {
	    return item == focused;
	}

	override void handleEvent( ref TEvent event ) {
	    int mouseAutosToSkip = 4;

	    TView.handleEvent(event);

	    if( event.what == evMouseDown ) {
	        // They must be before doubleClick to avoid "b4 double click"
	        if( event.mouse.buttons == mbButton4 ) {
	            focusItemNum(focused - size.y * numCols);
	            clearEvent( event );
	            return;
			}
	        if( event.mouse.buttons == mbButton5 ) {
				focusItemNum(focused + size.y * numCols);
	            clearEvent( event );
	            return;
			}
	        if( event.mouse.doubleClick && range > focused ) {
	            selectItem( focused );
	            clearEvent( event );
	            return;
			}
	        int colWidth = size.x / numCols + 1;
	        ccIndex oldItem =  focused;
	        TPoint mouse = makeLocal( event.mouse.where );
	        ccIndex newItem = mouse.y + (size.y * (mouse.x / colWidth)) + topItem;
	        int count = 0;
	        do  {
	            if( newItem != oldItem ) {
	                focusItemNum( newItem );
	            }
	            oldItem = newItem;
	            mouse = makeLocal( event.mouse.where );
	            if( mouseInView( event.mouse.where ) ) {
	                newItem = mouse.y + (size.y * (mouse.x / colWidth)) + topItem;
	            } else {
	                if( numCols == 1 ) {
	                    if( event.what == evMouseAuto )
	                        count++;
	                    if( count == mouseAutosToSkip ) {
	                        count = 0;
	                        if( mouse.y < 0 )
	                            newItem = focused - 1;
	                        else if( mouse.y >= size.y )
	                                newItem = focused + 1;
						}
					} else {
	                    if( event.what == evMouseAuto )
	                        count++;
	                    if( count == mouseAutosToSkip ) {
	                        count = 0;
	                        if( mouse.x < 0 )
	                            newItem = focused - size.y;
	                        else if( mouse.x >= size.x )
	                            newItem = focused + size.y;
	                        else if( mouse.y < 0 )
	                            newItem = focused - focused % size.y;
	                        else if( mouse.y > size.y )
	                            newItem = focused - focused % size.y + size.y - 1;
						}
					}
				}
			} while( mouseEvent( event, evMouseMove | evMouseAuto ) );
	        focusItemNum( newItem );
	        if( event.mouse.doubleClick && range > focused )
	            selectItem( focused );
	        clearEvent( event );
		} else if( event.what == evKeyDown ) {
			ccIndex newItem;
	        if ((handleSpace == true) &&
	            (event.keyDown.charScan.charCode ==  ' ') && focused < range ) {
	            selectItem( focused );
	            newItem = focused;
			} else {
	            switch (ctrlToArrow(event.keyDown.keyCode)) {
	                case KeyCode.kbUp:
	                    newItem = focused - 1;
	                    break;
	                case KeyCode.kbDown:
	                    newItem = focused + 1;
	                    break;
	                case KeyCode.kbRight:
	                    if( numCols > 1 )
	                        newItem = focused + size.y;
	                    else { // SET: if the user put a scroll bar with one column
	                          // that's what he wants
	                        if (hScrollBar) 
								hScrollBar.handleEvent(event);
	                        return;
						}
	                    break;
	                case KeyCode.kbLeft:
	                    if( numCols > 1 )
	                        newItem = focused - size.y;
	                    else { // SET: see KeyCode.kbRight
	                        if (hScrollBar) 
								hScrollBar.handleEvent(event);
	                        return;
	                    }
	                    break;
	                case KeyCode.kbPgDn:
	                    newItem = focused + size.y * numCols;
	                    break;
	                case  KeyCode.kbPgUp:
	                    newItem = focused - size.y * numCols;
	                    break;
	                case KeyCode.kbHome:
	                    newItem = topItem;
	                    break;
	                case KeyCode.kbEnd:
	                    newItem = topItem + (size.y * numCols) - 1;
	                    break;
	                case KeyCode.kbCtrlPgDn:
	                    newItem = range - 1;
	                    break;
	                case KeyCode.kbCtrlPgUp:
	                    newItem = 0;
	                    break;
	                default:
	                    return;
	            }
	            focusItemNum(newItem);
	        }
	        clearEvent(event);
	    } else if( event.what == evBroadcast ) {
	        if( (options & ofSelectable) != 0 ) {
	            if( event.message.command == cm.ScrollBarClicked &&
	                  ( cast(TView)event.message.infoPtr is hScrollBar || 
	                    cast(TView)event.message.infoPtr is vScrollBar ) ) {
	                select();
	            } else if( event.message.command == cm.ScrollBarChanged ) {
	                if( vScrollBar is cast(TView)event.message.infoPtr ) {
	                    focusItemNum( vScrollBar.value );
	                    drawView();
					} else if( hScrollBar is cast(TView)event.message.infoPtr )
	                    drawView();
				}
			}
		}
	}

	void selectItem( ccIndex ) {
	    message( owner, evBroadcast, cm.ListItemSelected, this );
	}

	void setRange( ccIndex aRange ) {
	    range = aRange;
	    if (focused >= aRange)
	       focused = (aRange - 1 >= 0) ? aRange - 1 : 0;
	    if( vScrollBar !is null ) {
	        vScrollBar.setParams( focused,
	                               0,
	                               aRange - 1,
	                               vScrollBar.pgStep,
	                               vScrollBar.arStep
	                             );
	        } 
	    else
	        drawView();
	}

	override void setState( ushort aState, bool enable) {
	    TView.setState( aState, enable );
	    if( (aState & (sfSelected | sfActive)) != 0 ) {
	        if( hScrollBar !is null ) {
	            if( getState(sfActive) )
	                hScrollBar.show();
	            else
	                hScrollBar.hide();
			}
	        if( vScrollBar !is null ) {
	            if( getState(sfActive) )
	                vScrollBar.show();
	            else
	                vScrollBar.hide();
			}
	        drawView();
		}
	}

	override void shutDown() {
	     hScrollBar = null;
	     vScrollBar = null;
	     TView.shutDown();
	}
}