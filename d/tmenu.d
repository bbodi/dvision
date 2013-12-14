module tmenu;

import std.uni;
import std.string : indexOf;
import std.algorithm : max, canFind, min, count;

import tview;
import ttypes;

private const ubyte[] cpMenuView = cast(ubyte[])"\x02\x03\x04\x05\x06\x07";
private immutable TPalette palette = immutable TPalette( cpMenuView );

//" ÚÄ¿  ÀÄÙ  ³ ³  ÃÄ´ " 8
//static string frameChars =  " \332\304\277  \300\304\331  \263 \263  \303\304\264 ";
//static string oframeChars = " \332\304\277  \300\304\331  \263 \263  \303\304\264 ";
// ┌─┐  └─┘  │ │  ├─┤ 
private immutable wstring frameChars =  cast(wstring)[32, 0x250C, 0x2500,0x2510, // " ┌─┐"
32, 32, 0x2514, 0x2500, 0x2518, 32, 32, // "  └─┘  "
0x2502, 32, 0x2502, 32, 32, // "│ │ " 
0x251C, 0x2500, 0x2524, 32]; // "├─┤ "
private immutable char rightArrow = 16;

struct TMenu {

	private TMenuItem items;
    private TMenuItem defaults;

	this(TMenuItem itemList) {
		items = defaults = itemList;
	}

	this(TMenuItem itemList, TMenuItem defList) {
		items = itemList;
		defaults = defList;
	}

}

class TMenuItem {

	private string name;
    private Command command;
    private KeyCode keyCode;
    private int helpCtx;
   
   	private union {
    	string param;
        TMenu* subMenu;
	};
	private TMenuItem next;

	private bool disabled;

	this(string aName, Command aCommand, KeyCode aKeyCode, int aHelpCtx, string p = null, TMenuItem aNext = null ) {
	    this.name = aName;
	    this.command = aCommand;
	    this.disabled = !TView.commandEnabled(aCommand);
	    this.keyCode = aKeyCode;
	   	this.helpCtx = aHelpCtx;
	    this.param = p;
	    this.next = aNext;
	}

	this(string aName, KeyCode aKeyCode, TMenu *aSubMenu, int aHelpCtx) {
	    this.name = aName;
	    this.disabled = !TView.commandEnabled(command);
	    this.keyCode = aKeyCode;
	   	this.helpCtx = aHelpCtx;
	    this.subMenu = aSubMenu;
	}


	ref TMenuItem opBinary(string op)(in ref TMenuItem rhs) const if (op == "+") {
		TMenuItem result = this;
		result.append(rhs);
		return result;
	}

	void opOpAssign(string op)(in ref TPoint rhs) if (op == "+="){
		append(rhs);
	}

	static TMenuItem newLine() {
    	return new TMenuItem( null, cm.Null, KeyCode.kbNoKey, hcNoContext, null, null );
	}

	void append( TMenuItem aNext ) {
    	TMenuItem item = this;
    	for ( ; item.next; item = item.next ) {
    		item.next = aNext;
    	}
	}
}

abstract class TMenuView : TView {
	// SET: Looks like some users really likes the original behavior of
    // having 1 space around menu items. As it reduces the number of menues
    // we can have. I added a conditional way to control it. The code is in
    // TMenuBar, when you create a menu bar (or chanBounds it) the Bar
    // calculates the length of the items and if they are greater than size.x
    // enters in the compatMenu mode. "Norberto Alfredo Bensa (Beto)"
    // <norberto.bensa@abaconet.com.ar> sent me an uncoditional patch that I used
    // as base. This variable is 0 by default (TMenuView constructor)
    byte compactMenu;

    protected TMenuView parentMenu;
    protected TMenu *menu;
    protected TMenuItem current;

	this( in TRect bounds, TMenu *aMenu = null, TMenuView aParent = null) {
		super(bounds);
		parentMenu = aParent;
		menu = aMenu;
		eventMask |= evBroadcast;
	}

