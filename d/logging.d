module logging;

import std.stdio;
import std.array;
import std.algorithm;

struct Logger {
	enum Level {
		error, warning, info, trace
	}

	private File *destination;
	Level currentLevel;

	private int ident;
	private string mySectionName;
	private Logger *parent;

	private bool sectionNameWritten;


	~this() {
		if (parent !is null) {
			parent.ident--;
		}
	}

	Logger createSectionLogger(string sectionName) {
		ident++;
		return Logger(destination, currentLevel, ident, sectionName, &this);
	}

	private void writeUnwrittenSectionName() {
		if (sectionNameWritten == false) {
			destination.writefln(replicate("\t", ident) ~ mySectionName);
			sectionNameWritten = true;
		}
	}

	void logInfo(C, T...)(C[] fmt,T args) {
		writeUnwrittenSectionName();
		destination.writefln(replicate("\t", ident) ~ "[INFO] " ~ fmt, args);
		destination.flush();
	}

	void logTrace(C, T...)(C[] fmt,T args) {
		writeUnwrittenSectionName();
		destination.writefln(replicate("\t", ident)~"[TRACE] " ~ fmt, args);
		destination.flush();
	}

	void logWarn(C, T...)(C[] fmt,T args) {
		writeUnwrittenSectionName();
		destination.writefln(replicate("\t", ident)~"[WARN] " ~ fmt, args);
		destination.flush();
	}

	void logError(C, T...)(C[] fmt,T args) {
		writeUnwrittenSectionName();
		destination.writefln(replicate("\t", ident)~"[ERROR] " ~ fmt, args);
		destination.flush();
	}
}

__gshared Logger *logger = new Logger(new File("logging.txt", "w"), Logger.Level.trace);