module tinputline;

import std.algorithm : min, max;
import std.typecons;

import tvision;
import osclipboard;

const ilValidatorBlocks = 1;

private wchar rightArrow;
private wchar leftArrow;

private immutable ubyte[] cpInputLine = [0x13, 0x13, 0x14, 0x15];
private immutable TPalette palette = immutable(TPalette)(cpInputLine);

enum Select {
	All, None
}

alias bool delegate(in char[] inputLineData) Validator;

class TInputLine : TView {

	private struct State {
		int curPos;
		int firstPos;
		int selStart;
		int selEnd;
		char[] data;
		int dataLen;

		void set(in ref State other) {
			dataLen = other.dataLen;
			data = other.data.dup;
			curPos = other.curPos;
			firstPos = other.firstPos;
			selStart = other.selStart;
			selEnd = other.selEnd;
		}
	}

	protected @property auto curPos() const { return curState.curPos; }
	protected @property auto firstPos() const { return curState.firstPos; }
	protected @property auto selStart() const { return curState.selStart; }
	protected @property auto selEnd() const { return curState.selEnd; }
	protected @property auto data() { return curState.data; }
	protected @property auto dataLen() const { return curState.dataLen; }

	string getData() const {
		return curState.data.idup;
	}

	protected @property void curPos(int param) { curState.curPos = param; }
	protected @property void firstPos(int param) { curState.firstPos = param; }
	protected @property void selStart(int param) { curState.selStart = param; }
	protected @property void selEnd(int param) { curState.selEnd = param; }
	protected @property void data(in char[] param) { curState.data = param.dup; }
	protected @property void dataLen(int param) { curState.dataLen = param; }


	private Validator validator;
	protected State curState, oldState;
 	private bool hideContent;
 	// IMHO exposing these two is a very bad idea, I added a couple of members to
 // work with them: setDataFromStr & getData. All TV code uses these new
 // members. If we don't hide them then we must compute the string length all
 // the time. SET.
	 private int maxLen;

	 this(in TRect bounds, int aMaxLen, Validator aValid = null) {
	 	super(bounds);
	 	maxLen = aMaxLen-1;
	 	validator = aValid;
	 	state |= sfCursorVis;
 		options |= ofSelectable | ofFirstClick;
 		modeOptions = defaultModeOptions;
 		hideContent = false;
	 }

	 override void draw() {
	 	int l, r;
		TDrawBuffer b;
		 
		ushort color=(state & sfFocused) ? getColor(2) : getColor(1);
		 
		b.moveChar(0,' ',color,size.x);
		if (hideContent) {
			int rest = dataLen - firstPos;
			if (rest>0)
		       b.moveChar(1,'*',color,min(size.x-2,rest));
		} else {
			b.moveStr(1, data[firstPos..$], color, size.x-2);
		}
		 
		if (canScroll(1))
			b.moveChar(size.x-1, /*rightArrow*/ 0x25b6, cast(ubyte)getColor(4),1);
		if (canScroll(-1))
			b.moveChar(0, /*leftArrow*/ 0x25c0,cast(ubyte)getColor(4),1);
		if (state & sfSelected) {
			l = selStart - firstPos;
		    r = selEnd - firstPos;
		    l = max(0,l);
		    r = min(size.x-2,r);
		    if (l < r)
		       b.moveChar(l+1,0,cast(ubyte)getColor(3),r-l);
		   }
		writeLine(0,0,size.x,size.y,b);
		setCursor(curPos-firstPos+1,0);
	}

 	void setHide(bool val) {
 		hideContent=val; 
 	}

 	override void getData(void *rec) {
		*cast(char[]*)rec = curState.data;
	}

	override void setData(void *rec) {
		data = *cast(string*)rec;
		dataLen = data.length;
	 	selectAll(Select.All);
	}

