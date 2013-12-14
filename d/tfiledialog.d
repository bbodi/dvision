module tfiledialog;

import std.path;
import std.file;

import tvision;
import tfilelist;
import tfileinfopane;

const ushort
    fdOKButton      = 0x0001,      // Put an OK button in the dialog
    fdOpenButton    = 0x0002,      // Put an Open button in the dialog
    fdReplaceButton = 0x0004,      // Put a Replace button in the dialog
    fdClearButton   = 0x0008,      // Put a Clear button in the dialog
    fdHelpButton    = 0x0010,      // Put a Help button in the dialog
    fdSelectButton  = 0x0020,      // Put a Select button in the dialog
    fdDoneButton    = 0x0040,      // Say Done isntead of "Cancel"
    fdAddButton     = 0x0080,      // Put an Add button in the dialog
    fdNoLoadDir     = 0x0100;      // Do not load the current directory
				   // contents into the dialog at Init.
				   // This means you intend to change the
				   // WildCard by using SetData or store
				   // the dialog on a stream.

// File dialog flags
const int
    ffOpen        = 0x0001,
    ffSaveAs      = 0x0002;


class TFileDialog : TDialog {
	private TFileInputLine fileName;
    private TFileList fileList;
    string wildCard;
    string directory;

    this( string aWildCard, string aTitle, string inputName, ushort aOptions, HistoryId histId ) {
	  	super(TRect(15, 1, 64, 21), aTitle);
	    options |= ofCentered;
	    // SET: Allow it to grow
	    growMode = gfGrowAll;
	    flags   |= wfGrow | wfZoom;
	    wildCard = aWildCard;

	    fileName = new TFileInputLine( TRect( 3, 2, 31, 3 ) );
	    fileName.setDataFromStr( wildCard );
	    fileName.growMode=gfGrowHiX;
	    insert( fileName );

	    insert( new TLabel( 2, 1, inputName, fileName ) );
	    THistory his = new THistory(TRect(31, 2, 34, 3), fileName, histId);
	    // SET: This and more settings to make it grow nicely
	    his.growMode = gfGrowLoX | gfGrowHiX;
	    insert(his);
	    
	    bool longNames = true; // SET
	    TScrollBar sb = longNames ?
	                     new TScrollBar( TRect( 34, 5, 35, 16 ) ) :
	                     new TScrollBar( TRect( 3, 15, 34, 16 ) );
	    insert( sb );
	    insert(fileList = new TFileList(TRect(3,5,34,longNames ? 16 : 15), sb));
	    fileList.growMode = gfGrowHiX | gfGrowHiY;

	    insert( new TLabel( 2, 4, __("~F~iles"), fileList ) );

	    ushort opt = bfDefault;
	    TRect r = TRect( 35, 2, 46, 4 );
	    
	    void AddButton(int flag, string name, Command command) {
	    	if (aOptions & flag) {
	        	TButton button = new TButton(r, name, command, opt); 
	        	button.growMode=gfGrowLoX | gfGrowHiX; 
	        	insert(button); 
	        	opt = bfNormal; 
	        	r.a.y += 2;
	        	r.b.y += 2; 
	        }
	    }

	    AddButton(fdOpenButton, __("~O~pen"), cm.FileOpen);
	    AddButton(fdOKButton, __("~O~K"), cm.FileOpen);
	    AddButton(fdAddButton, __("~A~dd"), cm.FileOpen);
	    AddButton(fdSelectButton, __("~S~elect"), cm.FileSelect);
	    AddButton(fdReplaceButton, __("~R~eplace"), cm.FileReplace);
	    AddButton(fdClearButton, __("~C~lear"), cm.FileClear);

	    TButton bt = new TButton(r,aOptions & fdDoneButton ? __("Done") : __("Cancel"), cm.Cancel, bfNormal);
	    bt.growMode=gfGrowLoX | gfGrowHiX;
	    insert(bt);
	    r.a.y += 2;
	    r.b.y += 2;

	    if( (aOptions & fdHelpButton) != 0 ) {
	        TButton button = new TButton(r,__("~H~elp"),cm.Help,bfNormal);
	        button.growMode=gfGrowLoX | gfGrowHiX;
	        insert(button);
	        r.a.y += 2;
	        r.b.y += 2;
		}

	    TFileInfoPane fip = new TFileInfoPane(TRect(1,16,48,19));
	    fip.growMode = gfGrowHiX | gfGrowHiY | gfGrowLoY;
	    insert(fip);

	    selectNext( false );
	    if( (aOptions & fdNoLoadDir) == 0 )
	        readDirectory();
	    else
	        setUpCurDir(); // SET: We must setup the current directory anyways
	}

