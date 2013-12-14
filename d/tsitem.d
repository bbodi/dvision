module tsitem;

struct TSItem {
	string value;
	TSItem *next;

	void opOpAssign(string op)(TSItem *other) if (op == "+=") {
		append(other);
	}

	TSItem* opBinary(string op)(TSItem *other)  if (op == "+") {
		TSItem ret = new TSItem(value, next);
		ret.append(other);
		return ret;
	}

	void append( TSItem *aNext ) {
		TSItem *item = &this;
		for ( ; item.next; item = item.next ){
		}
		item.next = aNext;
	}
}