    void trackMouse( in TEvent e ) {
    	TPoint mouse = makeLocal( e.mouse.where );
    	for( current = menu.items; current !is null; current = current.next ) {
        	TRect r = getItemRect( current );
        	if( r.contains(mouse) ) {
            	return;
			}
        }
	}

	void nextItem() {
    	if( (current = current.next) is null ) {
        	current = menu.items;
		}
	}

	void prevItem() {
    	TMenuItem p;

    	if( (p = current) == menu.items) {
        	p = null;
		}

    	do  {
        	nextItem();
        } while( current.next != p );
	}

	void trackKey( bool findNext ) {
    	if( current is null )
        	return;

	    do  {
	        if( findNext )
	            nextItem();
	        else
	            prevItem();
	        } while( current.name is null );
	}

	bool mouseInOwner( ref TEvent e )
	{
	    if( parentMenu is null || parentMenu.size.y != 1 )
	        return false;
	    else {
	        TPoint mouse = parentMenu.makeLocal( e.mouse.where );
	        TRect r = parentMenu.getItemRect( parentMenu.current );
	        return r.contains( mouse );
		}
	}

	bool mouseInMenus( ref TEvent e )
	{
	    TMenuView p = parentMenu;
	    while( p !is null && !p.mouseInView(e.mouse.where) )
	        p = p.parentMenu;

	    return  p !is null;
	}

	TMenuView topMenu() {
	    TMenuView p = this;
	    while( p.parentMenu !is null )
	        p = p.parentMenu;
	    return p;
	}

	enum MenuAction { doNothing, doSelect, doReturn };

