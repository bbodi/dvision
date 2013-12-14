module tpalette;

struct TPalette {
	ubyte[] data;

    this( in ubyte[] d ) immutable {
		if (d is null) {
			data = [0];
		} else {
			data = ([cast(ubyte)d.length] ~ d).idup;
		}
	}

	unittest {
		ubyte[] array = [1, 2, 3, 4];
		immutable TPalette pal = immutable(TPalette)(array);
		assert(pal.data !is null);
		assert(pal.data.length == 5);
		assert(pal.data[0] == 4);
		assert(pal.data[1..$] == array);
		assert(pal.data !is array);
	}

	this( in TPalette tp ) {
		data = tp.data.dup;
	}

	ubyte opIndex(int index) const {
        return data[index];
    }

}