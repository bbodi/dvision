module tpoint;

import configfile;

struct TPoint {
	int x, y;

	TPoint opBinary(string op)(in ref TPoint rhs) const {
		TPoint result;
		mixin("result.x = this.x " ~ op ~ " rhs.x;");
		mixin("result.y = this.y " ~ op ~ " rhs.y;");
		return result;
	}

	void opOpAssign(string op)(in ref TPoint rhs) {
		mixin("x " ~ op ~ "= rhs.x;");
		mixin("y " ~ op ~ "= rhs.y;");
	}

	void deSerializeFrom(Elem* stream) {
		x = stream.x.value!int;
		y = stream.y.value!int;
	}

	void serializeTo(Elem* stream) const {
		stream.x.set(x);
		stream.y.set(y);
	}

	bool opEquals(in ref TPoint other) const {
		return x == other.x && y == other.y;
	}

}