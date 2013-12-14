module tvalidator;

import std.typecons;

import tstringcollection;
import tobject;

enum TPicResult {prComplete, prIncomplete, prEmpty, prError, prSyntax,
prAmbiguous, prIncompNoFill};


enum TVTransfer{
	vtDataSize,
		vtSetData,
		vtGetData
} ;

const ushort
	// TValidator Status constants
	vsOk            = 0,
	vsSyntax        = 1,
	// Validator option flags
	voFill          = 0x0001,
	voTransfer      = 0x0002,
	voOnAppend      = 0x0004,
	voReserved      = 0x00F8;

abstract class TValidator : TObject {
	ushort status;
	ushort options;

	bool validate(string S) {
		if (isValid(S))
			return true;
		error();
		return false;
	}

	abstract void error();
	abstract bool isValidInput(in char[], Flag!"noAutoFill" noAutoFill);
	abstract bool isValid(in char[]);
	abstract ushort transfer(char[], void *, TVTransfer);
	abstract void format(char *source);
	abstract bool validate(in char[]);

}

class TFilterValidator : TValidator {
	protected string validChars;
}

class TRangeValidator : TFilterValidator {
	protected long min, max;
}

class TPXPictureValidator : TValidator {
	char *pic;

	private int index, jndex;
    private static string errorMsg;
}

class TLookupValidator : TValidator {

}

class TStringLookupValidator : TLookupValidator {
	TStringCollection strings;
    static string errorMsg;
}