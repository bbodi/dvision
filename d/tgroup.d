module tgroup;

import tview;
import trect;
import tevent;

TView TheTopView;

static bool hasMouse( TView p, void *s ) {
	return p.containsMouse( *cast(TEvent *)s );
}

static private int force_redraw = 0;

class TGroup : TView {

	TView last, current;
	
	TRect clip;
	phaseType phase;
	
	CharInfo[] buffer;
	ubyte lockFlag;
	Command endState;

	
	this( in TRect bounds ) {
		super(bounds);
		current = last = null;
		phase = phaseType.phFocused;
		buffer = null;
		lockFlag = 0;
		endState = cm.Null;
		options |= ofSelectable | ofBuffered;
		clip = getExtent();
		eventMask = 0xFFFF;
	}

	TView first() {
		if( last is null )
			return null;
		else
			return last.next;
	}

	bool canShowCursor() {
		if (buffer) {
			if (owner) {
				return owner.canShowCursor();
			}
			return false;
		}
		return lockFlag ? false : true;
	}

	override void setData(void* ptr) {
		uint fieldOffset = 0;
		if( last !is null ) {
			TView v = last;
			do  {
				v.setData( cast(byte *)ptr + fieldOffset );
				fieldOffset += v.dataSize();
				v = v.prev();
			} while (v !is last);
		}
	}

	private static void doExpose( TView p, void *enable )
	{
		if( (p.state & sfVisible) != 0 )
			p.setState( sfExposed, *cast(bool *)enable );
	}

	struct setBlock
	{
		ushort st;
		bool en;
	};
	
	static void doSetState( TView p, void *b )
	{
		p.setState( (cast(setBlock *)b).st, (cast(setBlock *)b).en );
	}
	
	override void setState( ushort aState, bool enable ) {
		setBlock sb;
		sb.st = aState;
		sb.en = enable;
		
		TView.setState( aState, enable );
		
		if( (aState & (sfActive | sfDragging)) != 0 ) { 
			lock();
			forEach( &doSetState, &sb );
			unlock();
		}
		
		if( (aState & sfFocused) != 0 ) {
			if( current !is null )
				current.setState( sfFocused, enable );
		}
		
		if( (aState & sfExposed) != 0 ) {
			forEach( &doExpose, &enable );
			if( enable == false )
				freeBuffer();
		}
	}

	void setCurrent( TView p, selectMode mode ) {
		if (current !is p) {
			lock();
			focusView( current, false );
			// Test if focus lost was allowed and focus has really been loose
			if ( (mode == selectMode.normalSelect) && (current !is null) && (current.state & sfFocused)) {
				unlock(); 
				return; 
			}
			if( mode != selectMode.enterSelect ) {
				if( current !is null ) {
					current.setState( sfSelected, false );
				}
			}
			if( mode != selectMode.leaveSelect ) {
				if( p !is null ) {
					p.setState( sfSelected, true );
				}
			}
			focusView( p, true );
			current = p;
			unlock();
		}
	}

	void unlock() {
		if( lockFlag != 0 && --lockFlag == 0 ) {
			drawView();
			// SET: Now is time to hide/show mouse according to
			// changes while we were locked.
			resetCursor();
		}
	}

	override void resetCursor() {
		if( current !is null ) {
			current.resetCursor();
		}
	}
	
	override bool valid( Command command ) {
		return  firstThat( (p, commandP) => !p.valid( *cast(Command *)commandP ), &command ) is null ;
	}

	void focusView( TView p, bool enable ) {
		if( (state & sfFocused) != 0 && p !is null )
			p.setState( sfFocused, enable );
	}

	override int getHelpCtx() const {
		int h = hcNoContext;
		if( current !is null )
			h = current.getHelpCtx();
		if (h == hcNoContext)
			h = TView.getHelpCtx();
		return h;
	}

	void resetCurrent() {
		setCurrent( firstMatch( sfVisible, ofSelectable ), selectMode.normalSelect );
	}

	void lock() {
		if( buffer !is null || lockFlag != 0 ) {
			lockFlag++;
		}
	}

	TView firstMatch( ushort aState, ushort aOptions ) {
		if( last is null )
			return null;
		
		TView temp = last;
		while(1) {
			if( ((temp.state & aState) == aState) && 
			   ((temp.options & aOptions) ==  aOptions))
				return temp;
			
			temp = temp.next;
			if( temp == last )
				return null;
		}
	}

	override void getData(void *rec) {
		uint i = 0;
		if (last !is null )
		{
			TView v = last;
			do  {
				v.getData( (cast(char *)rec) + i );
				i += v.dataSize();
				v = v.prev();
			} while( v !is last );
		}
	}