	override Command execute() {
	    bool    autoSelect = false;
	    char   ch;
	    int    withAlt;
	    Command result = cm.Null;
	    TMenuItem itemShown;
	    TMenuItem p;

	    this.current = menu.defaults ? menu.defaults : null;
		TEvent e;
		MenuAction action;
	    do  {
	        action = MenuAction.doNothing;
	        getEvent(e);
	        switch (e.what) {
	            case  evMouseDown:
	                if( mouseInView(e.mouse.where) || mouseInOwner(e) ) {
	                    trackMouse(e);
	                    if( size.y == 1 ) {
	                        autoSelect = true;
						}
					} else {
	                    action =  MenuAction.doReturn;
					}
	                break;
	            case  evMouseUp:
	                trackMouse(e);
	                if( mouseInOwner(e) ) {
	                    current = menu.defaults;
	                } else if( current !is null && current.name !is null ) {
	                    action = MenuAction.doSelect;
	                } else {
	                    action = MenuAction.doReturn;
					}
	                break;
	            case  evMouseMove:
	                if( e.mouse.buttons != 0 ) {
	                    trackMouse(e);
	                    if( !(mouseInView(e.mouse.where) || mouseInOwner(e)) && mouseInMenus(e) ) {
	                        action = MenuAction.doReturn;
						}
					}
	                break;
	            case  evKeyDown:
	                switch( ctrlToArrow(e.keyDown.keyCode) ) {
	                    case  KeyCode.kbUp:
	                    case  KeyCode.kbDown:
	                        if( size.y != 1 ) {
	                            trackKey(ctrlToArrow(e.keyDown.keyCode) == KeyCode.kbDown);
							} else if( e.keyDown.keyCode == KeyCode.kbDown ) {
	                            autoSelect =  true;
							}
	                        break;
	                    case  KeyCode.kbLeft:
	                    case  KeyCode.kbRight:
	                        if( parentMenu is null ) {
	                            trackKey(ctrlToArrow(e.keyDown.keyCode) == KeyCode.kbRight);
	                        } else {
	                            action =  MenuAction.doReturn;
							}
	                        break;
	                    case  KeyCode.kbHome:
	                    case  KeyCode.kbEnd:
	                        if( size.y != 1 ) {
	                            current = menu.items;
	                            if( e.keyDown.keyCode == KeyCode.kbEnd ) {
	                                trackKey(false);
								}
							}
	                        break;
	                    case  KeyCode.kbEnter:
	                        if( size.y == 1 ) {
	                            autoSelect =  true;
							}
	                        action = MenuAction.doSelect;
	                        break;
	                    case  KeyCode.kbEsc:
	                        action = MenuAction.doReturn;
	                        if( parentMenu is null || parentMenu.size.y != 1 ) {
	                            clearEvent(e);
							}
	                        break;
	                    default:
	                        TMenuView target = this;
	                        ch = TGKey.GetAltChar(e.keyDown.keyCode, e.keyDown.charScan.charCode);
	                        withAlt = e.keyDown.keyCode & (KeyCode.kbAltRCode | KeyCode.kbAltLCode);
	                        if( ch == 0 ) {
	                            ch = e.keyDown.charScan.charCode;
							}
	                        if( withAlt ) {// SET: Original behavior
	                            if( ch ) {
	                                target = topMenu();
								}
	                            p = target.findItem(ch);
	                        } else {
	                            p = target.findItem(ch);
	                            if( p is null ) {
	                                target = topMenu();
	                                p = target.findItem(ch);
	                            }
							}
	                        if( p is null ) {
	                            p = topMenu().hotKey(e.keyDown.keyCode);
	                            if( p !is null && commandEnabled(p.command) ) {
	                                result = p.command;
	                                action = MenuAction.doReturn;
								}
							} else if( target == this ) {
	                            if( size.y == 1 ) {
	                                autoSelect = true;
								}
	                            action = MenuAction.doSelect;
	                            current = p;
							} else if( parentMenu != target || parentMenu.current != p ) {
								action = MenuAction.doReturn;
							}
	                    }
	                break;
	            case  evCommand:
	                if( e.message.command == cm.Menu ) {
	                    autoSelect = false;
	                    if (parentMenu !is null ) {
	                        action = MenuAction.doReturn;
						}
					} else {
	                    action = MenuAction.doReturn;
					}
	                break;
				default:
						break;
	            }

	        if( itemShown !is current ) {
	            itemShown =  current;
	            drawView();
			}

	        if( (action == MenuAction.doSelect || (action == MenuAction.doNothing && autoSelect)) &&
	            current !is null &&
	            current.name !is null )  {
				if( current.command == cm.Null ) {
					if( (e.what & (evMouseDown | evMouseMove)) != 0 ) {
						putEvent(e);
					}
	                TRect r = getItemRect( current );
	                r.a.x = r.a.x + origin.x;
	                r.a.y = r.b.y + origin.y;
	                r.b = owner.size;
	                if( compactMenu && size.y == 1 ) {
						r.a.x--;
					}
	                TView target = topMenu().newSubView(r, current.subMenu, this);
	                result = owner.execView(target);
	                CLY_destroy( target );
				} else if( action == MenuAction.doSelect ) {
					result = current.command;
				}
			}

	        if( result != cm.Null && commandEnabled(result) ) {
	            action =  MenuAction.doReturn;
	            clearEvent(e);
			} else {
	            result = cm.Null; // 0
			}
		} while( action != MenuAction.doReturn );

	    if( e.what != evNothing && (parentMenu !is null || e.what == evCommand)) {
	            putEvent(e);
		}
	    if (current !is null) {
	        menu.defaults = current;
	        current = null;
	        drawView();
		}
	    return result;
	}

	TMenuItem findItem( dchar ch ) {
	    if( !ch ) return null;
	    //ch = TVCodePage.toUpper(ch);
		ch = toUpper(ch);
	    TMenuItem p = menu.items;
	    while( p !is null ) {
	        if( p.name !is null && !p.disabled ) {
				int index  = p.name.indexOf("~");
				bool shortcutPressed = index != -1 && toUpper(p.name[index+1]) == ch; // TGKey.CompareASCII(ch, TVCodePage.toUpper(p.name[index+1]))
	            if( shortcutPressed) {
	                return p;
				}
			}
			p =  p.next;
		}
	    return null;
	}

