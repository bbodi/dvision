module trect;

import configfile;
import std.algorithm;

import tpoint;

struct TRect {

	TPoint a, b;

	this(int ax, int ay, int bx, int by) {
	    a.x = ax;
	    a.y = ay;
	    b.x = bx;
	    b.y = by;
	}

	this(in TPoint p1, in TPoint p2 ) {
    	a = p1;
    	b = p2;
	}

	void move( int deltaX, int deltaY ) {
	    a.x += deltaX;
	    a.y += deltaY;
	    b.x += deltaX;
	    b.y += deltaY;
	}

	ref TRect grow( int deltaX, int deltaY ) {
	    a.x -= deltaX;
	    a.y -= deltaY;
	    b.x += deltaX;
	    b.y += deltaY;
		return this;
	}

	void intersect( in TRect r ) {
	    a.x = max( a.x, r.a.x );
	    a.y = max( a.y, r.a.y );
	    b.x = min( b.x, r.b.x );
	    b.y = min( b.y, r.b.y );
	}

	void Union( in TRect r ) {
	    a.x = min( a.x, r.a.x );
	    a.y = min( a.y, r.a.y );
	    b.x = max( b.x, r.b.x );
	    b.y = max( b.y, r.b.y );
	}

	bool contains( in TPoint p ) const {
    	return p.x >= a.x && p.x < b.x && p.y >= a.y && p.y < b.y;
	}

	bool opEquals(in TRect other) const {
		return a == other.a && b == other.b;
	}

	bool isEmpty() const {
		return a.x >= b.x || a.y >= b.y;
	}

	void deSerializeFrom(Elem* stream) {
		a.deSerializeFrom(stream.a);
		b.deSerializeFrom(stream.b);
	}

	void serializeTo(Elem* stream) {
		a.serializeTo(stream.a);
		b.serializeTo(stream.b);
	}
}