	override void draw()
	{
		/* I have changed it now to force a redraw of all subviews
   instead of redrawing from the buffer, when the flag
   'force_redraw' is set. This flag is set by the new member
   function 'Redraw' which should be called, when the app wants
   a forced redraw of all subviews.
*/
		if (buffer !is null) {
			if (force_redraw)
			{
				lockFlag++;
				redraw();
				lockFlag--;
			}
			writeNativeBuf( 0, 0, size.x, size.y, buffer );
		} else {
			getBuffer();
			if (buffer !is null) {
				lockFlag++;
				redraw();
				lockFlag--;
				writeNativeBuf( 0, 0, size.x, size.y, buffer );
			} else {
				clip = getClipRect();
				redraw();
				clip = getExtent();
			}
		}
	}

	void drawSubViews( TView p, TView bottom ) {
		while( p !is bottom ) {
			p.drawView();
			p = p.nextView();
		}
	}

	void removeView(TView p) {
		TView akt, view;
		if (!last) return;
		view = last;
		akt = view.next;
		while ((akt !is p) && (akt !is last))
		{
			view = akt;
			akt = view.next;
		}
		if (akt is p)
		{
			akt = p.next;
			view.next = akt;
			if (last !is p) return;
			if (akt is p) view = null;
			last = view;
			return;
		}
		if (akt is last) return;
	}

	void remove(TView p) {
		ushort saveState;
		saveState = p.state;
		p.hide();
		removeView(p);
		p.owner = null;
		p.next= null;
		if( (saveState & sfVisible) != 0 )
			p.show();
	}

	void eventError( in ref TEvent event ) {
		if (owner !is null ) {
			owner.eventError( event );
		}
	}

	override Command execute() {
		do {
			endState = cm.Null;
			TEvent e;
			do  {
				getEvent( e );
				handleEvent( e );
				if( e.what != evNothing )
					eventError( e );
			} while( endState == cm.Null );
		} while( !valid(endState) );
		return endState;
	}

	struct handleStruct {
		TEvent *event;
		TGroup grp;
	};

	override void handleEvent( ref TEvent event ) {
		TView.handleEvent( event );
		
		handleStruct hs = handleStruct( &event, this );
		
		if( (event.what & focusedEvents) != 0 ) {
			phase = phaseType.phPreProcess;
			forEach( &doHandleEvent, &hs );
			
			phase = phaseType.phFocused;
			doHandleEvent( current, &hs );
			
			phase = phaseType.phPostProcess;
			forEach( &doHandleEvent, &hs );
		}
		else {
			phase = phaseType.phFocused;
			bool positionalEvent = (event.what & positionalEvents) != 0;
			if( positionalEvent ) {
				doHandleEvent( firstThat( (p, s) => p.containsMouse( *cast(TEvent *)s ), &event ), &hs );
			}
			else {
				forEach( &doHandleEvent, &hs );
			}
		}
	}

	private static void doHandleEvent( TView p, void *s ) {
		handleStruct *ptr = cast(handleStruct *)s;
		bool positionalEvent = (ptr.event.what & positionalEvents) != 0;
		bool focusedEvent = (ptr.event.what & focusedEvents) != 0;
		if( p is null ||
		   ( (p.state & sfDisabled) != 0 &&
		 (positionalEvent || focusedEvent)
		 )
		   )
			return;
		
		switch( ptr.grp.phase ) {
			case phaseType.phPreProcess:
				if( (p.options & ofPreProcess) == 0 )
					return;
				break;
			case phaseType.phPostProcess:
				if( (p.options & ofPostProcess) == 0 )
					return;
				break;
			default:
				break;
		}
		if( (ptr.event.what & p.eventMask) != 0 )
			p.handleEvent( *ptr.event );
	}

	void insert( TView p ) {
		insertBefore( p, first() );
	}


	void insertBefore( TView newView, TView Target ) {
		if( newView !is null && newView.owner is null && (Target is null || Target.owner is this) ) {
			if( (newView.options & ofCenterX) != 0 )
				newView.origin.x = (size.x - newView.size.x)/2;
			if( (newView.options & ofCenterY) != 0 )
				newView.origin.y = (size.y - newView.size.y)/2;
			ushort saveState = newView.state;
			newView.hide();
			insertView(newView, Target);
			if( (saveState & sfVisible) != 0 ) {
				newView.show();
			}
		}
	}
	
	void insertView( TView newView, TView Target ) {
		newView.owner = this;
		if( Target !is null ) {
			Target = Target.prev();
			newView.next = Target.next;
			Target.next = newView;
		} else {
			if( last is null) {
				newView.next = newView;
			} else {
				newView.next = last.next;
				last.next = newView;
			}
			last = newView;
		}
	}

