module progressbar;

import std.conv;

import tvision;

private immutable ubyte[] cpProgressBar = [0x04];
private immutable TPalette palette = immutable(TPalette)( cpProgressBar);


class ProgressBar : TView {

	private char          backChar;   // background character
   	private int total;      // total iterations to complete 100 %
   	private int progress;   // current iteration value
   	private wchar[]       bar;	     // thermometer bar
   	private int  dispLen;    // length of bar
   	private int  curPercent; // current percentage
   	private int  curWidth;
   	private int  numOffset;  // offset in the string to display the percentage
   	private double        charValue;

   	this(in TRect bounds, int aTotal, char aBackChar = 'a') {
		super(bounds);
	    backChar = aBackChar;
	    total = aTotal;
	    numOffset = (size.x/2)-3;
	    bar = new wchar[size.x];
	    bar[] = backChar;
	    charValue = 100.0/size.x;
	    progress = curPercent = curWidth = 0;
	}

	override void draw() {
	   	char[] str = to!(char[])(curPercent);
	   	/*if(curPercent < 10) {
			str[2] = str[0];
			str[1] = str[0] = ' ';
		} else if(curPercent<100 && curPercent>9) {
	    	str[2] = str[1];
	    	str[1] = str[0];
	    	str[0] = ' ';
		}*/
		TDrawBuffer nbuf;
	   	short colorNormal = getColor(1);
	   	int fore = colorNormal >> 4;                    // >>4 is same as /16
	   	int colorHiLite = fore+((colorNormal-(fore<<4))<<4); // <<4 is same as *16
	   	nbuf.moveChar(0,backChar,colorNormal,size.x);
	   	nbuf.moveStr(numOffset, str, colorNormal);
	   	nbuf.moveStr(numOffset+3," %",colorNormal);
	   	for(int i=0; i < curWidth; i++) {
			nbuf.putAttribute(i, colorHiLite);
	  	}
	   	writeLine(0, 0, size.x, 1, nbuf);
	}


	override ref immutable(TPalette) getPalette() const {
	   	return palette;
	}


	void update(int aProgress) {
		progress = aProgress;
	   	calcPercent();
	   	drawView();
	}

	private	void calcPercent() {
	   	int percent = cast(int) ( (cast(double)progress/cast(double)total) * 100.0 );

		if(percent != curPercent) {
			curPercent = percent;
			int width = cast(int)(cast(double)curPercent/charValue);

			if(width != curWidth) {
				curWidth = width; 
			}
	    }
	}

	int getTotal() {
	   return total;
	}

	int getProgress() {
	   return progress;
	}

	void setTotal(int newTotal) {
	   	int tmp = total;
	   	total = newTotal;
	   	bar[] = backChar;
	   	curWidth   = 0; 
	   	progress   = 0; 
	   	curPercent = 0; 
	   	if (tmp) {
			drawView();
		}
	}

	void setProgress(int newProgress) {
		progress = newProgress;
	   	calcPercent();
	   	drawView();                       // paint the thermometer bar
	}
}