	TRect getItemRect( TMenuItem  ) {
	    return TRect( 0, 0, 0, 0 );
	}

	override int getHelpCtx() const {
		
		const(TMenuView) findFirstHelpContext(in TMenuView c) {
			if (c is null ||
				(c.current !is null &&
				 c.current.helpCtx != hcNoContext &&
					c.current.name !is null )
				) {
					return c;
				}
			return findFirstHelpContext(c.parentMenu);
		}
	    const TMenuView c = findFirstHelpContext(this);

	    if( c !is null )
	        return c.current.helpCtx;
	    else
	        return hcNoContext;
	}

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}

	bool updateMenu( TMenu *menu ) {
	    if (!menu) return false;
	    bool res = false;
	    for( TMenuItem p = menu.items; p !is null; p = p.next ) {
	        if( p.name !is null ) {
	            if( p.command == cm.Null ) {
	                if (updateMenu(p.subMenu) == true) {
	                    res = true;
					}
				} else {
	                bool commandState = commandEnabled(p.command);
	                if( p.disabled == commandState ) {
	                    p.disabled = !commandState;
	                    res = true;
					}
				}
			}
		}
	    return res;
	}

	void do_a_select( ref TEvent event ) {
	    putEvent( event );
	    event.message.command = owner.execView(this);
	    if( event.message.command != cm.Null && commandEnabled(event.message.command) ) {
	        event.what = evCommand;
	        event.message.infoPtr = cast(void*)0;
	        putEvent(event);
		}
	    clearEvent(event);
	}

	/**[txh]********************************************************************

	  Description:
	  This is the code to look-up an item from a key. Used by handleEvent.
	  
	  Return: true if the item was found.
	  
	***************************************************************************/

	bool keyToItem(ref TEvent event) {
		auto ch = TGKey.GetAltChar(event.keyDown.keyCode, event.keyDown.charScan.charCode);
		if ( findItem(ch) ) {
			putEvent(event);
			do_a_select(event);
			return true;
		}
		return false;
	}

	/**[txh]********************************************************************

	  Description:
	  This is the code to look-up a short cut from a key. Used by handleEvent.
	  
	  Return: true if the item was found.
	  
	***************************************************************************/

	bool keyToHotKey(ref TEvent event) {
		TMenuItem p = hotKey(event.keyDown.keyCode);
		if (p && commandEnabled(p.command)) {
			event.what=evCommand;
			event.message.command = p.command;
			event.message.infoPtr = cast(void*)0;
			putEvent(event);
			clearEvent(event);
		}
		return p ? true : false;
	}

	override void handleEvent( ref TEvent event ) { 
		if( menu !is null )
		switch (event.what) {
			case  evMouseDown:
				do_a_select(event);
				break;
			case  evKeyDown:
				if(! keyToItem(event) )
					keyToHotKey(event);
					break;
			case  evCommand:
				if( event.message.command == cm.Menu )
					do_a_select(event);
				break;
			case  evBroadcast:
				if( event.message.command == cm.CommandSetChanged ) {
					if( updateMenu(menu) ) {
						drawView();
					}
				}
				break;
			default:
				break;
		}
	}


	TMenuItem findHotKey( TMenuItem p, KeyCode keyCode ) {
	    while( p !is null ) {
	        if( p.name !is null ) {
	            if( p.command == cm.Null ) {
	                TMenuItem T;
	                if( (T = findHotKey( p.subMenu.items, keyCode )) !is null )
	                    return T;
				} else if( !p.disabled && p.keyCode != KeyCode.kbNoKey && p.keyCode == keyCode)
	                return p;
	            }
			p =  p.next;
		}
	    return null;
	}

	TMenuItem hotKey( KeyCode keyCode ) {
	    return findHotKey( menu.items, keyCode );
	}

	TMenuView newSubView( in TRect bounds, TMenu *aMenu, TMenuView aParentMenu ) {
	    return new TMenuBox( bounds, aMenu, aParentMenu );
	}
}

