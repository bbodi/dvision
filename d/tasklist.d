module tasklist;

import tvision;
import std.datetime;
import std.conv;
import std.stream;
import configfile;

private wchar columnSeparator = 0x179;
private immutable ubyte[] cpListViewer = [0x1A, 0x1A, 0x1B, 0x1C, 0x1D];
private immutable TPalette palette = immutable(TPalette)( cpListViewer);

abstract class Listnode(T) {

	this(){}

	this(Elem* ins) {
		deSerialize(ins);
	}

	ulong getId() const;
	ulong getParentId() const;
	Elem serialize() const;
	void deSerialize(Elem*);
	void drawCellTo(ref TDrawBuffer b, TreeNode!(T)* cell, int column);
}

class Task : Listnode!Task {
	private ulong id;
	private string name;
	private ulong parentId;
	private Duration workedTime;
	private Duration todayWorkedTime;
	private Duration loggedTime;
	private Date lastWorkingDay;

	private Task parentTask;

	this(Elem* ins) {
		super(ins);
	}

	this(ulong id, string name, ulong parentId = 0) {
		this.id = id;
		this.name = name;
		this.parentId = parentId;
	}

	override Elem serialize() const {
		Elem data;
		data.id.set(id);
		data.name.set(name);
		data.parentId.set(parentId);
		writeDuration(data.workedTime, workedTime);
		writeDuration(data.todayWorkedTime, todayWorkedTime);
		writeDuration(data.loggedTime, loggedTime);
		data.lastWorkingDay.set(lastWorkingDay.toSimpleString());
		return data;
	}

	override void deSerialize(Elem* data) {
		id = data.id.value!ulong;
		name = data.name.value!string;
		parentId = data.parentId.value!ulong;
		workedTime = readDuration(data.workedTime);
		todayWorkedTime = readDuration(data.todayWorkedTime);
		loggedTime = readDuration(data.loggedTime);
		lastWorkingDay = Date.fromSimpleString(data.lastWorkingDay.value!string);
	}


	override ulong getId() const {
		return id;
	}

	override ulong getParentId() const {
		return parentId;
	}

	override void drawCellTo(ref TDrawBuffer b, TreeNode!(Task)* cell, int column) {
		switch(column) {
			case 0:
				b.moveStr( 0, cell.data.name, 30 );
				break;
			case 1:
				b.moveStr( 0, cell.data.todayWorkedTime.toString(), 30 );
				break;
			case 2:
				b.moveStr( 0, cell.data.workedTime.toString(), 30 );
				break;
			case 3:
				b.moveStr( 0, cell.data.loggedTime.toString(), 30 );
				break;
			default:
				return;
		}
	}

	private void addWorkedTime(Duration dur) {
		workedTime += dur;
	}

	void addTodayWorkedTime(Duration dur) {
		todayWorkedTime += dur;
		addWorkedTime(dur);
	}

	Duration getTodayWorkedTime() const {
		return todayWorkedTime;
	}
	
}

private Duration readDuration(Elem* data) {
	long d, h, m, s;
	d = data.days.value!long;
	h = data.hours.value!long;
	m = data.minutes.value!long;
	s = data.seconds.value!long;
	return days(d) + hours(h) + minutes(m) + seconds(s);
}

private void writeDuration(Elem* data, in ref Duration dur) {
	data.days.set(dur.days);
	data.hours.set(dur.hours);
	data.minutes.set(dur.minutes);
	data.seconds.set(dur.seconds);
}


struct TreeNode(T) {
	T data;
	TreeNode!(T)*[] children;
	TreeNode!(T)* parent;
	bool opened;
	bool selected;

	TreeNode!T* addChild(T child) {
		auto childNode = new TreeNode!T(child);
		addChild(childNode);
		return childNode;
	}

	void addChild(TreeNode!T* childNode) {
		childNode.parent = &this;
		children ~= childNode;
	}

