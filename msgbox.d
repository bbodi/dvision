module msgbox;

import tvision;

import std.format;
import std.algorithm : min, max;
import std.stdio;
import core.vararg;

const ushort

//  Message box classes

mfWarning      = 0x0000,       // Display a Warning box
    mfError        = 0x0001,       // Dispaly a Error box
    mfInformation  = 0x0002,       // Display an Information Box
    mfConfirmation = 0x0003,       // Display a Confirmation Box

	// Message box button flags

    mfYesButton    = 0x0100,       // Put a Yes button into the dialog
    mfNoButton     = 0x0200,       // Put a No button into the dialog
    mfOKButton     = 0x0400,       // Put an OK button into the dialog
    mfCancelButton = 0x0800,       // Put a Cancel button into the dialog

	// Special flag: Avoid translating this message, is already translated.
    mfDontTranslate = 0x4000,
	// Special flag: For the "Don't show it next time" field
    mfDontShowAgain = 0x8000,

    mfYesNoCancel  = mfYesButton | mfNoButton | mfCancelButton,
	// Standard Yes, No, Cancel dialog
    mfOKCancel     = mfOKButton | mfCancelButton;
// Standard OK, Cancel dialog

immutable string buttonName[] = [
    __("~Y~es"),
    __("~N~o"),
    __("~O~K"),
    __("Cancel")
];

immutable Command[] commands = [
    cm.Yes,
    cm.No,
    cm.OK,
    cm.Cancel
];

immutable string Titles[] = [
    __("Warning"),
    __("Error"),
    __("Information"),
    __("Confirm")
];

Command messageBoxRect( in TRect r, in char[] msg, ushort aOptions ) {
    int i, x, buttonCount;
    TView[5] buttonList;
    int height = r.b.y - r.a.y;
    TCheckBoxes dsa;

    TRect rlocal = r;

    if (aOptions & mfDontShowAgain) {
       rlocal.a.y-=2;
       rlocal.b.y++;
    }

    TDialog dialog = new TDialog( rlocal, Titles[aOptions & 0x3] );

    dialog.insert(new TStaticText(TRect(3, 2, dialog.size.x - 2, height - 3), msg) );

    if (aOptions & mfDontShowAgain) {
        dsa = new TCheckBoxes(TRect(2, height - 2, dialog.size.x - 2, height - 1),
							  new TSItem(__("Don't warn you next time"),null));
        dialog.insert(dsa);
    }

    for( i = 0, x = -2, buttonCount = 0; i < 4; i++ ) {
        if( (aOptions & (0x0100 << i)) != 0) {
            buttonList[buttonCount] =
                new TButton( TRect(0, 0, 10, 2), _(buttonName[i]), commands[i], bfNormal );
            x += buttonList[buttonCount++].size.x + 2;
        }
    }

    x = (dialog.size.x - x) / 2;

    for( i = 0; i < buttonCount; i++ ) {
        dialog.insert(buttonList[i]);
        buttonList[i].moveTo(x, dialog.size.y - 3);
        x += buttonList[i].size.x + 2;
    }

    dialog.selectNext(false);

    bool oldBusy = TScreen.showBusyState(false);
    Command ccode = TProgram.deskTop.execView(dialog);
    TScreen.showBusyState(oldBusy);
    if (aOptions & mfDontShowAgain) {
       ushort val;
       dsa.getData(&val); 
	   /* WTF?
       if (val)
          ccode |= 0x8000; // Not so clean but cm.Ok,Yes,etc are low values
	   */
    }

    CLY_destroy( dialog );
    
    return ccode;
}

ushort messageBoxRectf(T...)( in TRect r,
                       ushort aOptions,
                       string fmt,
                       T args ) {
	static if (args.length == 0) {
		return messageBoxRect( makeRect(), msg, aOptions );
	} else {
		auto writer = appender!string();
		formattedWrite(writer, fmt, args);

		return messageBoxRect( r, writer.data, aOptions | mfDontTranslate );
	}
}

private TRect makeRect() {
    TRect r = TRect(0, 0, 40, 9);
    r.move((TProgram.deskTop.size.x - r.b.x) / 2,
           (TProgram.deskTop.size.y - r.b.y) / 2);
    return r;
}

Command messageBox(T...)( ushort aOptions, string fmt, T args ) {
	static if (args.length == 0) {
		return messageBoxRect( makeRect(), fmt, aOptions );
	} else {
		auto writer = appender!string();
		formattedWrite(writer, fmt, args);

		return messageBoxRect( makeRect(), writer.data, aOptions | mfDontTranslate );
	}
}

Command inputBox( string Title, string aLabel, wchar[] s, int limit,
                 Validator v ) {   
    // Use a size according to the label+limit and title
    int len;
    len = max( aLabel.length + 8 + limit, Title.length + 11 );
    len = min( len, 60 );
    len = max( len , 24 );
    TRect r = TRect(0, 0, len, 7);
    r.move((TProgram.deskTop.size.x - r.b.x) / 2,
           (TProgram.deskTop.size.y - r.b.y) / 2);
    return inputBoxRect(r, Title, aLabel, s, limit, v);
}

Command inputBoxRect( in TRect bounds,
                     string Title,
                     string aLabel,
                     wchar[] s,
                     int limit,
                     Validator v )
{

    TDialog dialog = new TDialog(bounds, Title);

    uint x = 4 + aLabel.length;
    TRect r = TRect( x, 2, min(x + limit + 2, cast(uint)dialog.size.x - 3), 3 );
    TInputLine control = new TInputLine( r, limit );
    control.setValidator( v );
    dialog.insert( control );

    r = TRect(2, 2, 3 + aLabel.length, 3);
    dialog.insert( new TLabel( r, aLabel, control ) );

    r = TRect( dialog.size.x / 2 - 11, dialog.size.y - 3,
               dialog.size.x / 2 - 1 , dialog.size.y - 1);
    dialog.insert( new TButton(r, __("~O~K"), cm.Ok, bfDefault));

    r.a.x += 12;
    r.b.x += 12;
    dialog.insert( new TButton(r, __("Cancel"), cm.Cancel, bfNormal));

    r.a.x += 12;
    r.b.x += 12;
    dialog.selectNext(false);
    dialog.setData(cast(void*)s);
    Command c = TProgram.deskTop.execView(dialog);
    if( c != cm.Cancel )
        dialog.getData(cast(void*)s.ptr);
    CLY_destroy( dialog );
    return c;
}