	override uint dataSize() {
		return (char[]).sizeof;
		//return data.length;
		/*uint dSize=0;

		if (validator)
			dSize = validator.transfer(data, null, TVTransfer.vtDataSize);
		if (dSize == 0)
			dSize = maxLen+1;
		return dSize*cellSize;*/
	}

	override ref immutable(TPalette) getPalette() const {
	 	return palette;
	}

	uint setModeOptions(uint newOps) { 
		uint old = modeOptions;
		modeOptions = newOps;
		return old; 
	}
 	
 	uint getModeOptions() {
 		return modeOptions; 
 	}
 
 	static uint setDefaultModeOptions(uint newOps) { 
 		uint old = defaultModeOptions; 
 		defaultModeOptions = newOps; 
 		return old; 
 	}

 	static uint getDefaultModeOptions() { 
 		return defaultModeOptions; 
 	}
 	

 	private void deleteSelect() {
		if (selStart < selEnd) {
			//CLY_memcpy(data+selStart*cellSize,data+selEnd*cellSize,(dataLen-selEnd+1)*cellSize);
			data = data[0..selStart] ~ data[selEnd..$];
			dataLen = dataLen - (selEnd - selStart);
			curPos = selStart;
		}
	}

 	/*
 	Used internally to ensure the cursor is at a visible position, unselect
	the text and force a draw.
	*/
	private void makeVisible() {
		if (firstPos > curPos)
			firstPos = curPos;
		int i = curPos - size.x+2;
		if (firstPos < i)
			firstPos=i;
		drawView();
	}

	private bool canScroll( int delta ) {
		if (delta < 0)
			return firstPos > 0;
		else if (delta > 0)
			return (dataLen - firstPos + 2) > size.x;
		else
			return false;
	}

	private void saveState() {
		if (validator) {// Save data to unroll
			oldState.set(curState);
		}
	}

	private void restoreState() {
		if (validator) {// Unroll the changes
			curState.set(oldState);
	   }
	}

	private bool checkValid(Flag!"noAutoFill" noAutoFill) {
		if (validator) {
		// IMPORTANT!!! The validator can write more than maxLen chars.
			if (!validator(data, /*noAutoFill*/)) {
				restoreState();
				return false;
			} else {
				int newLen = data.length;//recomputeDataLen();
				if (curPos >= dataLen && newLen > dataLen)
					curPos=newLen;
				dataLen=newLen;
				return true;
			}
		}
		return true;
	}

	private void assignPos(int index, int val) {
		data[index] = cast(char)val;
	}

	/**[txh]********************************************************************

	  Description:
	  Inserts a character at the cursor position. If the text is currently
	selected it's removed. If a validator is defined it's called. This basic
	input line have a fixed size and will refuse to insert the character if
	there is not enough space, but the virtual resizeData() is called giving
	a chance to create variable size input lines.@*
	  I (SET) moved it to allow insertions from sources other than the keyboard
	emulating it's behavior.
	  
	  Return: False if the validator canceled the character, otherwise True.
	  
	***************************************************************************/
	// TODO: The validator can't be 8 bits for an Unicode class.
	bool insertChar(uint value) 	{
		saveState();
		// Operate
		if (insertModeOn())
	    	deleteSelect();
		//if (( insertModeOn() && lineIsFull()) || (!insertModeOn() && posIsEnd()))
	    //	resizeData();

		if (insertModeOn()) {
	    	if (!lineIsFull()) {
				int to = curPos+1 + dataLen-curPos;
				data = data[0..curPos] ~ [cast(char)0] ~ data[curPos..$];
	       		/*memmove(data+(curPos+1)*cellSize,
						data+curPos*cellSize,
						((dataLen-curPos)+1)*cellSize);*/
	       		dataLen = dataLen+1;
	       		if (firstPos > curPos)
	          		firstPos = curPos;
	       		assignPos(curPos,value);
				curPos = curPos + 1;
			}
		} else if (dataLen==curPos) {
	    	assignPos(curPos+1,0);
	    	data[curPos+1]=0;
		} else {
			if (firstPos>curPos)
	       		firstPos=curPos;
	    	if (curPos==dataLen) {
	       		dataLen = dataLen + 1;
			}
	    	assignPos(curPos,value);
			curPos = curPos + 1;
	   	}

	 	return checkValid(No.noAutoFill);
	}