	void open() {
		opened = true;
	}

	void close() {
		opened = false;
	}

	void toggle() {
		opened = !opened;
	}
}

class TreeView(T) : TView, TStreamable {

	alias TreeNode!T Node;

	private struct Nodes {
		private Node*[] items;
		private Node*[ulong] itemsByKey;
		private Node*[int] itemsByDrawingOrder;

		alias items this;
	}

	Nodes items;

	@property Node* focusedNode() {
		return focusedRow in items.itemsByDrawingOrder ? items.itemsByDrawingOrder[focusedRow] : null;
	}

	int focusedColumn;
	int focusedRow;
	int drawedRowCount;

	TScrollBar hScrollBar;
    TScrollBar vScrollBar;
	private int[] columnWidths;
	private @property int columns() const {return columnWidths.length;}

	this(in TRect bounds, TScrollBar aVScrollBar, int[] columnWidths = null) {
    	super(bounds);
    	options |= ofFirstClick | ofSelectable | ofBeVerbose;
	    eventMask |= evBroadcast;
		this.columnWidths = columnWidths != null ? columnWidths : [20]; // [(bounds.b - bounds.a).x
	    hScrollBar = null;
	    vScrollBar = aVScrollBar;
    }

	void addItem(T item) {
		auto node = new Node(item);
		items ~= node;
		items.itemsByKey[item.getId()] = node;
		drawView();
	}

	void addChild(Node* parent, T child) {
		parent.addChild(child);
		drawView();
	}

	Node* getNode(ulong uniqueKey) {
		return items.itemsByKey[uniqueKey];
	}

	override string streamableName() const {
		return TreeView!T.stringof;
	}

	override void changeBounds( in TRect bounds ) {
	    TView.changeBounds( bounds );
	    if( hScrollBar !is null )
	        hScrollBar.setStep( size.x, 1 );
	}

	override void draw() {
		clear();
		drawedRowCount = drawItems(items);
	}

	const spaceForToggleChar = 2;

	void clear() {
		TDrawBuffer b;
		foreach(y; 0..size.y) {
			clearRow(b);
			writeLine( 0, y, size.x+1, 1, b );
		}
	}

	TDrawBuffer b;
	int drawItems(Node*[] nodes, in int row = 0, int indent = 0) {
		int drawedRows = 0;
		foreach(node; nodes) {
			int rowIndex = row + drawedRows;
			drawOneRow(rowIndex, indent, node);
			++drawedRows;
			if (node.opened && node.children) {
				drawedRows += drawItems(node.children, rowIndex+1, indent+2);
			}
		}
		return drawedRows;
	}

	private void drawOneRow(int rowIndex, int indent, Node* node) {
		clearRow(b);
		b.setOffset(indent);
		drawColumnsOfOneRow(indent, node, rowIndex);
		b.setOffset(indent);
		if (node.children) {
			b.putChar( 0, node.opened ? '-' : '+' );
		}
		if( showMarkers ) {
			b.putChar( 0, specialChars[0] );
			b.putChar( size.x+1-2, specialChars[0+1] );
		}
		writeLine( 0, rowIndex, size.x+1, 1, b );
	}

	private void drawColumnsOfOneRow(int indent, Node* node, int rowIndex) {
		int columnIndent = indent;
		foreach(column; 0..columns) {
			b.setOffset(columnIndent + spaceForToggleChar);
			drawOneCell(node, column);
			b.setAttrib(0);
			items.itemsByDrawingOrder[rowIndex] = node;
			columnIndent += columnWidths[column];
		}
	}

	private void drawOneCell(Node* node, int column) {
		int attrib = getAttribForCell(node, column);
		b.setAttrib(attrib);
		node.data.drawCellTo(b, node, column);
	}

	private int getAttribForCell(Node* node, int colIndex) {
		if (node is focusedNode) {
			if (colIndex == focusedColumn) {
				return BACKGROUND_RED;
			} else {
				return BACKGROUND_GREEN;
			}
		} else {
			return 0;
		}
	}

