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

module calcdisp;

const DISPLAYLEN =  25;      // Length (width) of calculator display

enum TCalcState {
	csFirst = 1, 
	csValid,
	csError 
};

const int cm.CalcButton  = 200,
          cm.CalcClear   = cm.CalcButton,
          cm.CalcDelete  = cm.CalcButton+1,
          cm.CalcPercent = cm.CalcButton+2,
          cm.CalcPlusMin = cm.CalcButton+3,
          cm.Calc7       = cm.CalcButton+4,
          cm.Calc8       = cm.CalcButton+5,
          cm.Calc9       = cm.CalcButton+6,
          cm.CalcDiv     = cm.CalcButton+7,
          cm.Calc4       = cm.CalcButton+8,
          cm.Calc5       = cm.CalcButton+9,
          cm.Calc6       = cm.CalcButton+10,
          cm.CalcMul     = cm.CalcButton+11,
          cm.Calc1       = cm.CalcButton+12,
          cm.Calc2       = cm.CalcButton+13,
          cm.Calc3       = cm.CalcButton+14,
          cm.CalcMinus   = cm.CalcButton+15,
          cm.Calc0       = cm.CalcButton+16,
          cm.CalcDecimal = cm.CalcButton+17,
          cm.CalcEqual   = cm.CalcButton+18,
          cm.CalcPlus    = cm.CalcButton+19;

class TCalcDisplay : TView {
	static const char * const name;
    static TStreamable *build();

	private TCalcState status;
    private char *number;
    private char sign;
    private char operate;           // since 'operator' is a reserved word.
    private double operand;

	const cpCalcPalette = "\x13"

	this(TRect r) {
		super(r);
	    options |= ofSelectable;
	    eventMask = (evKeyboard | evBroadcast);
	    number = new char[DISPLAYLEN];
	    clear();

	}

	~this() {
	    DeleteArray(number);
	}

	TPalette& TCalcDisplay::getPalette() const {
	    static TPalette palette( cpCalcPalette, sizeof(cpCalcPalette)-1 );
	    return palette;
	}


	void handleEvent(TEvent event) {
	    // SET: Independent of the label
	    static char keys[]=['C','\x8','%','_','7','8','9','/','4','5','6',
	                        '*','1','2','3','-','0','.','=','+'];
	    TView.handleEvent(event);

	    switch(event.what)
	        {
	        case evKeyboard:
	            calcKey(event.keyDown.charScan.charCode,event.keyDown.keyCode);
	            clearEvent(event);
	            break;
	        case evBroadcast:
	            if(event.message.command>=cm.CalcButton &&
	               event.message.command<=cm.CalcButton+19)
	                {
	                calcKey(keys[event.message.command-cm.CalcButton],0);
	                clearEvent(event);
	                }
	            break;
	        }
	}


	void draw() {
	    char color = getColor(1);
	    int i;
	    TDrawBuffer buf;

	    i = size.x - strlen(number) - 2;
	    buf.moveChar(0, ' ', color, size.x);
	    buf.moveChar(i, sign, color, 1);
	    buf.moveStr(i+1, number, color);
	    writeLine(0, 0, size.x, 1, buf);
	}



	TStreamable* build() {
		return new TCalcDisplay( streamableInit );
	}

    /*inline ipstream& operator >> ( ipstream& is, TCalcDisplay& cl )
    { return is >> (TStreamable&) cl; }
inline ipstream& operator >> ( ipstream& is, TCalcDisplay*& cl )
    { return is >> (void *&) cl; }

inline opstream& operator << ( opstream& os, TCalcDisplay& cl )
    { return os << (TStreamable&) cl; }
inline opstream& operator << ( opstream& os, TCalcDisplay* cl )
    { return os << (TStreamable *) cl; }*/

    private void calcKey(char key, uint code) {
	    char stub[2] = " ";
	    double r;
	    char *decPoint=nl_langinfo(RADIXCHAR);

	    switch(code) {
	        case kbBackSpace:
	             key=8;
	             break;
	        case kbEsc:
	             key=27;
	             break;
	        case kbEnter: // Added by Mike
	             key=13;
	             break;
	    }
	    
	    key = (char)toupper(key);
	    if (status == csError && key != 'C')
	        key = ' ';

    	switch(key) {
        case '0':   case '1':   case '2':   case '3':   case '4':
        case '5':   case '6':   case '7':   case '8':   case '9':
            checkFirst();
            if (strlen(number) < 15) {                       // 15 is max visible display length
                if (!strcmp(number, "0"))
                    number[0] = '\0';
                stub[0] = key;
                strcat(number, stub);
            }
            break;
        case 8:
        case 27:
            int len;

            checkFirst();
            if( (len = strlen(number)) == 1 )
                strcpy(number, "0");
            else
                number[len-1] = '\0';
            break;

        case '_': // +-
            sign = (sign == ' ') ? '-' : ' ';
            break;

        case '.':
             checkFirst();
             if(strstr(number, decPoint) == NULL)
                 strcat(number, decPoint);
            break;

        case '+':   case '-':   case '*':   case '/':
        case '=':   case '%':   case 13:
            if(status == csValid) {
                status = csFirst;
                r = getDisplay() * ((sign == '-') ? -1.0 : 1.0);
                if( key == '%' )
                    {
                    if(operate == '+' || operate == '-')
                        r = (operand * r) / 100;
                    else
                        r /= 100;
                    }
                switch( operate ) {
                    case '+':
                        setDisplay(operand + r);
                        break;

                    case '-':
                        setDisplay(operand - r);
                        break;

                    case '*':
                        setDisplay(operand * r);
                        break;

                    case '/':
                        if(r == 0)
                            error();
                        else
                            setDisplay(operand / r);
                        break;

                    }
                }
            operate = key;
            operand = getDisplay() * ((sign == '-') ? -1.0 : 1.0);
            break;

        case 'C':
            clear();
            break;

        }
    	drawView();
	}

	private void checkFirst() {
    	if(status == csFirst)	{
	        status = csValid;
	        strcpy(number, "0");
	        sign = ' ';
        }
	}

	private void setDisplay(double r) {
	    int  len;
	    char str[64];
	    //ostrstream displayStr( str, sizeof str );SET: Removed this waste

	    if(r < 0.0) {
	        sign = '-';
	        sprintf(str,"%f",-r);
	    } else {
	        sprintf(str,"%f",r);
	        sign = ' ';
	    }

	    len = strlen(str) - 1;          // Minus one so we can use as an index.

	    if(len > DISPLAYLEN)
	        error();
	    else
	        strcpy(number, str);
	}

	private void clear() {
	    status = csFirst;
	    strcpy(number, "0");
	    sign = ' ';
	    operate = '=';
	}

	private void error() {
	    status = csError;
	    strcpy(number, _("Error"));
	    sign = ' ';
	}

	private double getDisplay() { 
		return( atof( number ) ); 
	};

	/*???*/private const char *streamableName() const {
     	return name;
    }

    protected void TCalcDisplay::write( opstream& os ) {
	    TView::write( os );
	    os.writeBytes(&status, sizeof(status));
	    os.writeString(number);
	    os.writeByte(sign);
	    os.writeByte(operate);
	    os.writeBytes(&operand, sizeof(operand));
	}


	protected void *TCalcDisplay::read( ipstream& is ) {
	    TView::read( is );
	    number = new char[DISPLAYLEN];
	    is.readBytes(&status, sizeof(status));
	    is.readString(number, DISPLAYLEN);
	    sign = is.readByte();
	    operate = is.readByte();
	    is.readBytes(&operand, sizeof(operand));
	    return this;
	}
}



