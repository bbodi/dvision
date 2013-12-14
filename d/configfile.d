module configfile;

import std.json;
import std.algorithm;
import std.array : array;
import std.stream : OutputStream, Stream;

struct Elem {

	private immutable string __name;
	private Elem* __parent;
	private JSONValue __jsonValue;
	private Elem*[string] __children;

	static Elem* fromFile(Stream ins) {
		return new Elem("asd", null, parseJSON(ins.toString()));
	}

	this(string name, Elem* parent = null, JSONValue jsonValue = JSONValue.init) {
		this.__name = name;
		this.__parent = parent;
		this.__jsonValue = jsonValue;
	}

	@property Elem* opDispatch(string name)() {
		if (name in __children) {
			return __children[name];
		}
		JSONValue defaultValue;
		if (name in __jsonValue.object) {
			defaultValue = __jsonValue.object[name];
		}
		Elem* elem = new Elem(name, &this, defaultValue);
		__children[name] = elem;
		return elem;
	}

	private JSONValue toJson(T)(T data) {
		JSONValue val;
		static if (is(T : long)) {
			val.integer = data;
			val.type = JSON_TYPE.INTEGER;
		} else static if (is(T : real)) {
			val.floating = data;
			val.type = JSON_TYPE.FLOAT;
		} else static if (is(T : string)) {
			val.str = data;
			val.type = JSON_TYPE.STRING;
		} else static if (is(T : Elem)) {
			val = data.__jsonValue;
		} else {
			static assert(false, "Invalid");
		}
		return val;
	}

	void set(T)(T rhs) {
		__jsonValue.type = JSON_TYPE.OBJECT;
		JSONValue val = toJson(rhs);
		if (__parent !is null) {
			__parent.__jsonValue.type = JSON_TYPE.OBJECT;
			this.__jsonValue = val;
			registerThisToAllParents();
		} else {
			this.__jsonValue.object[__name] = val;
		}
	}

	void add(T)(T data) {
		auto val = toJson(data);
		__jsonValue.type = JSON_TYPE.ARRAY;
		__jsonValue.array ~= val;
		if (__parent !is null) {
			registerThisToAllParents();
		}
	}

	private void registerThisToAllParents() {
		Elem* parent = __parent;
		string name = __name;
		JSONValue val = __jsonValue;
		while(parent !is null) {
			parent.__jsonValue.object[name] = val;
			if (parent.__jsonValue.type == JSON_TYPE.init) {
				parent.__jsonValue.type = JSON_TYPE.OBJECT;
			}
			name = parent.__name;
			val = parent.__jsonValue;
			parent = parent.__parent;
		}
	}

	Elem*[] array() {
		return std.array.array(map!(a => new Elem("unknown", &this, a))(__jsonValue.array));
	}

	@property T value(T)() {
		static if (is(T == long)) {
			return __jsonValue.integer;
		} else static if (is(T == ulong)) {
			return cast(ulong)__jsonValue.integer;
		} else static if (is(T == ushort)) {
			return cast(ushort)__jsonValue.integer;
		} else static if (is(T == bool)) {
			return cast(bool)__jsonValue.integer;
		} else static if (is(T : int)) {
			return cast(int)__jsonValue.integer;
		} else static if (is(T : real)) {
			return __jsonValue.floating;
		} else static if (is(T : string)) {
			return __jsonValue.str;
		} else {
			static assert(false, "Invalid");
		}
	}

	string toString() {
		return toJSON(&__jsonValue);
	}
	
}

unittest {
	Elem p;
	p.nameDefinedByUser.set(12);
	p.asd.set(113);
	foreach(i; 0..3) {
		Elem item;
		item.a.set(12+i);
		item.b.set("13");
		p.items.add(item);
	}
	p.numbers.add(1);
	p.numbers.add(2);
	p.numbers.add(3);
	p.numbers.add(4);
	p.a.b.c.set(3);
	string str = p.toString();
	p.nameDefinedByUser.set(13);
	assert(p.nameDefinedByUser.value!int == 13);
	foreach(i, item; p.items.array()) {
		assert(item.a.value!int == 12+i);
		assert(item.b.value!string == "13");
	}
}