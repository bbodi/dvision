module tstatictext;

import tvision;

immutable ubyte[] cpStaticText = [0x06];
immutable TPalette palette = immutable(TPalette)( cpStaticText);

class TStaticText : TView {

	string text;

	this( const TRect bounds, in char[] aText ) {
		super(bounds);
		text = aText.idup;
	}

	override void draw() {
	    TDrawBuffer b;
	    int maxLen = size.x*size.y;
	    // +2 to hold the \x3 center char (SET)

	    ushort color = getColor(1);
	    string str = text;
	    int len = text.length;
	    // Check if the size if bigger than allowed and the extra char isn't the
	    // center char (SET)
	    if ((len > maxLen) && str[0] != 3) {
	        len--;
	        str = text[0..len];
		}
	    int p = 0;
	    int y = 0;
	    bool center = false;
	    int i, j;
	    while (y < size.y) {
	        b.moveChar(0, ' ', color, size.x);
	        if (p < len) {
	            if (str[p] == 3) {
	                center = true;
	                ++p;
				}
	            i = p;
	            do {
	               j = p;
	               while ((p < len) && (str[p] == ' ')) 
	                   ++p;
	               while ((p < len) && (str[p] != ' ') && (str[p] != '\n'))
	                   ++p;
				} while ((p < len) && (p < i + size.x) && (str[p] != '\n'));
	            if (p > i + size.x) {
	                if (j > i)
	                    p = j;
	                else
	                    p = i + size.x;
				}
	            if (center)
					j = (size.x - p + i) / 2 ;
	            else 
					j = 0;
	            b.moveBuf(j, str[i..$], color, (p - i));
	            while ((p < len) && (str[p] == ' '))
	                p++;
	            if ((p < len) && (str[p] == '\n')) {
	                center = false;
	                p++;
	                if ((p < len) && (str[p] == 10))
	                    p++;
				}
			}
	        writeLine(0, y++, size.x, 1, b);
		}
	}

	override ref immutable(TPalette) getPalette() const {
	    return palette;
	}
}