	bool insertCharEv(ref TEvent event) {
		TGKey.fillCharCode(event);
		//printf("insertChar de Unicode: U+%04X\n",event.keyDown.charCode);
	 	if (event.keyDown.charCode>=' ' && event.keyDown.charCode<0xFF00) {
	    	if (!insertChar(event.keyDown.charCode))
				clearEvent(event);
			return true;
		}
		return false;
	}

	// TODO: Get the clipboard in unicode format
	bool pasteFromOSClipboard() {
		//if (sizeof(T) != 1) return false;
		/*uint size,i;
		T *p=(T *)TVOSClipboard.paste(1, size);
		if (p) {
			for (i=0; i<size; i++) {
				insertChar(p[i]);
				selStart=selEnd=0; // Reset the selection or we will delete the last insertion
			}
			makeVisible();
	    	return true;
		}*/
		return false;
	}

	void copyToOSClipboard() {
	 //if (sizeof(T)==1)
	    TVOSClipboard.copy(1, data[selStart..selEnd]);
	 // else if 2 ....
	 // TODO: Put to the clipboard in unicode format
	}

	void adjustSelectBlock(int anchor) {
		if( curPos < anchor ) {                  
			selStart = curPos; 
			selEnd = anchor;   
		} else {                  
			selStart = anchor; 
			selEnd = curPos;   
		}
	}

	override void handleEvent(ref TEvent event) {
		KeyCode key;
		bool extendBlock;
		TView.handleEvent(event);

		int delta, anchor=0;
		if ((state & sfSelected)!=0) {
			switch (event.what) {
				case evMouseDown:
					if (event.mouse.buttons==mbMiddleButton && TVOSClipboard.isAvailable() > 1) {
						pasteFromOSClipboard();
					} else if (canScroll(delta = mouseDelta(event))) {
	               		do {
	                  		if (canScroll(delta)) {
	                     		firstPos = firstPos + delta;
	                     		drawView();
	                    	}
	                  	} while (mouseEvent(event,evMouseAuto));
					} else if (event.mouse.doubleClick) {
	               		selectAll(Select.All);
					} else {
						anchor=mousePos(event);
						do {
							if (event.what==evMouseAuto && canScroll(delta=mouseDelta(event)))
								firstPos = firstPos+delta;
	                  		curPos=mousePos(event);
	                  		adjustSelectBlock(anchor);
	                  		drawView();
	                 	} while (mouseEvent(event,evMouseMove | evMouseAuto));
	               		if (TVOSClipboard.isAvailable()>1) {
	                  		copyToOSClipboard();
	                  	}
					}
					clearEvent(event);
					break;
				case evKeyDown:
					key = ctrlToArrow(event.keyDown.keyCode);
					extendBlock = false;
					if (key & KeyCode.kbShiftCode) {
					   KeyCode keyS = cast(KeyCode)(key & (~KeyCode.kbShiftCode));
						if (keyS==KeyCode.kbHome || keyS==KeyCode.kbLeft || keyS==KeyCode.kbRight || keyS==KeyCode.kbEnd) {
							if (curPos==selEnd)
	                    		anchor=selStart;
	                  		else
								anchor=selEnd;
							key = keyS;
							extendBlock=true;
						}
					}            
					switch (key) {
					   case KeyCode.kbLeft:
							if (curPos>0)
							   curPos = curPos - 1;
							break;
					   case KeyCode.kbRight:
							if (!posIsEnd()) {
								curPos = curPos + 1;
							}
							break;
					   case KeyCode.kbHome:
							curPos=0;
							break;
					   case KeyCode.kbEnd:
							curPos=dataLen;
							break;
					   case KeyCode.kbBackSpace:
							if (curPos>0) {
							   saveState();
							   selStart=curPos-1;
							   selEnd  =curPos;
							   deleteSelect();
							   if (firstPos>0)
								  firstPos = firstPos - 1;
							   checkValid(Yes.noAutoFill);
							}
							break;
					   case KeyCode.kbDelete:
							saveState();
							if (selStart==selEnd) {
								if (!posIsEnd()) {
									selStart=curPos;
									selEnd  =curPos+1;
								 }
							}
							deleteSelect();
							checkValid(Yes.noAutoFill);
							break;
					   case KeyCode.kbInsert:
							setState(sfCursorIns,!(state & sfCursorIns));
							break;
					   case KeyCode.kbCtrlY:
							assignPos(0,EOS);
							curPos = 0;
							dataLen = 0;
							break;
					   // Let them pass even if these contains a strange ASCII (SET)
					   case KeyCode.kbEnter:
					   case KeyCode.kbTab:
							return;
					   default:
							if (!insertCharEv(event))
							   return;
					  }
					if (extendBlock) {
						adjustSelectBlock(anchor);
					} else {
						selStart=0;
						selEnd=0;
					}
					makeVisible();
					clearEvent(event);
					break;
				default:
					break;
			}
		}
	}

