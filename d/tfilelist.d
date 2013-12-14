module tfilelist;

import std.path;
import std.file;
import std.algorithm;

import tvision;

private alias TSortedListBox!(DirEntry) Parent;

string DirEntryToString(in DirEntry entry) {
	return baseName(entry.name);
}

class TFileList : Parent {

	this(in TRect bounds, TScrollBar aScrollBar) {
		super(bounds, 2, aScrollBar);
		setNumCols(1);
	}

	override void focusItem( ccIndex item ) {
		Parent.focusItem( item );
		message( owner, evBroadcast, cm.FileFocused, &items[item] );
	}

	override void selectItem( ccIndex item ) {
		message( owner, evBroadcast, cm.FileDoubleClicked, &items[item] );
	}

	override void getData( void * ) {
	}

	override void setData( void * ) {
	}

	override uint dataSize() {
	  return 0;
	}

	override void* getKey( string s ) {
		return cast(void *)s.ptr;
	}

	override void handleEvent( ref TEvent event ) {
	  	Parent.handleEvent( event );
		if( event.what == evKeyDown ) {
			if( event.keyDown.keyCode == KeyCode.kbLeft ) {
				clearEvent( event );
				/* Move to .. */ 
				auto entry = &items[0]; 
				message( owner, evBroadcast, cm.FileFocused, entry );
				message( owner, evBroadcast, cm.FileDoubleClicked, entry );
			} else if( event.keyDown.keyCode == KeyCode.kbRight ) {
				clearEvent( event );
				/* Enter dir */
				DirEntry* tp = &items[focused];
				if( tp.isDir )
					message( owner, evBroadcast, cm.FileDoubleClicked, tp );
			}
		}
	}

	override void setState( ushort aState, bool enable ) {
		Parent.setState( aState, enable );
		if ( aState == sfFocused && enable ) {
			message( owner, evBroadcast, cm.FileFocused, &items[focused] );
		}
	}
	/******** end of struct DirSearchRec ********/


	// SET: Helper routine to exclude some special files
	/*static
	int ExcludeSpecialName(string name) {
		int len=strlen(name);
		if ((TFileCollection.sortOptions & fcolHideEndTilde) && name[len-1]=='~')
			return 1;
		if ((TFileCollection.sortOptions & fcolHideEndBkp) && len>4 &&
			strcasecmp(name+len-4,".bkp")==0)
			return 1;
		if ((TFileCollection.sortOptions & fcolHideStartDot) && name[0]=='.')
			return 1;
		return 0;
	}*/

	// Win32+MingW
	void readDirectory(string dir, string pattern) {
		DirEntry[] fileList;
	  
	  // find all dirs
		fileList.add(DirEntry(buildNormalizedPath(dir, "..")));
		auto entries = dirEntries(dir, pattern, SpanMode.shallow);
		foreach(DirEntry e; entries) {
	        fileList.add(e);
		}

		newList(fileList);
		if (items.length > 0)
			message( owner, evBroadcast, cm.FileFocused, &items[0] );
		else {
			message( owner, evBroadcast, cm.FileFocused, null );
		}
	}

	
}