	TView firstThat( bool function(TView , void *) func, void *args ) {
		TView temp = last;
		if( temp is null )
			return null;
		
		do  {
			temp = temp.next;
			if( func( temp, args ) == true )
				return temp;
		} while( temp !is last );
		return null;
	}

	void CLY_Redraw() {
		force_redraw++;
		redraw();
		force_redraw--;
	}

	void redraw() {
		drawSubViews( first(), null );
	}

	void forEach( void function(TView, void *) func, void *args ) {
		TView term = last;
		TView temp = last;
		if( temp is null )
			return;
		
		TView next = temp.next;
		do  {
			temp = next;
			next = temp.next;
			func( temp, args );
		} while( temp !is term );
	}

	short indexOf( TView p ) {
		if( last is null )
			return 0;
		
		short index = 0;
		TView temp = last;
		do  {
			index++;
			temp = temp.next;
		} while( temp !is p && temp !is last );
		if( temp !is p )
			return 0;
		else
			return index;
	}

	TView at( short index ) {
		TView temp = last;
		while( index-- > 0 )
			temp = temp.next;
		return temp;
	}

	void selectNext( bool forwards ) {
		if( current !is null ) {
			TView p = current;
			do  {
				if (forwards)
					p = p.next;
				else
					p = p.prev();
			} while ( !(
				(((p.state & (sfVisible + sfDisabled)) == sfVisible) &&
			 (p.options & ofSelectable)) || (p is current)
				) );
			p.select();
		}
	}

	void selectView( TView p, bool enable ) {
		if( p !is null)
			p.setState( sfSelected, enable );
	}

	Command execView( TView p ) {
		if( p is null )
			return cm.Cancel;
		
		ushort saveOptions = p.options;
		TGroup saveOwner = p.owner;
		TView saveTopView = TheTopView;
		TView saveCurrent= current;
		TCommandSet saveCommands;
		getCommands( saveCommands );
		TheTopView = p;
		p.options = p.options & ~ofSelectable;
		p.setState(sfModal, true);
		setCurrent(p, selectMode.enterSelect);
		if( saveOwner is null )
			insert(p);
		
		// Just be foolproof
		int oldLock=lockFlag;
		if (lockFlag)
		{
			lockFlag=1; unlock();
		}
		
		Command retval = p.execute();
		p.setState(sfActive, false);
		
		// Re-lock if needed
		lockFlag = cast(ubyte)oldLock;
		
		if( saveOwner is null )
			remove(p);
		setCurrent(saveCurrent, selectMode.leaveSelect);
		p.setState(sfModal, false);
		p.options = saveOptions;
		TheTopView = saveTopView;
		setCommands(saveCommands);
		return retval;
	}

	override void shutDown() {
		// Avoid problems if a hidden or unselectable TView was forced to be
		// selected. Marek Bojarski <bojarski@if.uj.edu.pl>
		resetCurrent();
		TView p = last;
		if( p !is null )
		do  {
			TView T = p.prev();
			CLY_destroy( p );
			p = T;
		} while( last !is null );
		freeBuffer();
		current = null;
		TView.shutDown();
	}

	void freeBuffer() {
		if( (options & ofBuffered) != 0 && buffer !is null )
		{
			//DeleteArray(buffer);
			buffer = null;
		}
	}

	private static void doCalcChange( TView p, void *d ) {
		TRect  r;
		p.calcBounds(r, *cast(TPoint*)d);
		p.changeBounds(r);
	}

	override void changeBounds( in TRect bounds ) {
		TPoint d;
		
		d.x = (bounds.b.x - bounds.a.x) - size.x;
		d.y = (bounds.b.y - bounds.a.y) - size.y;
		if( d.x == 0 && d.y == 0 )
		{
			setBounds(bounds);
			drawView();
		}
		else
		{
			freeBuffer();
			setBounds( bounds );
			clip = getExtent();
			getBuffer();
			lock();
			forEach( &doCalcChange, &d );
			unlock();
		}
	}

	void getBuffer() {
		if( (state & sfExposed) != 0 ) {
			if( (options & ofBuffered) != 0 && (buffer is null)) {
				buffer = new CharInfo[size.x * size.y];
			}
		}
	}

	private static void addSubviewDataSize( TView p, void *T ) {
		*(cast(uint *)T) += (cast(TGroup )p).dataSize();
	}
	
	override uint dataSize() {
		uint T = 0;
		forEach( &addSubviewDataSize, &T );
		return T;
	}

	override void endModal( Command command ) {
		if( (state & sfModal) != 0 )
			endState = command;
		else
			TView.endModal( command );
	}

}