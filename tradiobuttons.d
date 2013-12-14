module tradiobuttons;

import tvision;

static string button = " ( ) ";
static wchar check = '*';

class TRadioButtons : TCluster {

	private uint[] enableMasks;
    private TView[] enableViews;
    private int enableCViews;

	this(in TRect bounds, TSItem *aStrings) {
		super(bounds, aStrings);
	}

	void setEnableMask( uint[] masks, TView[] views, int cViews ) {
		enableMasks = masks;
		enableViews = views;
		enableCViews = cViews;
    }

    override void draw() {
	    drawBox( button, check );
	}

	override bool mark( int item ) {
	    return cast(uint)item == value;
	}

	override void press( int item ) {
	    value = item;
	    TCluster.press(item);
	    evaluateMasks();
	}

	override void movedTo( int item ) {
	    value = item;
	    TCluster.movedTo(item);
	    evaluateMasks();
	}

	override void setData( void * rec ) {
	    TCluster.setData(rec);
	    sel = value;
	    evaluateMasks();
	}

	void evaluateMasks() {
	    if( !enableMasks )
	        return;

	    uint theMask = enableMasks[value];
	    for( uint i = 0, mask = 1; i < enableCViews; mask <<= 1, i++ ) {
	        TView view = enableViews[i];
	        if( theMask & mask ) {// Enable this view
				if( view.state & sfDisabled )
					view.setState( sfDisabled, false );
			} else {// Disable this view
				if( !( view.state & sfDisabled ) )
					view.setState( sfDisabled, true );
			}
		}
	}

	override uint dataSize() {
	    return 4;
	}
}