	// SET: Avoid a size smaller than the starting one
	override void sizeLimits(out TPoint min, out TPoint max) const {
		TDialog.sizeLimits(min, max);
		min.x = 64 - 15;
		min.y = 21 - 1;
	}

	override void shutDown() {
	    fileName = null;
	    fileList = null;
	    TDialog.shutDown();
	}

	override void handleEvent(ref TEvent event) {
	    TDialog.handleEvent(event);
	    if( event.what == evCommand ) {
			if (event.message.command.someOfThem(cm.FileOpen, cm.FileReplace, cm.FileClear, cm.FileSelect)) {
				endModal(event.message.command);
				clearEvent(event);
			}
	    } else if( event.what == evBroadcast && event.message.command == cm.FileDoubleClicked ) {
	        event.what = evCommand;
	        event.message.command = cm.Ok;
	        putEvent( event );
	        clearEvent( event );
		}
	}

	void readDirectory() {
	    fileList.readDirectory( directory, wildCard );
	    setUpCurDir();
	}

	void setUpCurDir() {
		directory = getcwd();
	}

	override void setData( void *rec ) {
	    TDialog.setData( rec );
	    string file = *cast(string*)rec;
	    if( file != "" && canFind(file, "?*") ) {
	        valid( cm.FileInit );
	        fileName.select();
		}
	}

	override void getData( void *rec ) const {
		string file = getFileName();
		*(cast(string*)rec) = std.path.baseName(file);
	}

	string getFileName() const {
		return fileName.getData();
	}

	private bool isWild(string str) const {
		return canFind(str, "*") || canFind(str, "?");
	}

	override bool valid(Command command) {
	    if (!TDialog.valid(command))
	        return false;

	    if ((command == cm.Valid) || (command == cm.Cancel))
	        return true;

	    string fName = getFileName();
	    if (command != cm.FileClear) {
			if(isWild(fName)) {
				string dir = dirName(fName);
				string name = baseName(fName);
	            if (std.path.isValidPath( dir )) {
	                directory = dir;
	                wildCard = name;
	                if (command != cm.FileInit)
	                    fileList.select();
	                fileList.readDirectory(directory, wildCard);
	            } else {
					messageBox( mfError | mfOKButton, __("Invalid drive or directory") );
					fileName.select();
					return false;
				}
	        } else if (isDir(fName)) {
	            if (std.path.isValidPath( fName )) {
	            	fName ~= dirSeparator;
	            	directory = fName;
	                if (command != cm.FileInit)
	                    fileList.select();
	                fileList.readDirectory(directory, wildCard);
	            } else {
					messageBox( mfError | mfOKButton, __("Invalid drive or directory") );
					fileName.select();
					return false;
				}
	        } else if (isValidPath(fName)) {
	            return true;
	        } else {
	            messageBox( mfError | mfOKButton, __("Invalid file name."));
	            return false;
	        }
	    }
	    else {
	       return true;
	   	}
		return false; 
	}

}

class TFileInputLine : TInputLine {
	
	this(in TRect bounds ) {
		super(bounds, 512);
    	eventMask = eventMask | evBroadcast;
	}

	override void handleEvent( ref TEvent event ) {
	    TInputLine.handleEvent(event);
	    if( event.what == evBroadcast &&
	        event.message.command == cm.FileFocused &&
	        !(state & sfSelected)   ) {
			auto entry = cast(DirEntry *)event.message.infoPtr;
	        if (entry.isDir ) {
				data = buildNormalizedPath(entry.name, (cast(TFileDialog )owner).wildCard);
				dataLen = data.length;
	        } else {
				data = entry.name;
	        	dataLen = data.length;
			}
	        drawView();
		}
	}
}