module tview;

import std.stream;
import std.algorithm;
import std.uni : toUpper;
import std.string;

public import tpoint;
public import trect;
public import tobject;
public import tstreamable;
public import tcommandset;
public import tevent;
public import tpalette;
public import tdrawbuffer;
public import tgroup;
public import tgkey;
public import tscreen;
public import tdisplay;
public import codepage;
public import teventqueue;
public import ttypes;
public import tvconfig;
public import views;
public import common;
public import commands;
import configfile;

private immutable TPalette palette = immutable(TPalette)(null);

abstract class TView : TObject, TStreamable {
	
	enum phaseType { phFocused, phPreProcess, phPostProcess };
	enum selectMode{ normalSelect, enterSelect, leaveSelect };
	
	static bool commandSetChanged;
	static bool showMarkers;
	static ubyte errorAttr;
	// SET: These are shared by various TView members.
	// I moved it to a class because I think is better to enclose them.
	static ubyte[] specialChars = [175, 174, 26, 27, ' ', ' ', 0];
	static ubyte[] ospecialChars = [ 175, 174, 26, 27, ' ', ' ', 0 ];

	static ubyte noMoireUnFill = ' ';  // Just space
	static ubyte noMoireFill = 0xDB;   // Full block
	static ubyte onoMoireFill = 0xDB;  // Full block
	
	static string name;
	
	TView next;
	TPoint size;
	ushort options;
	ushort eventMask;
	ushort state;
	TPoint origin;
	TPoint cursor;
	ushort growMode;
	ushort dragMode;
	int helpCtx;
	TGroup owner;

	static TCommandSet curCommandSet = initCommands();
	
	this(in TRect bounds) {
		this.next = null;
		this.options = 0;
		this.eventMask = evMouseDown | evKeyDown | evCommand | evMouseWheel;
		this.state = sfVisible;
		this.growMode = 0;
		this.dragMode = dmLimitLoY;
		this.helpCtx = hcNoContext;
		this.owner = null;
		setBounds( bounds);
		cursor.x = cursor.y = 0;
	}

	static private TCommandSet initCommands() {
		TCommandSet temp;
		temp.enableAllCommands();
		temp.disableCmd( cm.Zoom );
		temp.disableCmd( cm.Close );
		temp.disableCmd( cm.Resize );
		temp.disableCmd( cm.Next );
		temp.disableCmd( cm.Prev );
		return temp;
	}
	
	void sizeLimits( out TPoint min, out TPoint max ) const {
		min.x = min.y = 0;
		if (owner !is null)
			max = owner.size;
		else
			max.x = max.y = int.max;
	}
	
	TRect getBounds() const {
		return TRect( origin, origin+size );
	}	
	
	TRect getExtent() const {
		return TRect( 0, 0, size.x, size.y );
	}
	
	TRect getClipRect() const {
		TRect clip = getBounds();
		if (owner !is null)
			clip.intersect(owner.clip);
		clip.move(-origin.x, -origin.y);
		return clip;
	}
	
	bool mouseInView(in TPoint mouse) const {
		TPoint localMouse = makeLocal( mouse );
		if (localMouse.y == -49) {
			localMouse.y = -49;
			TPoint fakk = makeLocal( mouse );
		}
		TRect r = getExtent();
		return r.contains(localMouse);
	}
	
	bool containsMouse(in TEvent event) const {
		return (state & sfVisible) != 0 && mouseInView( event.mouse.where );
	}
	
	void locate( ref TRect bounds ) {
		TPoint min, max;
		sizeLimits(min, max);
		bounds.b.x = bounds.a.x + range(bounds.b.x - bounds.a.x, min.x, max.x);
		bounds.b.y = bounds.a.y + range(bounds.b.y - bounds.a.y, min.y, max.y);
		TRect r = getBounds();
		if( bounds != r ) {
			changeBounds( bounds );
			if ( owner !is null && (state & sfVisible) !=0  ) {
				if ( (state & sfShadow) != 0 ) {
					r.Union(bounds);
					r.b += shadowSize;
				}
				drawUnderRect( r, null );
			}
		}
	}
	
