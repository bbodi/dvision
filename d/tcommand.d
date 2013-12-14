module tcommandset;

import std.algorithm;
import commands;



struct TCommandSet {

	private Command[] disabledCommands;

	void opOpAssign(string op)(Command cmd) {
		static if (op == "+=") {
			enableCmd( cmd );
		} else if (op == "-=") {
			disableCmd(cmd);
		}
	}

	void opOpAssign(string op)(in ref TCommandSet tc) {
		static if (op == "+=") {
			enableCmd( tc );
		} else if (op == "-=") {
			disableCmd(tc);
		} 
	}

	TCommandSet opBinary(string op)(in ref TCommandSet other) if (op == "&" || op == "|") {
		TCommandSet result = TCommandSet(this);
		mixin("result " ~ op ~ "= other;");
		return result;
	}

	void enableAllCommands() {
  		disabledCommands.length = 0;
	}

	this(in ref TCommandSet other) {
		this.disabledCommands = other.disabledCommands.dup;		
	}

	void opAssign(in TCommandSet other) {
		this.disabledCommands = other.disabledCommands.dup;
	}

	bool has( Command cmd ) const {
	    return disabledCommands.canFind(cmd) == false ;
	}

	void disableCmd( Command cmd ) 	{
		if (has(cmd) == false ) {
			return;
		}
		disabledCommands ~= cmd;
	}

	void enableCmd( in ref TCommandSet other ) {
		foreach(disabledCmd; this.disabledCommands) {
			if (other.has(disabledCmd)) {
				enableCmd(disabledCmd);
			}
		}
	}

	void disableCmd( in ref TCommandSet other ) {
		foreach(disabledCmd; other.disabledCommands) {
			if (this.has(disabledCmd)) {
				disableCmd(disabledCmd);
			}
		}
	}

	void enableCmd( Command cmd ) {
		int index = disabledCommands.countUntil(cmd);
		if (index != -1) {
			disabledCommands = disabledCommands[0..index] ~ disabledCommands[index+1..$];
		}
	}


	bool opEquals(in ref TCommandSet other) const {
		return this.disabledCommands == other.disabledCommands;
	}

}