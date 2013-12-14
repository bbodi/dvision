module grid;

import tvision;

class Grid : TGroup {

	private TView[][] cells;

	this(in TRect bounds, TView[][] cells) {
		super(bounds);
		this.cells = cells;
	}

	override void draw() {

	}

}