module tfileinfopane;

import std.datetime;
import std.file;
import std.path;
import std.conv;

import tvision;

private immutable string[] months =
    [
    "",__("Jan"),__("Feb"),__("Mar"),__("Apr"),__("May"),__("Jun"),
    __("Jul"),__("Aug"),__("Sep"),__("Oct"),__("Nov"),__("Dec")
    ];

private immutable ubyte[] cpInfoPane = [0x1E];

class TFileInfoPane : TView {

	private DirEntry* fileBlock;

	this( in TRect bounds ) {
		super(bounds);
    	eventMask |= evBroadcast;
	}

	override void draw() {
	    TFileDialog owner = cast(TFileDialog)owner;
	    string path = buildNormalizedPath(absolutePath(owner.directory), owner.wildCard);

	    int color = getColor(0x01);
	    TDrawBuffer b;
	    b.moveChar( 0, ' ', color, size.x );
	    b.moveStr( 1, path, color );
	    writeLine( 0, 0, size.x, 1, b );

	    b.moveChar( 0, ' ', color, size.x );
	    b.moveStr( 1, baseName(fileBlock.name), color );

	    writeLine( 0, 1, size.x, 1, b);
	    b.moveChar( 0, ' ', color, size.x );

	    if ( fileBlock !is null && fileBlock.name != "" ) {
			string buf = to!string(fileBlock.size);
			b.moveStr( 14, buf, color );

			SysTime time = fileBlock.timeLastAccessed;
			b.moveStr( 25, (cast(DateTime)time).toSimpleString(), color );
	    }
	    writeLine(0, 2, size.x, 1, b );
	    b.moveChar( 0, ' ', color, size. x);
	    writeLine( 0, 3, size.x, size.y-3, b);
	}

	override ref immutable(TPalette) getPalette() const {
	    static immutable TPalette palette = immutable(TPalette)( cpInfoPane);
	    return palette;
	}

	override void handleEvent( ref TEvent event ) {
	    TView.handleEvent(event);
	    if( event.what == evBroadcast && event.message.command == cm.FileFocused ) {
			fileBlock = (cast(DirEntry *)(event.message.infoPtr));
	        drawView();
		}
	}
}