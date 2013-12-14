module common;

import std.uni;
import std.utf;

import tpoint;

const ubyte shadowAttr = 0x08;
const EOS =	'\0';

string __(string str) {
	return str;
}

string _(string str) {
	return str;
}

char hotKey( string s ) {
    auto index = std.string.indexOf(s, "~");
    if( index != -1 )
        return cast(char)(s[index+1].toUpper());
    else
        return 0;
}


TPoint shadowSize = {2,1};

import std.uni;
bool CompareUpperASCII(char a, char b) {
	return toUpper(a) == toUpper(b);
}

@property int lenWithoutTides(S)(in S str) {
	import std.algorithm : max, count;
	return max(0, std.utf.count(str) - str.count("~"));
}

import tpalette;
mixin template DefinePalette(alias paletteData) {
	static immutable ubyte[] cpPalette = paletteData;
	static immutable TPalette myPalette = immutable(TPalette)(paletteData);
}

void insert(T)(ref T[] array, int pos, T elem) {
	array = array[0..pos] ~ elem ~ array[pos..$];
}

void add(T)(ref T[] array, T elem) {
	array ~= elem;
}

string stringToString(string s) {
	return s;
}

import std.file;