	void dragView( ref TEvent event, int aMode, ref TRect limits, TPoint minSize, TPoint maxSize) {
		ubyte mode = cast(ubyte)aMode;
		TRect saveBounds;
		
		TPoint p, s;
		setState( sfDragging, true );
		
		if( event.what == evMouseDown ) {
			if( (mode & dmDragMove) != 0 ) {
				p = origin - event.mouse.where;
				do  {
					event.mouse.where += p;
					moveGrow( event.mouse.where,
					         size,
					         limits,
					         minSize,
					         maxSize,
					         mode
					         );
				} while( mouseEvent(event,evMouseMove) );
			} else {
				p = size - event.mouse.where;
				do  {
					event.mouse.where += p;
					moveGrow( origin,
					         event.mouse.where,
					         limits,
					         minSize,
					         maxSize,
					         mode
					         );
				} while( mouseEvent(event,evMouseMove) );
			}
		} else {
			static TPoint 
			goLeft      =   {-1, 0}, 
			goRight     =   { 1, 0}, 
			goUp        =   { 0,-1}, 
			goDown      =   { 0, 1}, 
			goCtrlLeft  =   {-8, 0}, 
			goCtrlRight =   { 8, 0};
			
			saveBounds = getBounds();
			do  {
				p = origin;
				s = size;
				keyEvent(event);
				switch (event.keyDown.keyCode) {
					case KeyCode.kbLeft:
						change(mode,goLeft,p,s);
						break;
					case KeyCode.kbRight:
						change(mode,goRight,p,s);
						break;
					case KeyCode.kbUp:
						change(mode,goUp,p,s);
						break;
					case KeyCode.kbDown:
						change(mode,goDown,p,s);
						break;
					case KeyCode.kbCtrlLeft:
						change(mode, goCtrlLeft, p, s);
						break;
					case KeyCode.kbCtrlRight:
						change(mode,goCtrlRight,p,s);
						break;
						// Shift info goes in the key
					case KeyCode.kbShLeft:
						change(mode,goLeft,p,s,1);
						break;
					case KeyCode.kbShRight:
						change(mode,goRight,p,s,1);
						break;
					case KeyCode.kbShUp:
						change(mode,goUp,p,s,1);
						break;
					case KeyCode.kbShDown:
						change(mode,goDown,p,s,1);
						break;
					case KeyCode.kbShCtLeft:
						change(mode,goCtrlLeft,p,s,1);
						break;
					case KeyCode.kbShCtRight:
						change(mode,goCtrlRight,p,s,1);
						break;
					case KeyCode.kbHome:
						p.x = limits.a.x;
						break;
					case KeyCode.kbEnd:
						p.x = limits.b.x - s.x;
						break;
					case KeyCode.kbPgUp:
						p.y = limits.a.y;
						break;
					case KeyCode.kbPgDn:
						p.y = limits.b.y - s.y;
						break;
					default:
						break;
				}
				moveGrow( p, s, limits, minSize, maxSize, mode );
			} while( event.keyDown.keyCode != KeyCode.kbEsc && event.keyDown.keyCode != KeyCode.kbEnter);
			if ( event.keyDown.keyCode == KeyCode.kbEsc ) {
				locate(saveBounds);
			}
		}
		setState(sfDragging, false);
	}
	
	int range( int val, int min, int max ) {
		if( val < min )
			return min;
		else if( val > max )
			return max;
		else
			return val;
	}
	
	void calcBounds( out TRect bounds, in TPoint delta ) {
		bounds = getBounds();
		
		int s = owner.size.x;
		int d = delta.x;
		
		void grow(ref int i) {
			if (growMode & gfGrowRel) {
				i = (i * s + ((s - d) >> 1)) / (s - d);
			} else {
				i += d;
			}
		}
		
		if( (growMode & gfGrowLoX) != 0 )
			grow(bounds.a.x);
		
		if( (growMode & gfGrowHiX) != 0 )
			grow(bounds.b.x);
		
		s = owner.size.y;
		d = delta.y;
		
		if( (growMode & gfGrowLoY) != 0 )
			grow(bounds.a.y);
		
		if( (growMode & gfGrowHiY) != 0 )
			grow(bounds.b.y);
		
		TPoint minLim, maxLim;
		sizeLimits( minLim, maxLim );
		bounds.b.x = bounds.a.x + range( bounds.b.x-bounds.a.x, minLim.x, maxLim.x );
		bounds.b.y = bounds.a.y + range( bounds.b.y-bounds.a.y, minLim.y, maxLim.y );
	}
	