	private void clearRow(ref TDrawBuffer b) const {
		int width = size.x+1;
		b.setOffset(0);
		b.moveChar( 0, ' ', 30, width );
	}

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}


	bool isSelected( int index ) const {
		return index == focusedRow;
	}

	T getFocusedItem() {
		return focusedNode.data;
	}

	override void handleEvent( ref TEvent event ) {
	    int mouseAutosToSkip = 4;

	    TView.handleEvent(event);

	    if( event.what == evMouseDown ) {
	        // They must be before doubleClick to avoid "b4 double click"
	       /* if( event.mouse.buttons == mbButton4 ) {
	            focusItemNum(focused - size.y );
	            clearEvent( event );
	            return;
			}
	        if( event.mouse.buttons == mbButton5 ) {
				focusItemNum(focused + size.y );
	            clearEvent( event );
	            return;
			}*/
			if( event.mouse.doubleClick ) {
				selectItem();
	            clearEvent( event );
	            return;
			}
			ccIndex oldItem =  focusedRow;
	        TPoint mouse = makeLocal( event.mouse.where );
			int colWidth = size.x;
	        ccIndex newItem = mouse.y + (size.y * (mouse.x / colWidth));
	        int count = 0;
	        do  {
	            if( newItem != oldItem ) {
	                focusItemByIndex( newItem );
	            }
	            oldItem = newItem;
	            mouse = makeLocal( event.mouse.where );
	            if( mouseInView( event.mouse.where ) ) {
	                newItem = mouse.y + (size.y * (mouse.x / colWidth));
	            } else {
					if( event.what == evMouseAuto )
						count++;
					if( count == mouseAutosToSkip ) {
						count = 0;
						if( mouse.y < 0 )
							newItem = focusedRow - 1;
						else if( mouse.y >= size.y )
							newItem = focusedRow + 1;
					}
				}
			} while( mouseEvent( event, evMouseMove | evMouseAuto ) );
			focusItemByIndex( newItem );
			if( event.mouse.doubleClick )
				selectItem();
	        clearEvent( event );
		} else if( event.what == evKeyDown ) {
			ccIndex newItem;
			bool spacePressed = event.keyDown.charScan.charCode ==  ' ';
			switch (ctrlToArrow(event.keyDown.keyCode)) {
				case KeyCode.kbUp:
					newItem = focusedRow - 1;
					break;
				case KeyCode.kbSpace:
					toggleRow();
					return;
				case KeyCode.kbEnter:
					selectItem();
					return;
				case KeyCode.kbDown:
					newItem = focusedRow + 1;
					break;
				case KeyCode.kbPgDn:
					newItem = focusedRow + size.y;
					break;
				case  KeyCode.kbPgUp:
					newItem = focusedRow - size.y;
					break;
				case KeyCode.kbHome:
					newItem = 0;
					break;
				case KeyCode.kbEnd:
					newItem = (size.y ) - 1;
					break;
				case KeyCode.kbCtrlPgDn:
					//newItem = range - 1;
					break;
				case KeyCode.kbCtrlPgUp:
					newItem = 0;
					break;
				case KeyCode.kbTab:
					selectNextCol();
					return;
				case KeyCode.kbLeft:
					selectPrevCol();
					return;
				case KeyCode.kbRight:
					selectNextCol();
					return;
				case KeyCode.kbDelete:
					deleteItem();
					return;
				default:
					return;
			}
			focusItemByIndex(newItem);
	        clearEvent(event);
	    } else if( event.what == evBroadcast ) {
	        if( (options & ofSelectable) != 0 ) {
				bool scrollBarClicked = cast(TView)event.message.infoPtr is hScrollBar || cast(TView)event.message.infoPtr is vScrollBar;
				if (event.message.command == cm.ScrollBarClicked && scrollBarClicked) {
						select();
				} else if( event.message.command == cm.ScrollBarChanged ) {
					if (vScrollBar is cast(TView)event.message.infoPtr ) {
						focusItemByIndex( vScrollBar.value );
						drawView();
					} else if( hScrollBar is cast(TView)event.message.infoPtr ) {
						drawView();
					}
				}
			}
		}
	}

	void focusItemByIndex(int index) {
		if (index >= drawedRowCount) {
			return;
		} else if (index < 0) {
			return;
		}
		focusedRow = index;
		focusItem(items.itemsByDrawingOrder[index]);
	}

	private void focusItem( Node* node ) {
		drawView();
	    if (owner && (options & ofBeVerbose))
			messageToDesktop(evBroadcast, cm.ListItemFocused, this);
	}


	private void toggleRow() {
		if (focusedNode is null) {
			return;
		}
		focusedNode.toggle();
		drawView();
	}

	private void selectNextCol() {
		if (++focusedColumn >= columns) {
			focusedColumn = 0;
		}
		drawView();
	}

	private void selectPrevCol() {
		if (--focusedColumn < 0) {
			focusedColumn = columns-1;
		}
		drawView();
	}

	void selectItem() {
	    message( owner, evBroadcast, cm.ListItemSelected, this );
	}

	void deleteItem() {
	    message( owner, evBroadcast, cm.ListItemDeleted, this );
	}

	void setRange( ccIndex aRange ) {
	    //range = aRange;
		if (focusedRow >= aRange)
			focusedRow = (aRange - 1 >= 0) ? aRange - 1 : 0;
	    if( vScrollBar !is null ) {
			vScrollBar.setParams( focusedRow,
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

	private static void writeItems(Elem* data, in Node*[] items) {
		//os.write(items.length);
		void writeSingleItem(in Node* node) {
			Elem item = node.data.serialize();
			item.opened.set(node.opened);
			data.items.add(item);
			//os.write(cast(byte)node.opened);
		}
		void writeChildren(in Node* node) {
			if (node.children) {
				foreach(child; node.children) {
					writeChildren(child);
				}
			}
			writeSingleItem(node);
		}
		foreach(item; items) {
			writeChildren(item);
		}
	}

	override void write( Elem* data ) const {
		super.write(data);
		writeItems(data, items);
		data.focusedColumn.set(focusedColumn);
		data.focusedRow.set(focusedRow);
		foreach(w; columnWidths) {
			data.columnWidths.add(w);
		}
		/*writeItems(os, items);
		os.write(cast(int)focusedColumn);
		os.write(cast(int)focusedRow);
		os.write(columnWidths.length);
		foreach(w; columnWidths) {
			os.write(w);
		}*/

		//TScrollBar hScrollBar;
		//TScrollBar vScrollBar;
	}

	private static Nodes readItems(Elem* data) {
		Nodes items;
		Node*[] tmpForChildren;
		foreach(itemData; data.array) {
			T item = new T(itemData);
			auto node = new Node(item);
			node.opened = itemData.opened.value!bool;
			if (item.getParentId() == 0) {
				items ~= node;
				items.itemsByKey[item.getId()] = node;
			} else {
				items.itemsByKey[item.getId()] = node;
				tmpForChildren ~= node;
			}
		}
		foreach(node; tmpForChildren) {
			items.itemsByKey[node.data.getParentId()].addChild(node);
		}
		return items;
	}

	/*private static Nodes readItems(Elem* ins) {
		Nodes items;
		Node*[] tmpForChildren;
		int rootItems;
		ins.read(rootItems);
		int readRootItems = 0;
		while (readRootItems < rootItems) {
			T item = new T(ins);
			auto node = new Node(item);
			byte opened;
			ins.read(opened);
			node.opened = opened == 1;
			if (item.getParentId() == 0) {
				items ~= node;
				items.itemsByKey[item.getId()] = node;
				++readRootItems;
			} else {
				items.itemsByKey[item.getId()] = node;
				tmpForChildren ~= node;
			}
		}
		foreach(node; tmpForChildren) {
			items.itemsByKey[node.data.getParentId()].addChild(node);
		}
		return items;
	}*/

	override void read( Elem* data ) {
		super.read(data);
		items = readItems(data.items);
		focusedColumn = data.focusedColumn.value!int;
		focusedRow = data.focusedRow.value!int;
		foreach(w; data.columnWidths.array()) {
			columnWidths ~= w.value!int;
		}
		/*items = readItems(ins);
		ins.read(focusedColumn);
		ins.read(focusedRow);
		ins.read(columns);
		columnWidths.length = columns;
		foreach(ref colWidth; columnWidths) {
			ins.read(colWidth);
		}*/

		//TScrollBar hScrollBar;
		//TScrollBar vScrollBar;
	}

	this(Elem* inStream) {
		super(inStream);
	}
}
/*
version(unittest) {
	class StringNode : Listnode!StringNode {
		this(Elem* ins) {
			super(ins);
		}
		private ulong id;
		private ulong parentId;
		private string str;

		this(ulong id, string str, ulong parent = 0) {
			this.id = id;
			this.str = str;
			this.parentId = parent;
		}

		override ulong getId() const {return id;}
		override ulong getParentId() const {return parentId;}
		override Elem serialize() const {
			Elem data;
			data.id.set(id);
			data.parentId.set(parentId);
			data.str.set(str);
			return data;
		}

		override void deSerialize(Elem* elem) {
			this.id = elem.id.value!ulong;
			this.parentId = elem.parentId.value!ulong;
			this.str = elem.str.value!string;
		}

		override void drawCellTo(ref TDrawBuffer b, TreeNode!StringNode* cell, int column) {}
	}
}



unittest {
	alias TreeNode!StringNode TestNode;
	auto a = new StringNode(1, "a");
	auto b = new StringNode(2, "b");
	auto b1 = new StringNode(3, "b -> b1", 2);
	auto c = new StringNode(4, "c");
	auto c1 = new StringNode(5, "c -> c1", 4);
	auto d1 = new StringNode(6, "c -> d1", 4);
	auto e2 = new StringNode(7, "d1 -> e2", 6);
	auto stream = new MemoryStream();
	TreeView!StringNode.writeItems(stream, [new TestNode(a), 
											new TestNode(b, 
												[new TestNode(b1)]
											), 
											new TestNode(c, [
												new TestNode(c1), 
												new TestNode(d1, 
													[new TestNode(e2)]
												)]
											)]
								  );
	ubyte[] data = stream.data();

	const idSize = ulong.sizeof;
	const parentIdSize = ulong.sizeof;
	const strLengthSize = size_t.sizeof;
	const strSize = (a.str ~ b.str ~ b1.str ~ c.str ~ c1.str ~ d1.str ~ e2.str).length;
	const rootItemsCountSize = size_t.sizeof;
	const countOfAllItems = 7;
	const isOpenedFlagSize = 1;
	const expectedSize = (idSize + parentIdSize + strLengthSize + isOpenedFlagSize) * countOfAllItems + strSize + rootItemsCountSize;
	assert(data.length == expectedSize);

	TreeView!StringNode.Nodes actual = TreeView!StringNode.readItems(new MemoryStream(data));
	assert(actual.items.length == 3, "Tree should store only root nodes!");
	auto _a = actual.items[0];
	auto _b = actual.items[1];
	auto _c = actual.items[2];
	assert(_a.data.str == a.str);
	assert(_b.data.str == b.str);
	assert(_c.data.str == c.str);
	assert(_a.children.length == 0);
	assert(_b.children.length == 1);
	assert(_c.children.length == 2);
	auto _d1 = _c.children[1];
	assert(_d1.children.length == 1);
}*/