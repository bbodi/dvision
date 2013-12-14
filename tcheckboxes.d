module tcheckboxes;

import tvision;

static string button = " [ ] ";

class TCheckBoxes : TCluster {

	this( in TRect bounds, TSItem *aStrings) {
		super(bounds, aStrings);
	}

	override void draw() {
	    drawBox( button, 'X' );
	}

	override bool mark(int item) {
	    return (value & (1 <<  item)) != 0;
	}

	override void press(int item) {
	    value = value^(1 << item);
	    TCluster.press(item);
	}

}