	void changeBounds( in TRect bounds ) {
		setBounds(bounds);
		drawView();
	}
	
	void growTo( int x, int y ) {
		TRect r = TRect(origin.x, origin.y, origin.x + x, origin.y + y);
		locate(r);
	}
	
	void moveTo( int x, int y ) {
		TRect r = TRect( x, y, x+size.x, y+size.y );
		locate(r);
	}
	
	void setBounds( in TRect bounds ) {            
		origin = bounds.a;
		size = bounds.b - bounds.a;
	}
	
	int getHelpCtx() const {
		if( (state & sfDragging) != 0 )
			return hcDragging;
		return helpCtx;
	}
	
	bool valid( Command ) {
		return true;
	}
	
	void hide() {
		if( (state & sfVisible) != 0 )
			setState( sfVisible, false );
	}
	
	void show() {
		if( (state & sfVisible) == 0 )
			setState(sfVisible, true);
	}
	
	void draw() {
		TDrawBuffer  b;
		b.moveChar( 0, ' ', getColor(1), size.x );
		writeLine( 0, 0, size.x, size.y, b );
	}
	
	void drawView() {
		if (exposed()) {
			draw();
			drawCursor();
		}
	}
	
	bool exposed() {
		if (!(state & sfExposed) || size.x<0 || size.y<0) {
			return false;
		}
		
		// Check each line, if at least one is exposed we are exposed
		int line=0;
		do {
			if (lineExposed(this, line, 0, size.x))
				return true;
			line++;
		} while (line<size.y);
		return false;
	}
	
	/**[txh]********************************************************************
	 
	 Description:
	 Finds if the area from x1 to x2 in the indicated line is exposed.
	 Note that sometimes the x1 - x2 range can be partially overlapped and we
	 must split the search in two. In this case the routine calls itself
	 providing a value for the target TView so we know that's just a continuation
	 and the initialization is skipped.
	 
	 Return:
	 true if exposed, false if not.
	 
	 ***************************************************************************/
	
	// TODO a paraméterek lehetnek constok!
	static bool lineExposed(TView view, int line, int x1, int x2, TView target = null) {
		int Xtest,Ytest;
		
		while (1) {
			if (target is null) {// This is a call to start searching, we must initialize
				target = view;
				// If no owner we are the view attached to the screen . we are exposed
				if (view.owner is null)
					return true;
				// Make coordinates relative to the owner
				line += view.origin.y;
				x1 += view.origin.x;
				x2 += view.origin.x;
				
				// Apply clipping, and check if the coordinate gets outside
				const TRect clip = view.owner.clip;
				if (line < clip.a.y || line >= clip.b.y)
					return false;
				if (x1<clip.a.x)
					x1=clip.a.x;
				if (x2>clip.b.x)
					x2=clip.b.x;
				if (x1>=x2)
					return false;
				
				// Go to last in the owner's list
				view = view.owner.last;
			}
			
			while (1)
			{
				view = view.next;
				if (view==target)
				{// No other TView is overlapping us
					// If our owner is buffered report exposed to draw in the buffer
					if (view.owner.buffer) return true;
					// If not work with the owner
					view = view.owner;
					target=null;
					break;
				}
				
				// If not visible forget it
				if (!(view.state & sfVisible)) 
					continue;
				
				// Check the Y range
				Ytest = view.origin.y;
				if (line<Ytest)  continue;
				Ytest += view.size.y;
				if (line>=Ytest) continue;
				
				// Check the X range
				Xtest = view.origin.x;
				if (x1>=Xtest)
				{
					Xtest+=view.size.x;
					if (x1>=Xtest) continue;
					// This object overlaps, reduce the x range
					x1=Xtest;
					if (x1<x2) continue;
					// It was reduced to nothing
					return false;
				}
				if (x2<=Xtest) continue;
				// This object overlaps
				Xtest+=view.size.x;
				if (x2<=Xtest)
				{// Reduce the x range
					x2=view.origin.x;
					continue;
				}
				// The object partially overlaps generating two segments
				// So call to analyze x1 to view.origin.x
				if (lineExposed(view,line,x1,view.origin.x,target))
					return true;
				// and then continue with view.origin.x+view.size.x to x2
				x1=Xtest;
			}
		}
	}
	
	void hideCursor() {
		setState( sfCursorVis, false );
	}
	
	void drawHide( TView lastView ) {
		drawCursor();
		drawUnderView((state & sfShadow) != 0, lastView);
	}
	
