module tdrawbuffer;

import std.algorithm;
import std.utf;

import common;
import tvconfig;
import codepage;
import tdisplay;

struct TDrawBuffer {

	private CharInfo[maxViewWidth] data;

	private int offset;
	private int attrib;

	void setOffset(int o) {
		offset = o;
	}

	void setAttrib(int o) {
		attrib = o;
	}

	const(CharInfo[]) getBuffer() const {
		return data;
	}

	private static ushort setLowByte(ushort w, ubyte value) {
		return (w&0xFF00) | value;
	}

	private static ushort setHighByte(ushort w, ubyte value) {
		return (w&0x00FF) | (value<<8);
	}

/**[txh]********************************************************************

  Description:
  Copies count bytes from source to the data buffer starting at indent. The
function uses the provided attribute, but if the attribute is 0 the attribute
in the buffer is unmodified.@p
  Added a check to avoid writings passing the end of the buffer.@p

***************************************************************************/
	
	void putAttribute(uint indent, uint attr ) 
	in {
		assert(indent + offset < maxViewWidth);
	} body {
		data[offset+indent].attrib = cast(ubyte)attr;
	}

	void putChar( uint indent, wchar c ) 
	in {
		assert(indent + offset < maxViewWidth);
	} body {
		data[offset+indent].ch = c;
	}

	void moveBuf(S)(const uint indent, in S src, uint attr, uint count) {
		if (attrib != 0) {
			attr = attrib;
		}
		if (!count || (indent >= cast(uint)maxViewWidth))  {
			return;
		}
		count = min(std.utf.count(src), maxViewWidth, count);
		
		S srcData = src.dup;
		int dstIndex = indent;
		while(count > 0) {
			putChar(dstIndex, cast(wchar)decodeFront(srcData));
			if (attr != 0) {
				putAttribute(dstIndex, cast(ubyte)attr);
			}
			dstIndex++;
			--count;
		}
	}

	version (unittest) {
		import std.conv;
		static void assertEquals(TDrawBuffer b, int len, string expected) {
			assert( equal(map!(a => a.ch)(cast(CharInfo[])b.data[0..len]), expected) );
		}
	}
	unittest {
		TDrawBuffer b;
		b.moveBuf(0, "être\u03bb\u20AC", 0, 6);
		assertEquals(b, 6, "être\u03bb\u20AC");

		b.moveBuf(0, "123456789", 0, 2);
		assertEquals(b, 2, "12");
		b.moveBuf(0, "123", 0, 6);
		assertEquals(b, 3, "123");

		b.moveBuf(0, "être\u03bb\u20AC"w, 0, 6);
		assertEquals(b, 6, "être\u03bb\u20AC");
		b.moveBuf(0, "être\u03bb\u20AC"d, 0, 6);
		assertEquals(b, 6, "être\u03bb\u20AC");
	}
	
/**[txh]********************************************************************

  Description:
  Fills count bytes in the buffer starting at the indent position. If the
attribute is 0 the original is left unchanged. If the character is 0 only
the attribute is used.@p
  Added a check to avoid writings passing the end of the buffer.@p

***************************************************************************/
	
	void moveChar(uint indent, wchar c, uint attr, uint count ) {
		if (attrib != 0) {
			attr = attrib;
		}
		if (!count || (indent >= cast(uint)maxViewWidth))  {
			return;
		}
		if (count+indent > cast(uint)maxViewWidth) {
			count = maxViewWidth - indent;
		}

		foreach(i; indent..indent+count) {
			if (c != 0) {
				putChar(i, c);
			}
			if (attr != 0) {
				putAttribute(i, cast(ubyte)attr);
			}
		}
	}

/**[txh]********************************************************************

  Description:
  That's the same as moveStr but the attrs parameter holds two attributes
the lower 8 bits are the normal value and the upper 8 bits define the
attribute to be used for text enclosed by ASCII 126. @x{::moveStr}.@p
  The routine was modified to avoid writes passing the end of the buffer.
Additionally was re-writed in assembler (I guess the Borland's original code
was assembler, but I didn't take a look to it) because the check slow downs
the routine so I wanted to avoid a lose in performance. SET.

***************************************************************************/
	void moveCStr(S)( uint indent, in S src, uint attr ) {
		if (attrib != 0) {
			attr = attrib;
		}
		ubyte bh = (attr >> 8) & 0xFF;
		ubyte ah = attr & 0xff;
		int len = min(maxViewWidth - indent, src.lenWithoutTides);

		S srcData = src.dup;
		int dstIndex = indent;
		while(len > 0) {
			wchar al = cast(wchar)decodeFront(srcData);
			if (al == '~') {
				auto temp = ah;
				ah = bh;
				bh = temp;
			}
			else {
				putChar(dstIndex, al);
				putAttribute(dstIndex, ah);
				dstIndex++;
				--len;
			}
		}
	}

	unittest {
		TDrawBuffer b;
		b.moveCStr(0, "~ê~tre\u03bb\u20AC", 0);
		auto bStr = map!(a => a.ch)(cast(CharInfo[])b.data[0..6]);
		assert(equal(bStr, "être\u03bb\u20AC"), to!string(bStr) ~ " != être\u03bb\u20AC");

		b.moveCStr(0, "être\u03bb\u20AC"w, 0);
		assertEquals(b, 6, "être\u03bb\u20AC");
		b.moveCStr(0, "être\u03bb\u20AC"d, 0);
		assertEquals(b, 6, "être\u03bb\u20AC");
	}

/**[txh]********************************************************************

  Description:
  Writes a string in the buffer with the provided attribute. The routine
copies until the EOS is found or the buffer is filled.@p
  Modified to avoid writes passing the end of the buffer. Optimized for
32 bits. Translated to asm just for fun, I think is a little bit faster.
SET.
  The optional maxLen argument can be used to limit how many characters
should be copied from the string.

***************************************************************************/
	
	void moveStr(uint indent, in char[] str, uint attr, int maxLen = int.max) {
		if (attrib != 0) {
			attr = attrib;
		}
		int endPos = indent + min(maxLen, min(maxViewWidth - indent, str.length));
		CharInfo[] dest = data[indent..endPos];
		int srcIndex = 0;
		foreach(dstIndex; indent..endPos) {
			putChar(dstIndex, str[srcIndex++]);
			putAttribute(dstIndex, cast(ubyte)attr);
		}
	}
}