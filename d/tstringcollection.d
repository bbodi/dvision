module tstringcollection;

import std.stream;
import std.string;
import std.algorithm;

import tsortedcollection;
import ttypes;
import tstreamable;
import configfile;

class TStringCollection : TSortedCollection!string {

	this(ccIndex aLimit, ccIndex aDelta) {
		super(aLimit, aDelta);
	}

	this(Elem* inStream) {
		super(inStream);
	}


	static bool compare(in string key1, in string key2) {
		return icmp( key1, key2 ) < 0;
	}

	override void sort() {
		items.sort!compare();
	}

	override void freeItem( string item ) {
	    //delete[] (char *)item;
	}


	override void writeItem( in string obj, OutputStream os ) {
	    os.write(cast(ubyte[])obj);
	}

	override string readItem( InputStream inputStream ) {
		ubyte[] str;
    	inputStream.read(str);
    	return cast(string)str;
	}

	//TStringCollection operator = (in TStringCollection pl)	 {
	TStringCollection fillBy(TStringCollection pl)	 {
	  int i;
	  duplicates = pl.duplicates;
	  freeAll();
	  for (i=0;i<pl.count;i++) {
	    insert(pl.items[i]);
	  }
	  return this;
	}
}