	void drawShow( TView lastView ) {
		drawView();
		if( (state & sfShadow) != 0 )
			drawUnderView( true, lastView );
	}
	
	void drawUnderRect( in TRect r, TView lastView ) {
		owner.clip.intersect(r);
		owner.drawSubViews(nextView(), lastView);
		owner.clip = owner.getExtent();
	}
	
	void drawUnderView( bool doShadow, TView lastView ) {
		TRect r = getBounds();
		if ( doShadow )
			r.b += shadowSize;
		drawUnderRect( r, lastView );
	}
	
	uint dataSize() {
		return 0;
	}
	
	void getData( void * ) {
	}
	
	void setData( void * ) {
	}
	
	void blockCursor() {
		setState(sfCursorIns, true);
	}
	
	void normalCursor() {
		setState(sfCursorIns, false);
	}
	
	/**[txh]********************************************************************
	 
	 Description: 
	 This routine enables/disables the screen cursor.
	 Two details are important:
	 1) If our object is really visible (not under another)
	 2) If our state indicates the cursor is visible or not.
	 The routine does a search climbing to the owners until the TView that
	 have the screen (owner==0) is reached or we determine we are under
	 another view and hence the cursor isn't visible.
	 SET: I recoded it for clarity.
	 
	 ***************************************************************************/
	void resetCursor() {
		int x, y, lookNext=1;
		TView target = this;
		TView view;
		
		// If not visible or not focused or cursor not visible (unless never hide)
		// then skip it
		if (((~state) & (sfVisible /*| sfCursorVis*/ | sfFocused))==0 &&
		    !(TScreen.getDontMoveHiddenCursor() && ((~state) & sfCursorVis)))
		{
			y = cursor.y;
			x = cursor.x;
			// While the cursor is inside the target
			while ( lookNext &&
			       ((x>=0) && (x<target.size.x)) &&
			       ((y>=0) && (y<target.size.y)) )
			{
				y += target.origin.y;
				x += target.origin.x;
				if (!target.owner)
				{ // Target is the one connected to the screen, set the screen cursor
					TScreen.setCursorPos(x,y);
					if (state & sfCursorVis)
					{
						ushort curShape = TScreen.cursorLines;
						if (state & sfCursorIns)
							curShape = 100*256;
						TScreen.setCursorType(curShape);
					}
					else
						TScreen.setCursorType(0);
					return;
				}
				// Analyze target.owner unless the coordinate is over another object
				// that belongs to the owner.
				lookNext = 0;
				view = target.owner.last;
				do
				{
					view = view.next;
					if (view == target)
					{ // Ok x,y is inside target and nobody is over it.
						target = view.owner;
						lookNext = 1;
						break;
					}
				}
				while (!(view.state & sfVisible) ||
				       y<view.origin.y ||
				       y>=view.origin.y+view.size.y ||
				       x<view.origin.x ||
				       x>=view.origin.x+view.size.x);
			}
		}
		// Cursor disabled
		TScreen.setCursorType(0);
		return;
	}
	
	void setCursor( int x, int y ) {
		cursor.x = x;
		cursor.y = y;
		drawCursor();
	}
	
	void showCursor() {
		setState( sfCursorVis, true );
	}
	
	void drawCursor() {
		// SET: do it only if our owner gives permission
		if( (state & sfFocused) != 0 && owner && owner.canShowCursor())
			resetCursor();
	}
	
	// TODO: Why is this here?...
	void clearEvent( ref TEvent event ) {
		event.what = evNothing;
		event.message.infoPtr = cast(void*)this;
	}
	
	bool eventAvail() {
		TEvent event;
		getEvent(event);
		if( event.what != evNothing )
			putEvent(event);
		return event.what != evNothing;
	}
	
	void getEvent( ref TEvent event ) {
		if( owner !is null )
			owner.getEvent(event);
	}
	
	void handleEvent(ref TEvent event) {
		if( event.what == evMouseDown )
		{
			if(!(state & (sfSelected | sfDisabled)) && (options & ofSelectable) )
			{
				select();
				if( !(state & sfSelected) || // SET: If we failed to get the focus forget
				   // about this mouse click.
				   !(options & ofFirstClick) )
					clearEvent(event);
			}
		}
	}
	
