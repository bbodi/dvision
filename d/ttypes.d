module ttypes;

import std.exception;
import std.algorithm;
import std.string;

alias int pid_t;
alias int ccIndex;

template ccTestFunc(T) {
	alias bool function(T, T) ccTestFunc;
	alias void function(T, T) ccAppFunc;
}

template ccAppFunc(T) {
	alias void function(T, T) ccAppFunc;
}

const int ccNotFound = -1;


unittest {
	auto a = Optional!int(2);
	assert(a.isNull == false);
	assert(a.get == 2);
	
	auto b = Optional!int(0, true);
	assert(b.isNull == true);
	assertThrown(b.get == 0);
	
	auto c = None!int;
	auto d = Some(2);
}

struct Optional(T) {
	private T _value;
	private bool _isNull;
	
	@property bool isNull() const {
		return _isNull;
	}
	
	@property bool hasValue() const {
		return _isNull == false;
	}
	
	inout(T) get() inout {
		enforce(_isNull == false);
		return _value;
	}

	@property Optional!T none() {
		return None!T();
	}

	@property Optional!T some(U)(U val) {
		return Some!T(cast(T)val);
	}
}

static Optional!T Some(T)(T value) {
	static if (is(T == class)) {
		enforce(value !is null, "Use None instead!");
	}
	return Optional!T(value, false);
}

static @property Optional!T None(T)() {
	return Optional!T(T.init, true);
}