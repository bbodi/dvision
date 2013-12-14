module tcollection;

import tobject;
import tstreamable;
import ttypes;
import std.c.stdlib;
import tvconfig;
import configfile;

import std.stream;

abstract class TCollection(T) : TObject, TStreamable {
	abstract T readItem( InputStream );
    abstract void writeItem( in T, OutputStream );

    protected T[] items;
    protected ccIndex count;
	protected ccIndex limit;
    protected ccIndex delta;
    protected bool shouldDelete;

	this( ccIndex aLimit, ccIndex aDelta ) {
		delta = aDelta; 
		setLimit( aLimit );
	}

	override string streamableName() const { 
		return TCollection.stringof; 
	}

	override void write( Elem* os ) {
		/*os.write(count);
		os.write(limit);
		os.write(delta);
	    for( ccIndex idx = 0; idx < count; idx++ ) {
	    	writeItem(items[idx], os);
	    }*/
	}

	override void read( Elem* inputStream ) {
		/*int limit;
		inputStream.read(count);
		inputStream.read(limit);
		inputStream.read(delta);
	    limit = 0;
	    setLimit(limit);
	    for( ccIndex idx = 0; idx < count; idx++ ) {
			// TODO
	        //items[idx] = readItem( inputStream );
		}*/
	}

	this( Elem* inStream) {
		read(inStream);
	}

	T at( ccIndex index ) {
		if( index < 0 || index >= count )
			error(1,0);
		return items[index];
	}

    ccIndex getCount() const { 
    	return count; 
    }

	this() {
		this.shouldDelete = true;
	    this.items = null;
	}

	~this() {
	    //delete[] items;
	}

	override void shutDown() {
	    if( shouldDelete )
	        freeAll();
	    else
	        count = 0;
	    setLimit(0);
		TObject.shutDown();
	}

	void atRemove( ccIndex index ) {
	    if( index < 0 || index >= count )
	        error(1,0);

	    count--;
	    items = items[0..index] ~ items[index+1..$];
	    //CLY_memcpy( &items[index], &items[index+1], (count-index)*sizeof(void *) );
	}

	void atFree( ccIndex index ) {
		T item = at( index ); // It could be: (*this)[index];
	    atRemove( index );
	    freeItem( item );
	}

	ccIndex insert(T item ) {
		ccIndex loc = count;
		atInsert( count, item );
		return loc;
	}


	void atInsert(in ccIndex index, T item) {
	    if( index < 0 )
	        error(1,0);
	    if( count == limit )
	        setLimit(count + delta);
	    items = items[0..index] ~ item ~ items[index..$];
	    //memmove( &items[index+1], &items[index], (count-index)*sizeof(void *) );
	    count++;
	}

	void atPut( ccIndex index, T item ) {
	    if( index >= count )
	        error(1,0);

	    items[index] = item;
	}

	// by SET
	void atReplace( ccIndex index, T item ) {
	    freeItem( at( index ) );
	    atPut( index, item );
	}

	void remove( T item ) {
	    atRemove( indexOf(item) );
	}

	void removeAll() {
	    count = 0;
	}

	void error( ccIndex /* code */, ccIndex ) {
	    exit(-1);
	}

	T firstThat( ccTestFunc!T Test, T arg ) {
	    for( ccIndex i = 0; i < count; i++ ) {
			if( Test( items[i], arg ) == true )
				return items[i];
	    }
	    return null;
	}

	T lastThat( ccTestFunc!T Test, T arg ) {
	    for( ccIndex i = count; i > 0; i-- ) {
	        if( Test( items[i-1], arg ) == true )
	            return items[i-1];
	        }
	    return null;
	}

	void forEach( ccAppFunc!T action, T arg ) {
	    for( ccIndex i = 0; i < count; i++ )
	        action( items[i], arg );
	}

	void free( T item ) {
	    remove( item );
	    freeItem( item );
	}

	void freeAll() {
	    for( ccIndex i =  0; i < count; i++ )
	        freeItem( at(i) );
	    count = 0;
	}

	void freeItem( T item ) {
	    //delete[] (char *)item;
	}

	ccIndex indexOf(in T item) {
	    for( ccIndex i = 0; i < count; i++ )
	        if( item is items[i] )
	            return i;

	    error(1,0);
	    return -1;
	}


	void pack() {
	    if (count == 0) return;
	    T* curDst = items.ptr;
	    T* curSrc = items.ptr;
	    T* last = items.ptr + count;
	    while( curSrc < last ) {
			if( *curSrc != null )
				*curDst++ = *curSrc;
			curSrc++;
		}
	}

	void setLimit(ccIndex aLimit) {
	    if( aLimit < count )
	        aLimit =  count;
	    if( aLimit > maxCollectionSize)
	        aLimit = maxCollectionSize;
	    if( aLimit != limit ) {
	        T[] aItems;
	        if (aLimit == 0 )
	            aItems = null;
	        else {
	            aItems = new T[aLimit];
	            if( count !=  0 && items ) {
					// ez miért nem működik? :(
					aItems[0..count][] = items[0..count][];
					foreach(i, ref a; aItems) {
						a = items[i];
					}
	            	
	            	// memcpy( aItems, items, count*sizeof(void *) );
	            }
	        }
	        items =  aItems;
	        limit =  aLimit;
	    }
	}

	/**[txh]********************************************************************

	  Description:
	  Just like at() but not inline and easier to call in some cases.

	***************************************************************************/

	T opIndex(ccIndex i) {
		if (i<0 || i>=count)
	    	error(1,0);
	 	return items[i];
	}
}