	void selectAll( Select select ) {
		selStart=0;
		if (select == Select.All) {
			curPos = dataLen;
			selEnd = dataLen;
		} else {
			curPos = 0;
			selEnd = 0;
		}
		firstPos = max(0, curPos-size.x+2);
		if (TVOSClipboard.isAvailable() > 1) {
	    	copyToOSClipboard();
		}
		drawView();
	}

	void setDataFromStr(in char[] str) {
		data = str;
		dataLen = data.length;
	}

	void setValidator(Validator aValidator) {
 		validator = aValidator;
	}

	override void setState(ushort aState, bool enable) {
		bool ownerIsVisible = owner && (owner.state & sfActive);
		bool weAreLosingTheFocus = aState==sfFocused && enable==false;
		bool wantToBlockIfInvalid = (modeOptions & ilValidatorBlocks);
	 	if (validator && wantToBlockIfInvalid  && ownerIsVisible &&  weAreLosingTheFocus) {
			Validator v = validator;
	    	validator = null;             // Avoid nested tests
	    	bool valid = v(data); // Check if we have valid data
	    	validator = v;
	    	if (!valid)                   // If not refuse the focus change
	       		return;
	   }
		TView.setState(aState,enable);
		if (aState==sfSelected || (aState==sfActive && (state & sfSelected)))
			selectAll(enable ? Select.All : Select.None);
	}

	override bool valid(Command cmd) {
		if (validator) {
	    	if (cmd == cm.Valid)
				/*return validator.status == vsOk;*/
				return true;
			else if (cmd != cm.Cancel) {
				if (!validator(data)) {
					owner.current = null;
					select();
					return false;
	            }
	        }
	   }
		return true;
	}

 // Inline helpers to make the code cleaner
	private int insertModeOn() {
		return (state & sfCursorIns) == 0;
	}

	private int lineIsFull() {
		return dataLen >= maxLen;
	}

	private int posIsEnd() {
		return curPos >= dataLen;
	}

 // To fine tune the behavior. SET.
 private static uint defaultModeOptions;
 private uint modeOptions;

	private int mouseDelta( ref TEvent event ) {
		TPoint mouse = makeLocal( event.mouse.where );
	 
		if (mouse.x <= 0)
			return -1;
		else if (mouse.x >= size.x-1)
			return 1;
		else
			return 0;
	}

	private int mousePos( ref TEvent event ) {
		TPoint mouse=makeLocal(event.mouse.where);
	 	mouse.x = max(mouse.x,1);
	 	int pos = mouse.x+firstPos-1;
	 	pos = max(pos,0);
	 	pos = min(pos,dataLen);
	 	return pos;
	 }

}