	void putEvent( ref TEvent event ) {
		if( owner !is null )
			owner.putEvent(event);
	}
	
	void createEvent(T)( ushort what, Command command, T infoPtr ) {
		TEvent event;
		event.what = what;
		event.message.command = command;
		event.message.infoPtr = cast(void*)infoPtr;
		putEvent( event );
	}
	
	static bool commandEnabled( Command command ) {
		return /* (command > 0x3FF) || // is now handled by
		        // curCommandSet.has(command) */
		curCommandSet.has(command);
	}
	
	static void disableCommands( TCommandSet commands ) {
		commandSetChanged = true;
		curCommandSet.disableCmd(commands);
	}
	
	static void disableCommand( Command command ) {
		commandSetChanged =  commandSetChanged ||
			curCommandSet.has(command) ;
		curCommandSet.disableCmd(command);
	}
	
	static void enableCommands( TCommandSet commands ) {
		commandSetChanged =  commandSetChanged || ((curCommandSet&commands) != commands) ;
		curCommandSet.enableCmd(commands);
	}
	
	static void enableCommand( Command command ) {
		commandSetChanged = commandSetChanged || !curCommandSet.has( command ) ;
		curCommandSet.enableCmd(command);
	}
	
	static void getCommands( out TCommandSet commands ) {
		commands = curCommandSet;
	}
	
	static void setCommands( TCommandSet commands ) {
		commandSetChanged = commandSetChanged || (curCommandSet != commands );
		curCommandSet = commands;
	}
	
	void endModal( Command command ) {
		if( TopView() !is null )
			TopView().endModal(command);
	}
	
	Command execute() {
		return cm.Cancel;
	}
	
	ushort getColor( ushort color ) const {
		ushort colorPair = color >> 8;
		
		if( colorPair != 0 )
			colorPair = mapColor(colorPair) << 8;
		
		colorPair |= mapColor( cast(ubyte)color );
		
		return colorPair;
	}
	
	ref immutable(TPalette) getPalette() const {
		return palette;
	}
	
	private ubyte getOwnerMapColor(in TView view, ubyte color) const {
		if (view is null) {
			return color;
		}
		const TPalette p = view.getPalette();
		auto paletteLen = p[0];
		if( paletteLen != 0 ) {
			if( color > paletteLen )
				return errorAttr;
			color = p[color];
			if( color == 0 )
				return errorAttr;
		}
		return getOwnerMapColor(view.owner, color);
	}
	
	ubyte mapColor( int c ) const {
		ubyte color = cast(ubyte)(c);
		if( color == 0 )
			return errorAttr;
		const TView cur = this;
		return getOwnerMapColor(this, color);
	}
	
	bool getState( ushort aState ) const {
		return  (state & aState) == aState ;
	}
	
	void select() {
		if( (options & ofTopSelect) != 0 )
			makeFirst();
		else if( owner !is null )
			owner.setCurrent( this, selectMode.normalSelect );
	}
	
	void setState( ushort aState, bool enable ) {
		if( enable == true )
			state |= aState;
		else
			state &= ~aState;
		
		if( owner is null )
			return;
		
		switch( aState )
		{
			case  sfVisible:
				if( (owner.state & sfExposed) != 0 )
					setState( sfExposed, enable );
				if( enable == true )
					drawShow( null );
				else
					drawHide( null );
				if( (options & ofSelectable) != 0 )
					owner.resetCurrent();
				break;
			case  sfCursorVis:
			case sfCursorIns:
				drawCursor();
				break;
			case  sfShadow:
				drawUnderView( true, null );
				break;
			case  sfFocused:
				if (owner && owner.canShowCursor())
					// SET: do it only if our owner gives permission
					resetCursor();
				message( owner,
				        evBroadcast,
				        (enable == true) ? cm.ReceivedFocus : cm.ReleasedFocus,
				        this
				        );
				break;
			default:
				break;
		}
	}
	
	void keyEvent( ref TEvent event ) {
		do {
			getEvent(event);
		} while( event.what != evKeyDown );
	}
	
	bool mouseEvent(ref TEvent event, ushort mask) {
		do {
			getEvent(event);
		} while( !(event.what & (mask | evMouseUp)) );
		
		return event.what != evMouseUp;
	}
	
	TPoint makeGlobal( TPoint source ) const {
		TPoint rMakeGlobal(in TView view) {
			if (view is null) {
				return source;
			}
			source += view.origin;
			return rMakeGlobal(view.owner);
		}
		return rMakeGlobal(this);
	}
	
