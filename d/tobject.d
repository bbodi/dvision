module tobject;

void destroy0(ref TObject o) {
	CLY_destroy(o);
 	o = null;
}

void CLY_destroy( TObject o ) {
	if( o !is null ) {
		o.shutDown();
	}
	//delete o;	
}

abstract class TObject {
	void shutDown() {
	}
}