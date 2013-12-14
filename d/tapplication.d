module tapplication;

import tprogram;
import tscreen;
import teventqueue;

abstract class TApplication : TProgram {

	void resume() {
		TScreen.resume();
		TEventQueue.resume(TScreen.getCols(), TScreen.getRows());
		resetIdleTime(); // Don't count this time
	}
	
	void suspend() {
		TEventQueue.suspend();
		TScreen.suspend();
	}
	
	this() {
		TEventQueue.init(TScreen.getCols(), TScreen.getRows());
	}
	
	~this() {
	}
}