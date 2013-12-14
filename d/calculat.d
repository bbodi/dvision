module calculat;

/*------------------------------------------------------------*/
/*                                                            */
/*   Turbo Vision D 1.0                                        */
/*   Copyright (c) 1991 by Borland International              */
/*                                                            */
/*   Calc.cpp:  TCalcDisplay member functions                 */
/*                                                            */
/*------------------------------------------------------------*/

/*
  Modified by Balazs Bodi <sharp1113@hotmail.com>
  <set@ieee.org> <set@computer.org>
  I ported it from C++ version of TV.
 */

// SET: Moved to the class, made ASCII
public const char keyChar[20] =
    {    "C",   "<-",    "%",   "+-",
         "7",    "8",    "9",    "/",
         "4",    "5",    "6",    "*",
         "1",    "2",    "3",    "-",
         "0",    ".",    "=",    "+"
    };

class TCalculator : TDialog {

	static const char * const name;
    static TStreamable *build();

	this()
	// SET: The display size must be satisfied
	TWindowInit( &TCalculator::initFrame ),
	TDialog( TRect(5, 3, 5+6+DISPLAYLEN, 18), __("Pocket Calculator") ) 
	{
	    TView *tv;
	    TRect r;

	    options |= ofFirstClick;

	    // SET: enlarged buttons
	    for(int i = 0; i <= 19; i++)
	        {
	        int x = (i%4)*6+3;
	        int y = (i/4)*2+4;
	        r = TRect( x, y, x+6, y+2 );

	        tv = new TButton( r, keyChar[i], cm.CalcButton+i, bfNormal | bfBroadcast );
	        tv.options &= ~ofSelectable;
	        insert( tv );
	    }
	    r = TRect( 3, 2, 3+DISPLAYLEN, 3 ); // SET, that's checked in setDisplay
	    insert( new TCalcDisplay(r) );
	}

	TStreamable* build() {
	    return new TCalculator( streamableInit );
	}

	this( StreamableInit ) {
		super(TView(streamableInit));
	}
}