class TMenuBox : TMenuView {

	static TRect getRect( in TRect bounds, TMenu *aMenu ) {
		int w =  10;
		int h =  2;
		if( aMenu !is null ) {
			for( TMenuItem p = aMenu.items; p !is null; p = p.next ) {
				if( p.name !is null ) {
					int len = p.name.length + 6;
					if( p.command == cm.Null )
						len += 3;
					else
						if( p.param !is null )
							len += p.param.length + 2;
					w = max( len, w );
                }
				h++;
            }
        }

		TRect r =  bounds;

		if( r.a.x + w < r.b.x ) {
			r.b.x = r.a.x + w;
		} else {
			r.a.x = r.b.x - w;
		}

		if (r.a.y + h < r.b.y) {
			r.b.y = r.a.y + h;
		} else {
			r.a.y = r.b.y - h;
		}
		return r;
	}

	this( in TRect bounds, TMenu *aMenu, TMenuView aParentMenu) {
		super(getRect(bounds, aMenu), aMenu, aParentMenu);
		state |= sfShadow;
		// This class can be "Braille friendly"
		if (TScreen.getShowCursorEver())
			state |= sfCursorVis;
		options |= ofPreProcess;
	}

	static ushort cNormal, color;

	void frameLine( ref TDrawBuffer b, short n ) {
		b.moveBuf( 0, frameChars[n..$], cNormal, 2 );
		b.moveChar( 2, frameChars[n+2], color, size.x - 4 );
		b.moveBuf( size.x - 2, frameChars[n+3..$], cNormal, 2 );
	}

	override void draw() {
		TDrawBuffer b;
		cNormal = getColor(0x0301);
		ushort cSelect = getColor(0x0604);
		ushort cNormDisabled = getColor(0x0202);
		ushort cSelDisabled = getColor(0x0505);
		int y=0, yCur=-1;
		color =  cNormal;
		frameLine( b, 0 );
		writeBuf( 0, y++, size.x, 1, b );
		if( menu !is null ) {
			for( TMenuItem p = menu.items; p !is null; p = p.next ) {
				color = cNormal;
				if( p.name is null )
					frameLine( b, 15 );
				else {
					if( p.disabled ) {
						if( p is  current ) {
							color = cSelDisabled;
							yCur = y;
                        } else {
							color = cNormDisabled;
						}
					} else if( p is current ) {
						color = cSelect;
						yCur = y;
                    }
					frameLine( b, 10 );
					b.moveCStr( 3, p.name, color );
					if( p.command == cm.Null ) {
						b.putChar( size.x-4, rightArrow );
					} else if( p.param !is null ) {
						b.moveStr( size.x - 3 - p.param.length, p.param, color);
					}
                }
				writeBuf( 0, y++, size.x, 1, b );
            }
        }
		color = cNormal;
		frameLine( b, 5 );
		writeBuf( 0, y++, size.x, 1, b );
		// SET: Force a cursor movement to indicate which one is selected.
		// This helps Braille Terminals, but the cursor must be visible!
		if( yCur != -1 ) {
			setCursor( 2 , yCur );
			resetCursor();
        }
	}

	override TRect getItemRect( TMenuItem item ) {
		short  y = 1;
		TMenuItem p = menu.items;

		while( p != item ) {
			y++;
			p =  p.next;
        }
		return TRect( 2, y, size.x-2, y+1 );
	}
}

class TMenuBar : TMenuView {

	this( in TRect bounds, TMenu *aMenu ) {
		super(bounds);
		menu = aMenu;
		growMode = gfGrowHiX;
		options |= ofPreProcess;
		computeLength();
		// This class can be "Braille friendly"
		if (TScreen.getShowCursorEver())
			state |= sfCursorVis;
	}

