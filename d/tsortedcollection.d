module tsortedcollection;

import std.algorithm;

import tcollection;
import tstreamable;
import std.stream;
import ttypes;
import configfile;

abstract class TSortedCollection(T) : TCollection!T, TStreamable {

	bool duplicates;

	abstract void sort();

	this( Elem* inStream )  {
		read(inStream);
	}

	override string streamableName() const { 
		return TSortedCollection.stringof; 
	}

	this(ccIndex aLimit, ccIndex aDelta) {
		super(aLimit, aDelta);
		duplicates = false;
		delta = aDelta;
		setLimit( aLimit );
	}

	override void write( Elem* os ) {
		//TCollection!T.write(os);
		//os.write(cast(int)duplicates);
	}

	override void read( Elem* ) {
		/*TCollection!T.read(inputStream);
		int temp;
		inputStream.read(temp);
		duplicates = temp != 0;*/
	}
}