	TPoint makeLocal( TPoint source ) const {
		TPoint rMakeLocal(in TView view) {
			if (view is null) {
				return source;
			}
			source -= view.origin;
			return rMakeLocal(view.owner);
		}
		return rMakeLocal(this);
	}
	
	TView nextView() {
		if( this is owner.last )
			return null;
		else
			return next;
	}
	
	TView prevView() {
		if( this is owner.first() )
			return null;
		else
			return prev();
	}
	
	TView prev() {
		TView res = this;
		while( res.next !is this )
			res = res.next;
		return res;
	}
	
	void makeFirst() {
		putInFrontOf(owner.first());
	}
	
	void putInFrontOf( TView target ) {
		TView p, lastView;
		
		if( owner !is null && target !is this && target !is nextView() &&
		   ( target is null || target.owner is owner)
		   )
		{
			if( (state & sfVisible) == 0 )
			{
				owner.removeView(this);
				owner.insertView(this, target);
			}
			else
			{
				lastView = nextView();
				p = target;
				while( p !is null && p !is this )
					p = p.nextView();
				if( p is null )
					lastView = target;
				state &= ~sfVisible;
				if( lastView is target )
					drawHide(lastView);
				owner.removeView(this);
				owner.insertView(this, target);
				state |= sfVisible;
				if( lastView !is target )
					drawShow(lastView);
				if( (options & ofSelectable) != 0 )
					owner.resetCurrent();
			}
		}
	}
	
	TView TopView() {
		if( TheTopView !is null )
			return TheTopView;
		else
		{
			TView p = this;
			while( p !is null && !(p.state & sfModal) )
				p = p.owner;
			return p;
		}
	}
	
	// That's the way to call the function getting conversion
	void writeBuf(int x, int y, int w, int h, in ref TDrawBuffer b) { 
		writeNativeBuf(x,y,w,h,b.getBuffer());
	}
	
	// Called by old code using codepage encoding
	void writeBuf(int x, int y, int w, int h, in CharInfo[] Buffer) {
		writeNativeBuf(x, y, w, h, Buffer);
	}
	
	// Used by new code that uses a buffer according to the mode
	void writeNativeBuf(int x, int y, int w, int h, in CharInfo[] Buffer)
	{
		int i=0;
		uint wB=w;
		//if (TDisplay.getDrawingMode() == TDisplay.unicode16)
		//	wB *= 2;
		const(CharInfo)[] b = Buffer;
		while (h--) {
			writeView(x, y++, w, b, this);
			b = b[wB..$];
			i++;
		}
	}
	