	this( in TRect bounds, TSubMenu aMenu ) {
		this(bounds, new TMenu( aMenu ));
	}


	/**[txh]********************************************************************

	Description:
	This routine computes the length of the menu bar, if that's greater than
	the size.x the menu becomes compacted to allow more options.@*
	Added by SET.

	***************************************************************************/

	void computeLength() {
		int l = 0;
		TMenuItem p;

		if( menu !is null ) {
			p = menu.items;
			while( p !is null ) {
				if( p.name !is null ) {
					l += p.name.length + 2;
				}
				p = p.next;
            }
        }
		compactMenu = l > size.x;
	}

	/**[txh]********************************************************************

	Description:
	Calls TMenuView::changeBounds, additionally re-computes the length of the
	bar to select the no/compact mode.@*
	Added by SET.

	***************************************************************************/

	override void changeBounds(in TRect bounds) {
		TMenuView.changeBounds(bounds);
		int oldCompact = compactMenu;
		computeLength();
		if (compactMenu != oldCompact)
			draw();
	}

	override void draw() {
		ushort color;
		int x, l, inc, xSel=-1;
		TMenuItem p;

		ushort cNormal = getColor(0x0301);
		ushort cSelect = getColor(0x0604);
		ushort cNormDisabled =  getColor(0x0202);
		ushort cSelDisabled =  getColor(0x0505);
		auto b = new TDrawBuffer;
		b.moveChar( 0, ' ', cNormal, size.x );
		inc = (compactMenu ? 1 : 2); // SET
		if( menu !is null ) {
			x = 0;
			p = menu.items;
			while( p !is null ) {
				if( p.name !is null ) {
					l = p.name.lenWithoutTides;
					if( x + l < size.x ) {
						if( p.disabled ) {
							if( p is current ) {
								xSel = x;
								color = cSelDisabled;
                            }
							else {
								color = cNormDisabled;
							}
						} else {
							if( p is current ) {
								xSel = x;
								color = cSelect;
                            }
							else {
								color = cNormal;
							}
						}
						b.moveChar( x, ' ', color, 1 );
						b.moveCStr( x+1, p.name, color );
						b.moveChar( x+l+1, ' ', color, 1 );
                    }
					x += l + inc;
                }
				p = p.next;
            }
        }
		writeBuf( 0, 0, size.x, 1, *b );
		if( xSel != -1 ) {
			setCursor( xSel , 0 );
			resetCursor();
        }
	}

	override TRect getItemRect( TMenuItem item ) {
		int y = compactMenu ? 1 : 0; // SET
		TRect r = TRect(y, 0, y, 1);
		y = compactMenu ? 1 : 2; // SET
		TMenuItem p = menu.items;
		while( p ) {
			r.a.x = r.b.x;
			if( p.name !is null )
				r.b.x += p.name.length + y;
			if( p is item )
				return r;
			p = p.next;
        }
		return TRect(0, 0, 0, 0); // SAA: should not ever happen
	}
}

class TSubMenu : TMenuItem {
	this( string name, KeyCode key, ushort helpCtx = hcNoContext ) {
		super(name, cm.Null, key, helpCtx);
	}

	unittest {
		assert((new TSubMenu("Test", KeyCode.kbAltF)).command == cm.Null);
	}

	void add(TMenuItem rhs) {
		TSubMenu sub = this;
		while( sub.next !is null ) {
			sub = cast(TSubMenu)(sub.next);
		}

		if( sub.subMenu is null ) {
			sub.subMenu = new TMenu( rhs );
		} else {
			TMenuItem cur = sub.subMenu.items;
			while( cur.next !is null ) {
				cur = cur.next;
			}
			cur.next = rhs;
        }
	}

	void add(TSubMenu rhs) {
		TMenuItem cur = this;
		while( cur.next !is null ) {
			cur = cur.next;
		}
		cur.next = rhs;
	}
}