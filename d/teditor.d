module teditor;
/*
import tvision;

import std.algorithm;
import std.string;
import std.utf;
import std.uni;
import std.typecons;
import std.conv;

private static const char dragFrame = '\xCD';
private static const char normalFrame = '\xC4';
private static const char modifiedStar = 15;

const int
  ufUpdate = 0x01,
  ufLine   = 0x02,
  ufView   = 0x04;

const int
  smExtend = 0x01,
  smDouble = 0x02;

const uint
  sfSearchFailed = uint.max;

const int
  cm.Save        = 80,
  cm.SaveAs      = 81,
  cm.Find        = 82,
  cm.Replace     = 83,
  cm.SearchAgain = 84;

const int
  cm.CharLeft    = 500,
  cm.CharRight   = 501,
  cm.WordLeft    = 502,
  cm.WordRight   = 503,
  cm.LineStart   = 504,
  cm.LineEnd     = 505,
  cm.LineUp      = 506,
  cm.LineDown    = 507,
  cm.PageUp      = 508,
  cm.PageDown    = 509,
  cm.TextStart   = 510,
  cm.TextEnd     = 511,
  cm.NewLine     = 512,
  cm.BackSpace   = 513,
  cm.DelChar     = 514,
  cm.DelWord     = 515,
  cm.DelStart    = 516,
  cm.DelEnd      = 517,
  cm.DelLine     = 518,
  cm.InsMode     = 519,
  cm.StartSelect = 520,
  cm.HideSelect  = 521,
  cm.IndentMode  = 522,
  cm.UpdateTitle = 523,
  cm.InsertText  = 524;

const int
  edOutOfMemory   = 0,
  edReadError     = 1,
  edWriteError    = 2,
  edCreateError   = 3,
  edSaveModify    = 4,
  edSaveUntitled  = 5,
  edSaveAs        = 6,
  edFind          = 7,
  edSearchFailed  = 8,
  edReplace       = 9,
  edReplacePrompt = 10;

const int
  efCaseSensitive   = 0x0001,
  efWholeWordsOnly  = 0x0002,
  efPromptOnReplace = 0x0004,
  efReplaceAll      = 0x0008,
  efDoReplace       = 0x0010,
  efBackupFiles     = 0x0100;

const int
  maxLineLength = 256;

// SET: Added these old constants here
const uint
  cm.Open       = 100,
  cm.New        = 101,
  cm.ChangeDrct = 102,
  cm.DosShell   = 103,
  cm.Calculator = 104,
  cm.ShowClip   = 105,
  cm.Macros     = 106;

private immutable ubyte[] cpIndicator = [0x02, 0x03];
private immutable ubyte[] cpEditor = [0x06, 0x07];

class TIndicator : TView {

    protected TPoint location;
    protected bool modified;

    this( in TRect bounds) {
    	super(bounds);
	    growMode = gfGrowLoY | gfGrowHiY;
	    location.x = location.y = 1;
	}

	override void draw() {
	    int color;
		char frame;
	    if( (state & sfDragging) == 0 ) {
	        color = getColor(1);
	        frame = dragFrame;
		} else {
			color = getColor(2);
	        frame = normalFrame;
		}

		TDrawBuffer b;
	    b.moveChar( 0, frame, color, size.x );
	    if( modified )
	        b.putChar( 0, modifiedStar );
	    string s = format(" %d:%d ", location.y+1,location.x+1);
	    b.moveCStr( 8-std.string.indexOf(s, ":"), s, color);
	    writeBuf(0, 0, size.x, 1, b);
	}

	override ref immutable(TPalette) getPalette() const {
	    static immutable TPalette palette = immutable(TPalette)( cpIndicator);
	    return palette;
	}

	override void setState( ushort aState, bool enable ) {
	    TView.setState(aState, enable);
	    if( aState == sfDragging )
	        drawView();
	}

	void setValue( TPoint aLocation, bool aModified ) {
	    if( (location !=  aLocation) || (modified != aModified) ) {
	        location = aLocation;
	        modified = aModified;
	        drawView();
		}
	}
}


class TEditor : TView {
	TScrollBar hScrollBar;
    TScrollBar vScrollBar;
    TIndicator indicator;
    char[] buffer;
    int bufSize;
    int bufLen;
    int gapLen;
    int selStart;
    int selEnd;
    int curPtr;
    TPoint curPos;
    TPoint delta;
    TPoint limit;
    int drawLine;
    int drawPtr;
    int delCount;
    int insCount;
    bool isValid;
    bool canUndo;
    bool modified;
    bool selecting;
    bool overwrite;
    bool autoIndent;

//   static TEditorDialog editorDialog;
    static ushort editorFlags = efBackupFiles | efPromptOnReplace;
    static string findStr;
    static string replaceStr;
    static TEditor clipboard;
    static int tabSize = 4;
    ubyte lockCount;
    ubyte updateFlags;
    int keyState;

    this( in TRect bounds, TScrollBar aHScrollBar, TScrollBar aVScrollBar, TIndicator aIndicator, int aBufSize ) {
		super(bounds);
		hScrollBar = aHScrollBar;
		vScrollBar = aVScrollBar;
		indicator = aIndicator;
		bufSize = aBufSize;
		canUndo = true;
		selecting = false;
		overwrite = false;
		autoIndent = false;

	    growMode = gfGrowHiX | gfGrowHiY;
	    options |= ofSelectable;
	    eventMask = evMouseDown | evKeyDown | evCommand | evBroadcast;
	    showCursor();
	    initBuffer();
	    if( buffer !is null )
	        isValid = true;
	    else {
	        editorDialog( edOutOfMemory );
	        bufSize = 0;
	        isValid = false;
	    }
	    setBufLen(0);
	}


	override void shutDown() {
	    doneBuffer();
	    TView.shutDown();
	}

	override void changeBounds( in TRect bounds ) {
	    setBounds(bounds);
	    delta.x = max(0, min(delta.x, limit.x - size.x));
	    delta.y = max(0, min(delta.y, limit.y - size.y));
	    update(ufView);
	}

	private int charPos( int p, int target ) {
	    int pos = 0;
	    while( p < target ) {
	        if( bufChar(p) == '\x09' )
		    	pos += tabSize - (pos % tabSize) - 1;
	        pos++;
	        p++;
	    }
	    return pos;
	}

	private int charPtr( int p, int target ) {
		int pos = 0;
		while( (pos < target) && (p < bufLen) && (bufChar(p) != '\x0D') && (bufChar(p) != '\x0A') ) {
	    	if( bufChar(p) == '\x09' )
		    	pos += tabSize - (pos % tabSize) -1;
		    pos++;
		    p++;
	    }
		if( pos > target )
			p--;
		return p;
	}

	private bool clipCopy() {
	    bool res = false;
	    if( (clipboard !is null) && (clipboard !is this) ) {
			res = clipboard.insertFrom(this);
	        selecting = false;
	        update(ufUpdate);
		}
	    return res;
	}

	private void clipCut() {
	    if( clipCopy() == true )
	        deleteSelect();
	}

	private void clipPaste() {
	    if( (clipboard !is null) && (clipboard !is this) )
	        insertFrom(clipboard);
	}


	private void convertEvent( ref TEvent event ) {
		if( event.what == evKeyDown ) {
			KeyCode key = event.keyDown.keyCode;
	        if( keyState != 0 ) {
	            if( key >= KeyCode.kbCtrlA && key <= KeyCode.kbCtrlZ )
	                key += KeyCode.kbA - KeyCode.kbCtrlA;
	            if( key >= KeyCode.kbShA && key<=KeyCode.kbShA )
	                key += KeyCode.kbA - KeyCode.kbShA;
			}
	        key = scanKeyMap(keyMap[keyState], key);
	        keyState = 0;
	        if( key != 0 ) {
	            if( (key & 0xFF00) == 0xFF00 ) {
	                keyState = (key & 0xFF);
	                clearEvent(event);
				} else {
	                event.what = evCommand;
	                event.message.command = key;
				}
			}
		}
	}

	private bool cursorVisible() {
	  return (curPos.y >= delta.y) && (curPos.y < delta.y + size.y);
	}

	private void deleteRange( int startPtr, int endPtr, bool delSelect) {
	    if( hasSelection() == true && delSelect == true ) {
	        deleteSelect();
	    } else {
	        setSelect(curPtr, endPtr, true);
	        deleteSelect();
	        setSelect(startPtr, curPtr, false);
	        deleteSelect();
		}
	}

	private void deleteSelect() {
	    insertText( "", No.selectText );
	}

	private void doneBuffer() {
	    buffer = null;
	}

	private void doSearchReplace() {
	    int cmd;
	    do  {
	        cmd = cm.Cancel;
	        if( search(findStr, editorFlags) == false ) {
	        	bool replaceAlAndDoReplace = (editorFlags & (efReplaceAll | efDoReplace)) == (efReplaceAll | efDoReplace);
	            if( !replaceAlAndDoReplace )
					editorDialog( edSearchFailed );
			} else if( (editorFlags & efDoReplace) != 0 ) {
	                cmd = cm.Yes;
	                if( (editorFlags & efPromptOnReplace) != 0 ) {
	                    TPoint c = makeGlobal( cursor );
	                    cmd = editorDialog( edReplacePrompt, c );
					}
	                if( cmd == cm.Yes ) {
	                    lock();
	                    insertText( replaceStr, No.selectText);
	                    trackCursor(false);
	                    unlock();
					}
			}
		} while( cmd != cm.Cancel && (editorFlags & efReplaceAll) != 0 );
	}

	private void doUpdate() {
	    if( updateFlags != 0 ) {
	        setCursor(curPos.x - delta.x, curPos.y - delta.y);
	        if( (updateFlags & ufView) != 0 )
	            drawView();
	        else if( (updateFlags & ufLine) != 0 )
				drawLines( curPos.y-delta.y, 1, lineStart(curPtr) );
	        if( hScrollBar !is null )
	            hScrollBar.setParams(delta.x, 0, limit.x - size.x, size.x / 2, 1);
	        if( vScrollBar !is null )
	            vScrollBar.setParams(delta.y, 0, limit.y - size.y, size.y - 1, 1);
	        if( indicator !is null )
	            indicator.setValue(curPos, modified);
	        if( (state & sfActive) != 0 )
	            updateCommands();
	        updateFlags = 0;
		}
	}

	override void draw() {
	    if( drawLine != delta.y ) {
	        drawPtr = lineMove( drawPtr, delta.y - drawLine );
	        drawLine = delta.y;
		}
	    drawLines( 0, size.y, drawPtr );
	}

	private void drawLines( int y, int count, int linePtr ) {
	    ushort color = getColor(0x0201);
	    while( count-- > 0 ) {
			CharInfo[maxLineLength] b;
	        formatLine( b, linePtr, delta.x+size.x, color );
	        writeBuf(0, y, size.x, 1, b[delta.x..$]);
	        linePtr = nextLine(linePtr);
	        y++;
		}
	}
	
	private int endianCol(int letra, int color) {
		return (((cast(uint)color)<<8) | (cast(uint)letra));
	}

	private static bool CALL(in TEditor edit, CharInfo[] drawBuf, ubyte color, int cx,
				   ref int offset, ref uint lineptr, ref int bufptr, int Width) {
		ubyte c;
		int count = cx - lineptr;
		if (count<=0) return true;
		do {
			c = edit.buffer[lineptr++];
			if (c == 0x0a || c == 0x0d || c == 0x09) {
				if (c == 0x09) {
					do {
						drawBuf[bufptr].ch = ' ';
						drawBuf[bufptr].attrib = color;
						bufptr++;
						offset++;
					} while ((offset % tabSize) != 0);
				} else {
					count = Width-offset;
					if (count <= 0)
						return true;
					while (count--) {
						drawBuf[bufptr].ch = ' ';
						drawBuf[bufptr].attrib = color;
						bufptr++;
					}
					return false;
				}
			} else {
				drawBuf[bufptr].ch = c;
				drawBuf[bufptr].attrib = color;
				bufptr++;
				offset++;
			}
			if (offset >= Width) {
				return false;
			}
			count--;
		} while (count);
		return true;
	}
	//#define CALL if (call10(this,(ushort *)DrawBuf,color,count,offset,LinePtr,bufptr,Width) == False) return
	private void formatLine( CharInfo[] drawBuf, uint LinePtr, int Width, ushort Colors ) {
		@property ubyte normalColor() { return (Colors & 0xff); }
		@property ubyte selectColor() { return (Colors >> 8) & 0xFF; }
		int count,offset,bufptr;
		ubyte color;
		bufptr = 0;
		offset = 0;
		if (selStart > LinePtr) {
			color = normalColor;
			count = selStart;
			if (CALL(this, drawBuf, color, count, offset, LinePtr, bufptr, Width) == false)
				return;
		}
		color = selectColor;
		count = curPtr;
		if (CALL(this, drawBuf, color, count, offset, LinePtr, bufptr, Width) == false)
			return;
		LinePtr += gapLen;
		count = selEnd+gapLen;
		if (CALL(this, drawBuf, color, count, offset, LinePtr, bufptr, Width) == false)
			return;
		color = normalColor;
		count = bufSize;
		if (CALL(this, drawBuf, color, count, offset, LinePtr, bufptr, Width) == false)
			return;
		count = Width-offset;
		//if (count<=offset) return;
		if (count<1) return;
		while (count--) {
			drawBuf[bufptr].ch = ' ';
			drawBuf[bufptr].attrib = color;
			bufptr++;
		}
	}

	private void find() {
	    TFindDialogRec findRec = TFindDialogRec( findStr, editorFlags );
	    if( editorDialog( edFind, &findRec ) != cm.Cancel ) {
			findStr = findRec.find;
	        editorFlags = findRec.options & ~efDoReplace;
	        doSearchReplace();
		}
	}

	private int getMousePtr( TPoint m ) {
	    TPoint mouse = makeLocal( m );
	    mouse.x = max(0, min(mouse.x, size.x - 1));
	    mouse.y = max(0, min(mouse.y, size.y - 1));
	    return charPtr(lineMove(drawPtr, mouse.y + delta.y - drawLine), mouse.x + delta.x);
	}

	override ref immutable(TPalette) getPalette() const {
	    static immutable TPalette palette = immutable(TPalette)( cpEditor);
	    return palette;
	}


	private void checkScrollBar( in ref TEvent event, in TScrollBar p, ref int d ) {
	    if( (cast(TScrollBar)event.message.infoPtr is p) && (p.value != d) ) {
			d = p.value;
			update( ufView );
		}
	}

	override void handleEvent( ref TEvent event ) {
	    TView.handleEvent( event );
	    //if (macros) macros.handleEvent(event,this);
	    convertEvent( event );
	    bool centerCursor = !cursorVisible();
	    ubyte selectMode = 0;
	    // SET: This way of getting the shift state is deprecated in our port, by
	    // now works.
		bool shiftPRessed = (TGKey.getShiftState() & (kbRightShiftDown | kbLeftShiftDown)) != 0;
	    if( selecting == true || shiftPRessed )
	        selectMode = smExtend;

	    switch( event.what ) {
	        case evMouseDown:
	            if( event.mouse.doubleClick == true )
	                selectMode |= smDouble;

	            do  {
	                lock();
	                if( event.what == evMouseAuto ) {
	                    TPoint mouse = makeLocal( event.mouse.where );
	                    TPoint d = delta;
	                    if( mouse.x < 0 )
	                        d.x--;
	                    if( mouse.x >= size.x )
	                        d.x++;
	                    if( mouse.y < 0 )
	                        d.y--;
	                    if( mouse.y >= size.y )
	                        d.y++;
	                    scrollTo(d.x, d.y);
					}
	                setCurPtr(getMousePtr(event.mouse.where), selectMode);
	                selectMode |= smExtend;
	                unlock();
				} while( mouseEvent(event, evMouseMove + evMouseAuto) );
	            break;

	        case evKeyDown:
	        	bool tabOrBetu = event.keyDown.charScan.charCode == 9 || ( event.keyDown.charScan.charCode >= 32 && event.keyDown.charScan.charCode < 255 );
	            if( tabOrBetu ) {
					lock();
	                if( overwrite == true && hasSelection() == false )
	                	if( curPtr != lineEnd(curPtr) )
	                    	selEnd = nextChar(curPtr);
						insertText( to!string(event.keyDown.charScan.charCode), No.selectText);
	                    trackCursor(centerCursor);
	                    unlock();
					} else {
						return;
					}
	            break;

	        case evCommand:
	            switch( event.message.command ) {
					case cm.InsertText:
			    		insertText(cast(string)event.message.infoPtr, No.selectText);
	                    break;
	                case cm.Find:
	                    find();
	                    break;
	                case cm.Replace:
	                    replace();
	                    break;
	                case cm.SearchAgain:
	                    doSearchReplace();
	                    break;
	                default:
	                    lock();
	                    switch( event.message.command ) {
	                        case cm.Cut:
	                            clipCut();
	                            break;
	                        case cm.Copy:
	                            clipCopy();
	                            break;
	                        case cm.Paste:
	                            clipPaste();
	                            break;
	                        case cm.Undo:
	                            undo();
	                            break;
	                        case cm.Clear:
	                            deleteSelect();
	                            break;
	                        case cm.CharLeft:
	                            setCurPtr(prevChar(curPtr), selectMode);
	                            break;
	                        case cm.CharRight:
	                            setCurPtr(nextChar(curPtr), selectMode);
	                            break;
	                        case cm.WordLeft:
	                            setCurPtr(prevWord(curPtr), selectMode);
	                            break;
	                        case cm.WordRight:
	                            setCurPtr(nextWord(curPtr), selectMode);
	                            break;
	                        case cm.LineStart:
	                            setCurPtr(lineStart(curPtr), selectMode);
	                            break;
	                        case cm.LineEnd:
	                            setCurPtr(lineEnd(curPtr), selectMode);
	                            break;
	                        case cm.LineUp:
	                            setCurPtr(lineMove(curPtr, -1), selectMode);
	                            break;
	                        case cm.LineDown:
	                            setCurPtr(lineMove(curPtr, 1), selectMode);
	                            break;
	                        case cm.PageUp:
	                            setCurPtr(lineMove(curPtr, -(size.y-1)), selectMode);
	                            break;
	                        case cm.PageDown:
	                            setCurPtr(lineMove(curPtr, size.y-1), selectMode);
	                            break;
	                        case cm.TextStart:
	                            setCurPtr(0, selectMode);
	                            break;
	                        case cm.TextEnd:
	                            setCurPtr(bufLen, selectMode);
	                            break;
	                        case cm.NewLine:
	                            newLine();
	                            break;
	                        case cm.BackSpace:
	                            deleteRange(prevChar(curPtr), curPtr, true);
	                            break;
	                        case cm.DelChar:
	                            deleteRange(curPtr, nextChar(curPtr), true);
	                            break;
	                        case cm.DelWord:
	                            deleteRange(curPtr, nextWord(curPtr), false);
	                            break;
	                        case cm.DelStart:
	                            deleteRange(lineStart(curPtr), curPtr, false);
	                            break;
	                        case cm.DelEnd:
	                            deleteRange(curPtr, lineEnd(curPtr), false);
	                            break;
	                        case cm.DelLine:
	                            deleteRange(lineStart(curPtr), nextLine(curPtr), false);
	                            break;
	                        case cm.InsMode:
	                            toggleInsMode();
	                            break;
	                        case cm.StartSelect:
	                            startSelect();
	                            break;
	                        case cm.HideSelect:
	                            hideSelect();
	                            break;
	                        case cm.IndentMode:
	                            autoIndent = !autoIndent;
	                            break;
	                        default:
	                            unlock();
	                            return;
	                    }
	                    trackCursor(centerCursor);
	                    unlock();
	                    break;
	                }

	        case evBroadcast:
	            switch( event.message.command ) {
	                case cm.ScrollBarChanged:
	                    checkScrollBar( event, hScrollBar, delta.x );
	                    checkScrollBar( event, vScrollBar, delta.y );
	                    break;
	                default:
	                    return;
				}
		default: 
			break;
		}
	    clearEvent(event);
	}


	int countLines( in char[] buf, int count ) {
		return std.algorithm.count(buf[0..count], 0x0a);
	}

	//#define Block ((const char *)(block))

	private int scan( in char[] scannedText, int size, string whatToFind ) {
		return std.string.indexOf(scannedText[0..size], whatToFind);
	}

	private int iScan( in char[] scannedText, int size, string whatToFind ) {
		return std.string.indexOf(scannedText[0..size], whatToFind);
	}

	private @property bool hasSelection() const {
	    return selStart != selEnd;
	}

	private void hideSelect() {
	    selecting = false;
	    setSelect(curPtr, curPtr, false);
	}

	private void initBuffer() {
	    buffer = new char[bufSize];
	}

	private bool insertBuffer( in char[] p, int offset, int length, Flag!"allowUndo" allowUndo, Flag!"selectText" selectText) {
	    selecting = false;
	    int selLen = selEnd - selStart;
	    if( selLen == 0 && length == 0 )
	        return true;

	    int delLen = 0;
	    if( allowUndo == true ) {
	        if( curPtr == selStart )
	            delLen = selLen;
	        else if( selLen > insCount )
	    		delLen = selLen - insCount;
		}

	    int newSize = cast(int)(bufLen + delCount - selLen + delLen) + length;

	    if( newSize > bufLen + delCount )
			setBufSize(cast(int)(newSize));

	    int selLines = countLines( buffer[bufPtr(selStart)..$], selLen );
	    if( curPtr == selEnd ) {
	        if( allowUndo == true ) {
	            if( delLen > 0 ) {
	            	int dstFrom = curPtr + gapLen - delCount - delLen;
	            	int dstTo = dstFrom + delLen;
	            	int srcFrom = selStart;
	            	int srcTo = srcFrom + delLen;
	            	buffer[dstFrom..dstTo] = buffer[srcFrom..srcTo];
	            }
				insCount -= selLen - delLen;
			}
	        curPtr = selStart;
	        curPos.y -= selLines;
		}
	    if( delta.y > curPos.y ) {
	        delta.y -= selLines;
	        if( delta.y < curPos.y )
	            delta.y = curPos.y;
		}

	    if( length > 0 ) {
	    	int dstFrom = curPtr;
			int dstTo = dstFrom + length;
	        int srcFrom = offset;
	        int srcTo = srcFrom + length;
	        buffer[dstFrom..dstTo] = p[srcFrom..srcTo];
	    }

	    int lines = countLines( buffer[curPtr..$], length );
	    curPtr += length;
	    curPos.y += lines;
	    drawLine = curPos.y;
	    drawPtr = lineStart(curPtr);
	    curPos.x = charPos(drawPtr, curPtr);
	    if( selectText == false )
	        selStart = curPtr;
	    selEnd = curPtr;
	    bufLen += length - selLen;
	    gapLen -= length - selLen;
	    if( allowUndo == true ) {
	        delCount += delLen;
	        insCount += length;
		}
	    limit.y += lines - selLines;
	    delta.y = max(0, min(delta.y, limit.y - size.y));
	    if( isClipboard() == false )
	        modified = true;
	    setBufSize(bufLen + delCount);
	    if( selLines == 0 && lines == 0 )
	        update(ufLine);
	    else
	        update(ufView);
	    return true;
	}

	private bool insertFrom( in TEditor editor ) {
	    return insertBuffer( editor.buffer,
	                         editor.bufPtr(editor.selStart),
	                         editor.selEnd - editor.selStart,
	                         canUndo ? Yes.allowUndo : No.allowUndo,
	                         isClipboard() ? Yes.selectText : No.selectText
	                        );
	}

	private bool insertText( in char[] text, Flag!"selectText" selectText ) {
	  return insertBuffer( text, 0, text.length, canUndo ? Yes.allowUndo : No.allowUndo, selectText);
	}

	private bool isClipboard() {
	    return clipboard is this;
	}

	private int lineMove( int p, int count ) {
	    int i = p;
	    p = lineStart(p);
	    int pos = charPos(p, i);
	    while( count != 0 ) {
	        i = p;
	        if( count < 0 ) {
	            p = prevLine(p);
	            count++;
			} else {
	            p = nextLine(p);
	            count--;
			}
		}
	    if( p != i )
	        p = charPtr(p, pos);
	    return p;
	}

	private void lock() {
	    lockCount++;
	}

	private void newLine() {
	    int p = lineStart(curPtr);
	    int i = p;
	    while( i < curPtr && ( (buffer[i] == ' ') || (buffer[i] == '\x09')))
	         i++;
	    insertText("\r\n", No.selectText);
	    if( autoIndent == true ) {
	        insertText( buffer[p..i], No.selectText);
		}
	}

	private int nextLine( int p ) {
	    return nextChar(lineEnd(p));
	}

	private static bool isWordChar(char ch) {
		return isAlpha(ch) || isNumber(ch) || ch == '_';
	}

	private int nextWord( int p ) const {
	   if (isWordChar(bufChar(p)))
	      while (p < bufLen && isWordChar(bufChar(p)))
	         p = nextChar(p);
	   else if (p < bufLen)
	      p = nextChar(p);
	   while (p < bufLen && !isWordChar(bufChar(p)))
	      p = nextChar(p);
	   return p;
	}

	private int prevLine( int p ) const {
	  return lineStart(prevChar(p));
	}

	private int prevWord( int p ) const {
	    while( p > 0 && isWordChar(bufChar(prevChar(p))) == 0 )
	        p = prevChar(p);
	    while( p > 0 && isWordChar(bufChar(prevChar(p))) != 0 )
	        p = prevChar(p);
	    return p;
	}

	private void replace() {
	    TReplaceDialogRec replaceRec = TReplaceDialogRec( findStr, replaceStr, editorFlags );
	    if( editorDialog( edReplace, &replaceRec ) != cm.Cancel ) {
	    	findStr = replaceRec.find;
	    	replaceStr = replaceRec.replace;
	        editorFlags = replaceRec.options | efDoReplace;
	        doSearchReplace();
		}

	}

	private void scrollTo( int x, int y ) {
	    x = max(0, min(x, limit.x - size.x));
	    y = max(0, min(y, limit.y - size.y));
	    if( x != delta.x || y != delta.y ) {
	        delta.x = x;
	        delta.y = y;
	        update(ufView);
		}
	}

	private bool search( string findStr, ushort opts ) {
	    int pos = curPtr;
	    int foundIndex;
	    do  {
	        if( (opts & efCaseSensitive) != 0 )
	            foundIndex = scan( buffer[bufPtr(pos)..$], bufLen - pos, findStr);
	        else
	            foundIndex = iScan( buffer[bufPtr(pos)..$], bufLen - pos, findStr);

	        if( foundIndex != -1 ) {
	            foundIndex += pos;
	            if( (opts & efWholeWordsOnly) == 0 ||
	                !(
	                    ( foundIndex != 0 && isWordChar(bufChar(foundIndex - 1)) != 0 ) ||
	                    ( foundIndex + findStr.length != bufLen &&
	                        isWordChar(bufChar(foundIndex + findStr.length))
	                    )
	                 ))
	                {
	                lock();
	                setSelect(foundIndex, foundIndex + findStr.length, false);
	                trackCursor(!cursorVisible());
	                unlock();
	                return true;
	                }
	            else
	                pos = foundIndex + 1;
	            }
	        } while( foundIndex != -1 );
	    return false;
	}

	private void setBufLen( int length ) {
	    bufLen = length;
	    gapLen = bufSize - length;
	    selStart = 0;
	    selEnd = 0;
	    curPtr = 0;
	    delta.x = 0;
	    delta.y = 0;
	    curPos = delta;
	    limit.x = maxLineLength;
	    limit.y = countLines( buffer[gapLen..$], bufLen ) + 1;
	    drawLine = 0;
	    drawPtr = 0;
	    delCount = 0;
	    insCount = 0;
	    modified = false;
	    update(ufView);
	}

	private bool setBufSize( int newSize ) const {
	    return newSize <= bufSize;
	}

	private void setCmdState( Command command, bool enable ) {
	    TCommandSet s;
	    s += command;
	    if( enable == true && (state & sfActive) != 0 )
	        enableCommands(s);
	    else
	        disableCommands(s);
	}

	private void setCurPtr( int p, ubyte selectMode ) {
	    int anchor;
	    if( (selectMode & smExtend) == 0 )
	        anchor = p;
	    else if( curPtr == selStart )
	        anchor = selEnd;
	    else
	        anchor = selStart;

	    if( p < anchor ) {
	        if( (selectMode & smDouble) != 0 ) {
	            p = prevLine(nextLine(p));
	            anchor = nextLine(prevLine(anchor));
			}
	        setSelect(p, anchor, true);
		} else {
	        if( (selectMode & smDouble) != 0 ) {
				p = nextLine(p);
	            anchor = prevLine(nextLine(anchor));
			}
		setSelect(anchor, p, false);
		}
	}

	void setSelect( int newStart, int newEnd, bool curStart ) {
	    int p;
	    if( curStart != 0 )
	        p = newStart;
	    else
	        p = newEnd;

	    ubyte flags = ufUpdate;

	    if( newStart != selStart || newEnd != selEnd )
	        if( newStart != newEnd || selStart != selEnd )
	            flags = ufView;

	    if( p != curPtr ) {
	        if( p > curPtr ) {
		    	int len = p - curPtr;
		    	buffer[curPtr..curPtr+len] = buffer[curPtr+gapLen..curPtr+gapLen+len];
	            curPos.y += countLines(buffer[curPtr..$], len);
	            curPtr = p;
			} else {
		    	int len = curPtr - p;
	            curPtr = p;
	            curPos.y -= countLines(buffer[curPtr..$], len);
	            buffer[curPtr+gapLen..curPtr+gapLen+len] = buffer[curPtr..curPtr+len];
			}
	        drawLine = curPos.y;
	        drawPtr = lineStart(p);
	        curPos.x = charPos(drawPtr, p);
	        delCount = 0;
	        insCount = 0;
	        setBufSize(bufLen);
	    }
	    selStart = newStart;
	    selEnd = newEnd;
	    update(flags);
	}

	override void setState( ushort aState, bool enable ) {
	    TView.setState(aState, enable);
	    switch( aState ) {
	        case sfActive:
	            if( hScrollBar !is null )
	                hScrollBar.setState(sfVisible, enable);
	            if( vScrollBar !is null )
	                vScrollBar.setState(sfVisible, enable);
	            if( indicator !is null )
	                indicator.setState(sfVisible, enable);
	            updateCommands();
	            break;

	        case sfExposed:
	            if( enable == true )
	                unlock();
			default:
				break;
	        }

	}

	private void startSelect() {
	    hideSelect();
	    selecting = true;
	}

	private void toggleInsMode() {
	    overwrite = !overwrite;
	    setState(sfCursorIns, !getState(sfCursorIns));
	}

	private void trackCursor( bool center ) {
	    if( center == true )
	        scrollTo( curPos.x - size.x + 1, curPos.y - size.y / 2);
	    else
	        scrollTo( max(curPos.x - size.x + 1, min(delta.x, curPos.x)),
	                  max(curPos.y - size.y + 1, min(delta.y, curPos.y)));
	}

	private void undo() {
	    if( delCount != 0 || insCount != 0 ) {
	        selStart = curPtr - insCount;
	        selEnd = curPtr;
			int length = delCount;
	        delCount = 0;
	        insCount = 0;
	        insertBuffer(buffer, curPtr + gapLen - length, length, No.allowUndo, Yes.selectText);
		}
	}

	void unlock() {
	    if( lockCount > 0 ) {
	        lockCount--;
	        if( lockCount == 0 )
	            doUpdate();
		}
	}

	void update( ubyte aFlags ) {
	    updateFlags |= aFlags;
	    if( lockCount == 0 )
	        doUpdate();
	}

	void updateCommands() {
	    setCmdState( cm.Undo,  delCount != 0 || insCount != 0 );
	    if( isClipboard() == false ) {
	        setCmdState(cm.Cut, hasSelection());
	        setCmdState(cm.Copy, hasSelection());
	        setCmdState(cm.Paste, clipboard !is null && (clipboard.hasSelection()));
		}
	    setCmdState(cm.Clear, hasSelection());
	    setCmdState(cm.Find, true);
	    setCmdState(cm.Replace, true);
	    setCmdState(cm.SearchAgain, true);
	}

	override bool valid( int ) const {
	  return isValid;
	}

	// SET: The following routines were assembler in the original TVision, Robert
	// did just a quick hack.
	// Notes: changed 0xd by '\r' and 0xa by '\n'. Seems to work with EOL=\n
	// with only one patch.
	// EDITS.CC

	private char bufChar( int p ) const {
	  if (p>=curPtr) 
		  p += gapLen;
	  return buffer[p];
	}

	private int bufPtr(int p) const {
	  if (p<curPtr) return p;
	  return (p+gapLen);
	}

	private int lineEnd(int p) const {
		int di = p,cx,bx;
		  bx = 0;
		  cx = curPtr-di;
		  if (cx<=0) goto lab1;
		//  di += bx;
		  while (cx--)
		  {
		    if (buffer[di++] == '\r') goto lab2;
		    if (buffer[di-1] == '\n') goto lab2;
		  }
		  di = curPtr;
		lab1:
		  cx = bufLen;
		  cx -= di;
		  if (!cx) return di;
		  bx += gapLen;
		  di += bx;
		  while (cx--)
		  {
		    if (buffer[di++] == '\r') goto lab2;
		    if (buffer[di-1] == '\n') goto lab2;
		  }
		  goto lab3;
		lab2:
		  di--;
		lab3:
		  di-=bx;
		  return di;
	}

	private int lineStart(int p) const {
	  int di = p,cx,bx;
	  bx = 0;
	  cx = di;
	  cx -= curPtr;
	  if (cx<=0) goto lab1;
	  bx += gapLen;
	  di += bx;
	  di--;
	  while (cx--)
	  {
	    if (buffer[di--] == '\r') goto lab2;
	    if (buffer[di+1] == '\n') goto lab2;
	  }
	  bx -= gapLen;
	  di = curPtr;
	lab1:
	  cx = di;
	  if (!cx) goto lab4;
	  di += bx;
	  di--;
	  while (cx--)
	  {
	    if (buffer[di--] == '\r') goto lab2;
	    if (buffer[di+1] == '\n') goto lab2;
	  }
	  goto lab3;
	lab2:
	  di++;
	  di++;
	  di -= bx;
	  if (cast(int)di == curPtr) goto lab4;
	  if (cast(int)di == bufLen) goto lab4;
	  // SET: When lines end only with \n it fails
	  if (buffer[di+bx] != '\n') goto lab4;
	  di++;
	  goto lab4;
	lab3:
	  di = 0;
	lab4:
	  return di;
	}

	private int nextChar(int p) const {
	  int gl=0;
	  if (p == bufLen) 
		  return p;
	  p++;
	  if (p == bufLen) 
		  return p;
	  if (p >= curPtr) 
		  gl = gapLen;
	  if (buffer[gl+p] == '\n' && buffer[gl+p-1] == '\r') 
		  return (p+1);
	  return p;
	}

	private int prevChar(int p) const {
	  int gl=0;
	  if (!p) return p;
	  p--;
	  if (!p) return p;
	  if (p >= curPtr) gl = gapLen;
	  if (buffer[gl+p] == '\n' && buffer[gl+p-1] == '\r') return (p-1);
	  return p;
	}

	// SET: Static members.
	// EDITSTAT.CC

	private ushort defEditorDialog( int, ... ) {
		return cm.Cancel;
	}
}*/