	static void writeView(int xStart, int line, int xEnd, in CharInfo[] buffer,
	               TView view, int offset = 0, int inShadow = 0, TView target = null)
	{
		int x,y,skipInit=0;
		
		if (target is null) {// Initial call so initialize
			// Check line is valid
			if (line<0 || line>=view.size.y) return;
			// Validate x range
			if (xStart<0) xStart=0;
			if (xEnd>view.size.x)  {
				xEnd=view.size.x;
			}
			if (xStart>=xEnd) return;
			// Initialize values
			offset=xStart;
			inShadow=0;
			skipInit=0;
		}
		else
			skipInit=1;
		
		do
		{
			if (skipInit)
				skipInit=0;
			else
			{// Pass to the owner or init if that's the first call
				if (!(view.state & sfVisible) ||
				    !view.owner) return;
				
				// Make coordinates relative to the owner
				line += view.origin.y;
				x = view.origin.x;
				xStart += x;
				xEnd  += x;
				offset += x;
				
				// Apply clipping, and check if the coordinate gets outside
				const TRect clip = view.owner.clip;
				if (line < clip.a.y || line >= clip.b.y) 
					return;
				if (xStart < clip.a.x)
					xStart = clip.a.x;
				if (xEnd > clip.b.x) {
					xEnd = clip.b.x;
				}
				if (xStart >= xEnd) 
					return;
				
				target = view;
				view = view.owner.last;
			}
			
			do
			{
				view=view.next;
				// We are visible go to the owner
				if (view is target) break;
				// Honor the sfVisible bit
				if (!(view.state & sfVisible)) continue;
				
				// Check the y range
				y = view.origin.y;
				if (line<y) continue;
				y += view.size.y;
				if (line >= y)
				{// The line is outside, now check for the shadow
					if (!(view.state & sfShadow)) continue;
					y+=shadowSize.y;
					if (line>=y) continue;
					// We are in the shadow line
					x = view.origin.x;
					x += shadowSize.x;
					if (xStart<x) {
						if (xEnd<=x) continue;
						// We are under a shadow. Do the part that isn't under.
						writeView(xStart, line, x, buffer, view, offset, inShadow, target);
						// Now the rest
						xStart=x;
					}
					x+=view.size.x;
				} else {// The line is inside, check the X range
					x=view.origin.x;
					if (xStart < x) {
						if (xEnd <= x) continue;
						// Do the xStart to view.origin.x part
						writeView(xStart,line,x,buffer,view,offset,inShadow,target);
						// Now the rest
						xStart=x;
					}
					x+=view.size.x;
					if (xStart < x) {
						if (xEnd<=x) return;
						// Overlapped, reduce the size
						xStart=x;
					}
					if (!(view.state & sfShadow)) continue;
					// Now add the shadow
					if (line<view.origin.y+shadowSize.y) continue;
					x += shadowSize.x;
				}
				// This part deals with the part that can be under the shadow
				if (xStart>=x) continue; // No in shadow
				inShadow++;
				if (xEnd<=x) continue;   // Full in shadow
				// Partially under a shadow, do the shadow part
				writeView(xStart,line,x,buffer,view,offset,inShadow,target);
				// and now the rest.
				xStart=x;
				inShadow--;
			}
			while (1);
			
			// We get here if we found a portion that can be exposed and need to
			// check in the owner.
			TGroup owner=view.owner;
			view=owner;
			// If the owner is unbuffered ...
			if (!owner.buffer)
			{ // and locked avoid drawing
				if (owner.lockFlag) return;
				// else go deeper
				continue;
			}
			// If the owner's buffer isn't the screen do the blit
			if (owner.buffer !is TScreen.screenBuffer) {
				blitBuffer(view, line, xStart, xEnd, offset, buffer, inShadow);
				// If locked stop here
				if (owner.lockFlag) return;
				continue;
			}
			// We are here because the owner is buffered and attached to the screen
			if (line!=TEventQueue.curMouse.where.y ||
			    xStart>TEventQueue.curMouse.where.x ||
			    xEnd<=TEventQueue.curMouse.where.x)
			{// The mouse is not in the draw area
				TMouse.resetDrawCounter();
				blitBuffer(view,line,xStart,xEnd,offset, buffer,inShadow);
				if (TMouse.getDrawCounter()==0)
				{// There was no mouse event
					if (owner.lockFlag) return;
					continue;
				}
			}
			// The mouse is in the draw area or an event has occoured during
			// the above drawing
			TMouse.hide();
			blitBuffer(view,line,xStart,xEnd,offset,buffer,inShadow);
			TMouse.show();
			if (owner.lockFlag) return;
		}
		while (1);
	}
	
	static void blitBuffer(TView view, int line, int xStart, int xEnd, int offset,
	                in CharInfo[] buffer, int inShadow)
	{
		int count = xEnd - xStart;
		int destOffset = line * view.size.x + xStart;
		int skipOffset = xStart-offset;
		const(CharInfo)[] blitFrom;
		TGroup group = cast(TGroup)view;
		bool isScreen = group.buffer is TScreen.screenBuffer;
		
			blitFrom = buffer[skipOffset..skipOffset+count];
			// Remap characters if needed
			CharInfo[] aux = new CharInfo[count];
			if (inShadow) {// is much more efficient to call the OS just once
				aux[] = blitFrom[0..aux.length][];
				for (int i = 0; i < count; i++) {
					aux[i].attrib = shadowAttr;
				}
				blitFrom = aux;
			}

			if (isScreen)
				TScreen.setCharacters(destOffset, blitFrom[0..count]);
			else {
				int to = destOffset + count;
				foreach(i, ref v; group.buffer[destOffset..to]) {
					v = blitFrom[i];
				}
			}
	}
	
	void writeLine(int x, int y, int w, int h, in ref TDrawBuffer b) {
		writeNativeLine(x,y,w,h,b.getBuffer());
		return;
	}
	
	void writeLine(int x, int y, int w, int h, in CharInfo[] Buffer) {
		writeNativeLine(x,y,w,h,Buffer);
	}
	
