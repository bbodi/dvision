module tdialog;

import tview;
import twindow;
import tapplication;

immutable ubyte[] cpDialog = [0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
                 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F];

immutable TPalette palette1 = immutable(TPalette)( cpDialog );
immutable TPalette palette2 = immutable(TPalette)( null );

class TDialog : TWindow {

	this(in TRect bounds, string aTitle ) {
		super( bounds, aTitle, wnNoNumber );
		growMode = 0;
     	flags = wfMove | wfClose;
	}

	override ref immutable(TPalette) getPalette() const {
	    // Avoid returning the palette if the dialog isn't inserted on the
	    // desktop or the application. Example: a dialog inside another.
	    if ( (owner is TApplication.deskTop) ||
	         (owner is TApplication.application) 
	       ) return palette1;
	    return palette2;
	}

	override void handleEvent(ref TEvent event) {
	    TWindow.handleEvent(event);
	    switch (event.what) {
	        case evKeyDown:
	            switch (event.keyDown.keyCode) {
	                case KeyCode.kbEsc:
	                    event.what = evCommand;
	                    event.message.command = cm.Cancel;
	                    event.message.infoPtr = null;
	                    putEvent(event);
	                    clearEvent(event);
	                    break;
	                case KeyCode.kbEnter:
	                    event.what = evBroadcast;
	                    event.message.command = cm.Default;
	                    event.message.infoPtr = null;
	                    putEvent(event);
	                    clearEvent(event);
	                    break;
					default:
						break;
				}
	            break;

	        case evCommand:
				if (event.message.command.someOfThem(cm.Ok, cm.Cancel, cm.Yes, cm.No)) {
					if( (state & sfModal) != 0 ) {
						endModal(event.message.command);
						clearEvent(event);
					}
				}
			default:
				break;	           
		}
	}

	override bool valid( Command command ) {
	    if( command == cm.Cancel )
	        return true;
	    else
	        return TGroup.valid( command );
	}


}