	void writeNativeLine(int x, int y, int w, int h, in CharInfo[] b) {
		while (h--) {
			writeView(x,y++, x + w, b, this);
		}
	}
	
	
	void writeChar(int x, int y, wchar c, ubyte color, int count) {
		if (count<=0)
			return;

		CharInfo cell = CharInfo(c, mapColor(color));
		CharInfo[] temp = new CharInfo[count];
		temp[] = cell;
		
		writeView(x, y, count, temp, this);
	}
	
	version(TV_BIG_ENDIAN) {
		static uint endianCol(int letraI, ushort color) {
			ushort letra = cast(ushort)letraI;
			return (((cast(uint)letra)<<16) | (cast(uint)color));
		}
	} else {
		static uint endianCol(int letraI, ushort color) {
			ushort letra = cast(ushort)letraI;
			return (((cast(uint)color)<<16) | (cast(uint)letra));
		}
	}
	
	void writeStr(int x, int y, string str, ubyte color)
	{
		/*
		 int count=strlen(str),i;
		 if (!count)
		 return;
		 //AllocLocalStr(temp,(count+1)*2);
		 char[] temp = new char((str.len+1)*2);
		 
		 if (TDisplay.getDrawingMode() == TDisplay.unicode16) {// Not in native mode
		 TVCodePage.convertStrCP_2_U16(str);
		 writeStrU16(x,y,(ushort *)temp, color);
		 return;
		 }
		 
		 color=mapColor(color);
		 for (i=0; i<count; i++)
		 {
		 temp[i*2]=str[i];
		 temp[i*2+1]=color;
		 }
		 writeView(x,y,count,temp);
		 */
	}
	
	override void shutDown() {
		hide();
		if( owner !is null )
			owner.remove( this );
		TObject.shutDown();
	}
	
	private void moveGrow( TPoint p,
	                      TPoint s,
	                      TRect limits,
	                      TPoint minSize,
	                      TPoint maxSize,
	                      ubyte mode
	                      )
	{
		TRect   r;
		s.x = min(max(s.x, minSize.x), maxSize.x);
		s.y = min(max(s.y, minSize.y), maxSize.y);
		p.x = min(max(p.x, limits.a.x - s.x+1), limits.b.x-1);
		p.y = min(max(p.y, limits.a.y - s.y+1), limits.b.y-1);
		
		if( (mode & dmLimitLoX) != 0 )
			p.x = max(p.x, limits.a.x);
		if( (mode & dmLimitLoY) != 0 )
			p.y = max(p.y, limits.a.y);
		if( (mode & dmLimitHiX) != 0 )
			p.x = min(p.x, limits.b.x-s.x);
		if( (mode & dmLimitHiY) != 0 )
			p.y = min(p.y, limits.b.y-s.y);
		r = TRect(p.x, p.y, p.x +  s.x, p.y +  s.y);
		locate(r);
	}
	
	void change( ubyte mode, TPoint delta, TPoint p, TPoint s, int grow = 0 ) {
		if( (mode & dmDragMove) != 0 && !grow )
			p += delta;
		else if( (mode & dmDragGrow) != 0 && grow )
			s += delta;
	}
	
	override string streamableName() const {
		return name; 
	}
	
	override void write( Elem* data ) const {
		
		ushort saveState = cast(ushort)(state & ~( sfActive | sfSelected | sfFocused | sfExposed ));
		origin.serializeTo(data.origin);
		size.serializeTo(data.size);
		cursor.serializeTo(data.cursor);
		data.growMode.set(growMode);
		data.dragMode.set(dragMode);
		data.helpCtx.set(helpCtx);
		data.state.set(saveState);
		data.options.set(options);
		data.eventMask.set(eventMask);
	}
	
	override void read( Elem* data ) {
		origin.deSerializeFrom(data.origin);
		size.deSerializeFrom(data.size);
		cursor.deSerializeFrom(data.cursor);
		growMode = data.growMode.value!ushort;
		dragMode = data.dragMode.value!ushort;
		helpCtx = data.helpCtx.value!ushort;
		state = data.state.value!ushort;
		options = data.options.value!ushort;
		eventMask = data.eventMask.value!ushort;
		owner = null;
		next = null;
	}
	
	this(Elem* inStream) {
		read(inStream);
	}

	
}