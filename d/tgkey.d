module tgkey;

import std.algorithm;
import std.string;

import tevent;
import tgkey;

union KeyType
{
	ushort full;
	struct b
	{
		version(TV_BIG_ENDIAN) {
			ubyte scan;
			ubyte ascii;
		} else {
			ubyte ascii;
			ubyte scan;
		}
	};
} ;

/*------------------------------------------------------------------------*/
/*                                                                        */
/*  ctrlToArrow                                                           */
/*                                                                        */
/*  argument:                                                             */
/*                                                                        */
/*      keyCode - scan code to be mapped to keypad arrow code             */
/*                                                                        */
/*  returns:                                                              */
/*                                                                        */
/*      scan code for arrow key corresponding to Wordstar key,            */
/*      or original key code if no correspondence exists                  */
/*                                                                        */
/*------------------------------------------------------------------------*/
KeyCode ctrlToArrow(KeyCode keyCode) {

	static const KeyCode ctrlCodes[] =
    [
		KeyCode.kbCtrlS, KeyCode.kbCtrlD, KeyCode.kbCtrlE, KeyCode.kbCtrlX, KeyCode.kbCtrlA,
		KeyCode.kbCtrlF, KeyCode.kbCtrlG, KeyCode.kbCtrlV, KeyCode.kbCtrlR, KeyCode.kbCtrlC, KeyCode.kbCtrlH
    ];

	static const KeyCode arrowCodes[] =
    [
		KeyCode.kbLeft, KeyCode.kbRight, KeyCode.kbUp, KeyCode.kbDown, KeyCode.kbHome,
		KeyCode.kbEnd,  KeyCode.kbDelete,   KeyCode.kbInsert,KeyCode.kbPgUp, KeyCode.kbPgDn, KeyCode.kbBackSpace
    ];

    /* The keycode contains now also the shift flags, which the
	caller don't want to see */
    ushort _keyCode = keyCode & 0x7F;

	foreach(ctrlCode; ctrlCodes) {
		if( _keyCode==ctrlCode ) {
			return ctrlCode;
		}
	}        
    /* If it was not found, return the original code */
    return keyCode;
}

version = Uses_FullSingleKeySymbols;
version(Uses_FullSingleKeySymbols) {
	// Key constants, basically they are from the US keyboard, but all of them
	// are standard ASCII and not extended.
	enum KeyCode {
		kbNoKey     = 0x0000,
		kbUnkNown=0,
			kbA= 1,kbB= 2,kbC= 3,kbD= 4,kbE= 5,kbF= 6,kbG= 7,kbH= 8,kbI= 9,kbJ=10,kbK=11,
			kbL=12,kbM=13,kbN=14,kbO=15,kbP=16,kbQ=17,kbR=18,kbS=19,kbT=20,kbU=21,kbV=22,
			kbW=23,kbX=24,kbY=25,kbZ=26,
			kbOpenBrace=27,kbBackSlash=28,kbCloseBrace=29,kbPause=30,kbEsc=31,
			kb0=32,kb1=33,kb2=34,kb3=35,kb4=36,kb5=37,kb6=38,kb7=39,kb8=40,kb9=41,
			kbBackSpace=42,kbTab=43,kbEnter=44,kbColon=45,kbQuote=46,kbGrave=47,
			kbComma=48,kbStop=49,kbSlash=50,kbAsterisk=51,kbSpace=52,kbMinus=53,
			kbPlus=54,kbPrnScr=55,kbEqual=56,kbF1=57,kbF2=58,kbF3=59,kbF4=60,kbF5=61,
			kbF6=62,kbF7=63,kbF8=64,kbF9=65,kbF10=66,kbF11=67,kbF12=68,kbHome=69,
			kbUp=70,kbPgUp=71,kbLeft=72,kbRight=73,kbEnd=74,kbDown=75,kbPgDn=76,
			kbInsert=77,kbDelete=78,kbCaret=79,kbAdmid=80,kbDobleQuote=81,
			kbNumeral=82,kbDolar=83,kbPercent=84,kbAmper=85,kbOpenPar=86,
			kbClosePar=87,kbDoubleDot=88,kbLessThan=89,kbGreaterThan=90,
			kbQuestion=91,kbA_Roba=92,kbOr=93,kbUnderLine=94,kbOpenCurly=95,
			kbCloseCurly=96,kbTilde=97,kbMacro=98,kbWinLeft=99,kbWinRight=100,
			kbWinSel=101,
			kbMouse=102,kbEterm=103,
			

		kbShUnknown=0x0080,kbShA=0x0081,kbShB=0x0082,kbShC=0x0083,kbShD=0x0084,
		kbShE=0x0085,kbShF=0x0086,kbShG=0x0087,kbShH=0x0088,kbShI=0x0089,
		kbShJ=0x008a,kbShK=0x008b,kbShL=0x008c,kbShM=0x008d,kbShN=0x008e,
		kbShO=0x008f,kbShP=0x0090,kbShQ=0x0091,kbShR=0x0092,kbShS=0x0093,
		kbShT=0x0094,kbShU=0x0095,kbShV=0x0096,kbShW=0x0097,kbShX=0x0098,
		kbShY=0x0099,kbShZ=0x009a,kbShOpenBrace=0x009b,kbShBackSlash=0x009c,
		kbShCloseBrace=0x009d,kbShPause=0x009e,kbShEsc=0x009f,kbSh0=0x00a0,
		kbSh1=0x00a1,kbSh2=0x00a2,kbSh3=0x00a3,kbSh4=0x00a4,kbSh5=0x00a5,
		kbSh6=0x00a6,kbSh7=0x00a7,kbSh8=0x00a8,kbSh9=0x00a9,
		kbShBackSpace=0x00aa,kbShTab=0x00ab,kbShEnter=0x00ac,
		kbShColon=0x00ad,kbShQuote=0x00ae,kbShGrave=0x00af,kbShComma=0x00b0,
		kbShStop=0x00b1,kbShSlash=0x00b2,kbShAsterisk=0x00b3,kbShSpace=0x00b4,
		kbShMinus=0x00b5,kbShPlus=0x00b6,kbShPrnScr=0x00b7,kbShEqual=0x00b8,
		kbShF1=0x00b9,kbShF2=0x00ba,kbShF3=0x00bb,kbShF4=0x00bc,kbShF5=0x00bd,
		kbShF6=0x00be,kbShF7=0x00bf,kbShF8=0x00c0,kbShF9=0x00c1,kbShF10=0x00c2,
		kbShF11=0x00c3,kbShF12=0x00c4,kbShHome=0x00c5,kbShUp=0x00c6,
		kbShPgUp=0x00c7,kbShLeft=0x00c8,kbShRight=0x00c9,kbShEnd=0x00ca,
		kbShDown=0x00cb,kbShPgDn=0x00cc,kbShInsert=0x00cd,kbShDelete=0x00ce,
		kbShCaret=0x00cf,kbShAdmid=0x00d0,kbShDobleQuote=0x00d1,
		kbShNumeral=0x00d2,kbShDolar=0x00d3,kbShPercent=0x00d4,
		kbShAmper=0x00d5,kbShOpenPar=0x00d6,kbShClosePar=0x00d7,
		kbShDoubleDot=0x00d8,kbShLessThan=0x00d9,kbShGreaterThan=0x00da,
		kbShQuestion=0x00db,kbShA_Roba=0x00dc,kbShOr=0x00dd,
		kbShUnderLine=0x00de,kbShOpenCurly=0x00df,kbShCloseCurly=0x00e0,
		kbShTilde=0x00e1,kbShMacro=0x00e2,kbShWinLeft=0x00e3,
		kbShWinRight=0x00e4,kbShWinSel=0x00e5,

		kbCtrlUnknown=0x0100,kbCtrlA=0x0101,kbCtrlB=0x0102,kbCtrlC=0x0103,kbCtrlD=0x0104,
		kbCtrlE=0x0105,kbCtrlF=0x0106,kbCtrlG=0x0107,kbCtrlH=0x0108,kbCtrlI=0x0109,
		kbCtrlJ=0x010a,kbCtrlK=0x010b,kbCtrlL=0x010c,kbCtrlM=0x010d,kbCtrlN=0x010e,
		kbCtrlO=0x010f,kbCtrlP=0x0110,kbCtrlQ=0x0111,kbCtrlR=0x0112,kbCtrlS=0x0113,
		kbCtrlT=0x0114,kbCtrlU=0x0115,kbCtrlV=0x0116,kbCtrlW=0x0117,kbCtrlX=0x0118,
		kbCtrlY=0x0119,kbCtrlZ=0x011a,kbCtrlOpenBrace=0x011b,kbCtrlBackSlash=0x011c,
		kbCtrlCloseBrace=0x011d,kbCtrlPause=0x011e,kbCtrlEsc=0x011f,kbCtrl0=0x0120,
		kbCtrl1=0x0121,kbCtrl2=0x0122,kbCtrl3=0x0123,kbCtrl4=0x0124,kbCtrl5=0x0125,
		kbCtrl6=0x0126,kbCtrl7=0x0127,kbCtrl8=0x0128,kbCtrl9=0x0129,
		kbCtrlBackSpace=0x012a,kbCtrlTab=0x012b,kbCtrlEnter=0x012c,kbCtrlColon=0x012d,
		kbCtrlQuote=0x012e,kbCtrlGrave=0x012f,kbCtrlComma=0x0130,kbCtrlStop=0x0131,
		kbCtrlSlash=0x0132,kbCtrlAsterisk=0x0133,kbCtrlSpace=0x0134,kbCtrlMinus=0x0135,
		kbCtrlPlus=0x0136,kbCtrlPrnScr=0x0137,kbCtrlEqual=0x0138,kbCtrlF1=0x0139,
		kbCtrlF2=0x013a,kbCtrlF3=0x013b,kbCtrlF4=0x013c,kbCtrlF5=0x013d,kbCtrlF6=0x013e,
		kbCtrlF7=0x013f,kbCtrlF8=0x0140,kbCtrlF9=0x0141,kbCtrlF10=0x0142,kbCtrlF11=0x0143,
		kbCtrlF12=0x0144,kbCtrlHome=0x0145,kbCtrlUp=0x0146,kbCtrlPgUp=0x0147,
		kbCtrlLeft=0x0148,kbCtrlRight=0x0149,kbCtrlEnd=0x014a,kbCtrlDown=0x014b,
		kbCtrlPgDn=0x014c,kbCtrlInsert=0x014d,kbCtrlDelete=0x014e,kbCtrlCaret=0x014f,
		kbCtrlAdmid=0x0150,kbCtrlDobleQuote=0x0151,kbCtrlNumeral=0x0152,
		kbCtrlDolar=0x0153,kbCtrlPercent=0x0154,kbCtrlAmper=0x0155,kbCtrlOpenPar=0x0156,
		kbCtrlClosePar=0x0157,kbCtrlDoubleDot=0x0158,kbCtrlLessThan=0x0159,
		kbCtrlGreaterThan=0x015a,kbCtrlQuestion=0x015b,kbCtrlA_Roba=0x015c,
		kbCtrlOr=0x015d,kbCtrlUnderLine=0x015e,kbCtrlOpenCurly=0x015f,
		kbCtrlCloseCurly=0x0160,kbCtrlTilde=0x0161,kbCtrlMacro=0x0162,kbCtrlWinLeft=0x0163,
		kbCtrlWinRight=0x0164,kbCtrlWinSel=0x0165,

		kbShCtUnknown=0x0180,kbShCtA=0x0181,kbShCtB=0x0182,kbShCtC=0x0183,
		kbShCtD=0x0184,kbShCtE=0x0185,kbShCtF=0x0186,kbShCtG=0x0187,
		kbShCtH=0x0188,kbShCtI=0x0189,kbShCtJ=0x018a,kbShCtK=0x018b,
		kbShCtL=0x018c,kbShCtM=0x018d,kbShCtN=0x018e,kbShCtO=0x018f,
		kbShCtP=0x0190,kbShCtQ=0x0191,kbShCtR=0x0192,kbShCtS=0x0193,
		kbShCtT=0x0194,kbShCtU=0x0195,kbShCtV=0x0196,kbShCtW=0x0197,
		kbShCtX=0x0198,kbShCtY=0x0199,kbShCtZ=0x019a,kbShCtOpenBrace=0x019b,
		kbShCtBackSlash=0x019c,kbShCtCloseBrace=0x019d,kbShCtPause=0x019e,
		kbShCtEsc=0x019f,kbShCt0=0x01a0,kbShCt1=0x01a1,kbShCt2=0x01a2,
		kbShCt3=0x01a3,kbShCt4=0x01a4,kbShCt5=0x01a5,kbShCt6=0x01a6,
		kbShCt7=0x01a7,kbShCt8=0x01a8,kbShCt9=0x01a9,kbShCtBackSpace=0x01aa,
		kbShCtTab=0x01ab,kbShCtEnter=0x01ac,kbShCtColon=0x01ad,
		kbShCtQuote=0x01ae,kbShCtGrave=0x01af,kbShCtComma=0x01b0,
		kbShCtStop=0x01b1,kbShCtSlash=0x01b2,kbShCtAsterisk=0x01b3,
		kbShCtSpace=0x01b4,kbShCtMinus=0x01b5,kbShCtPlus=0x01b6,
		kbShCtPrnScr=0x01b7,kbShCtEqual=0x01b8,kbShCtF1=0x01b9,kbShCtF2=0x01ba,
		kbShCtF3=0x01bb,kbShCtF4=0x01bc,kbShCtF5=0x01bd,kbShCtF6=0x01be,
		kbShCtF7=0x01bf,kbShCtF8=0x01c0,kbShCtF9=0x01c1,kbShCtF10=0x01c2,
		kbShCtF11=0x01c3,kbShCtF12=0x01c4,kbShCtHome=0x01c5,kbShCtUp=0x01c6,
		kbShCtPgUp=0x01c7,kbShCtLeft=0x01c8,kbShCtRight=0x01c9,kbShCtEnd=0x01ca,
		kbShCtDown=0x01cb,kbShCtPgDn=0x01cc,kbShCtInsert=0x01cd,
		kbShCtDelete=0x01ce,kbShCtCaret=0x01cf,kbShCtAdmid=0x01d0,
		kbShCtDobleQuote=0x01d1,kbShCtNumeral=0x01d2,kbShCtDolar=0x01d3,
		kbShCtPercent=0x01d4,kbShCtAmper=0x01d5,kbShCtOpenPar=0x01d6,
		kbShCtClosePar=0x01d7,kbShCtDoubleDot=0x01d8,kbShCtLessThan=0x01d9,
		kbShCtGreaterThan=0x01da,kbShCtQuestion=0x01db,kbShCtA_Roba=0x01dc,
		kbShCtOr=0x01dd,kbShCtUnderLine=0x01de,kbShCtOpenCurly=0x01df,
		kbShCtCloseCurly=0x01e0,kbShCtTilde=0x01e1,kbShCtMacro=0x01e2,
		kbShCtWinLeft=0x01e3,kbShCtWinRight=0x01e4,kbShCtWinSel=0x01e5,

		kbAltUnknown=0x0200,kbAltA=0x0201,kbAltB=0x0202,kbAltC=0x0203,kbAltD=0x0204,
		kbAltE=0x0205,kbAltF=0x0206,kbAltG=0x0207,kbAltH=0x0208,kbAltI=0x0209,
		kbAltJ=0x020a,kbAltK=0x020b,kbAltL=0x020c,kbAltM=0x020d,kbAltN=0x020e,
		kbAltO=0x020f,kbAltP=0x0210,kbAltQ=0x0211,kbAltR=0x0212,kbAltS=0x0213,
		kbAltT=0x0214,kbAltU=0x0215,kbAltV=0x0216,kbAltW=0x0217,kbAltX=0x0218,
		kbAltY=0x0219,kbAltZ=0x021a,kbAltOpenBrace=0x021b,kbAltBackSlash=0x021c,
		kbAltCloseBrace=0x021d,kbAltPause=0x021e,kbAltEsc=0x021f,kbAlt0=0x0220,
		kbAlt1=0x0221,kbAlt2=0x0222,kbAlt3=0x0223,kbAlt4=0x0224,kbAlt5=0x0225,
		kbAlt6=0x0226,kbAlt7=0x0227,kbAlt8=0x0228,kbAlt9=0x0229,
		kbAltBackSpace=0x022a,kbAltTab=0x022b,kbAltEnter=0x022c,kbAltColon=0x022d,
		kbAltQuote=0x022e,kbAltGrave=0x022f,kbAltComma=0x0230,kbAltStop=0x0231,
		kbAltSlash=0x0232,kbAltAsterisk=0x0233,kbAltSpace=0x0234,kbAltMinus=0x0235,
		kbAltPlus=0x0236,kbAltPrnScr=0x0237,kbAltEqual=0x0238,kbAltF1=0x0239,
		kbAltF2=0x023a,kbAltF3=0x023b,kbAltF4=0x023c,kbAltF5=0x023d,kbAltF6=0x023e,
		kbAltF7=0x023f,kbAltF8=0x0240,kbAltF9=0x0241,kbAltF10=0x0242,kbAltF11=0x0243,
		kbAltF12=0x0244,kbAltHome=0x0245,kbAltUp=0x0246,kbAltPgUp=0x0247,
		kbAltLeft=0x0248,kbAltRight=0x0249,kbAltEnd=0x024a,kbAltDown=0x024b,
		kbAltPgDn=0x024c,kbAltInsert=0x024d,kbAltDelete=0x024e,kbAltCaret=0x024f,
		kbAltAdmid=0x0250,kbAltDobleQuote=0x0251,kbAltNumeral=0x0252,
		kbAltDolar=0x0253,kbAltPercent=0x0254,kbAltAmper=0x0255,kbAltOpenPar=0x0256,
		kbAltClosePar=0x0257,kbAltDoubleDot=0x0258,kbAltLessThan=0x0259,
		kbAltGreaterThan=0x025a,kbAltQuestion=0x025b,kbAltA_Roba=0x025c,
		kbAltOr=0x025d,kbAltUnderLine=0x025e,kbAltOpenCurly=0x025f,
		kbAltCloseCurly=0x0260,kbAltTilde=0x0261,kbAltMacro=0x0262,kbAltWinLeft=0x0263,
		kbAltWinRight=0x0264,kbAltWinSel=0x0265,

		kbShAlUnknown=0x0280,kbShAlA=0x0281,kbShAlB=0x0282,kbShAlC=0x0283,
		kbShAlD=0x0284,kbShAlE=0x0285,kbShAlF=0x0286,kbShAlG=0x0287,
		kbShAlH=0x0288,kbShAlI=0x0289,kbShAlJ=0x028a,kbShAlK=0x028b,
		kbShAlL=0x028c,kbShAlM=0x028d,kbShAlN=0x028e,kbShAlO=0x028f,
		kbShAlP=0x0290,kbShAlQ=0x0291,kbShAlR=0x0292,kbShAlS=0x0293,
		kbShAlT=0x0294,kbShAlU=0x0295,kbShAlV=0x0296,kbShAlW=0x0297,
		kbShAlX=0x0298,kbShAlY=0x0299,kbShAlZ=0x029a,kbShAlOpenBrace=0x029b,
		kbShAlBackSlash=0x029c,kbShAlCloseBrace=0x029d,kbShAlPause=0x029e,
		kbShAlEsc=0x029f,kbShAl0=0x02a0,kbShAl1=0x02a1,kbShAl2=0x02a2,
		kbShAl3=0x02a3,kbShAl4=0x02a4,kbShAl5=0x02a5,kbShAl6=0x02a6,
		kbShAl7=0x02a7,kbShAl8=0x02a8,kbShAl9=0x02a9,kbShAlBackSpace=0x02aa,
		kbShAlTab=0x02ab,kbShAlEnter=0x02ac,kbShAlColon=0x02ad,
		kbShAlQuote=0x02ae,kbShAlGrave=0x02af,kbShAlComma=0x02b0,
		kbShAlStop=0x02b1,kbShAlSlash=0x02b2,kbShAlAsterisk=0x02b3,
		kbShAlSpace=0x02b4,kbShAlMinus=0x02b5,kbShAlPlus=0x02b6,
		kbShAlPrnScr=0x02b7,kbShAlEqual=0x02b8,kbShAlF1=0x02b9,
		kbShAlF2=0x02ba,kbShAlF3=0x02bb,kbShAlF4=0x02bc,kbShAlF5=0x02bd,
		kbShAlF6=0x02be,kbShAlF7=0x02bf,kbShAlF8=0x02c0,kbShAlF9=0x02c1,
		kbShAlF10=0x02c2,kbShAlF11=0x02c3,kbShAlF12=0x02c4,kbShAlHome=0x02c5,
		kbShAlUp=0x02c6,kbShAlPgUp=0x02c7,kbShAlLeft=0x02c8,kbShAlRight=0x02c9,
		kbShAlEnd=0x02ca,kbShAlDown=0x02cb,kbShAlPgDn=0x02cc,
		kbShAlInsert=0x02cd,kbShAlDelete=0x02ce,kbShAlCaret=0x02cf,
		kbShAlAdmid=0x02d0,kbShAlDobleQuote=0x02d1,kbShAlNumeral=0x02d2,
		kbShAlDolar=0x02d3,kbShAlPercent=0x02d4,kbShAlAmper=0x02d5,
		kbShAlOpenPar=0x02d6,kbShAlClosePar=0x02d7,kbShAlDoubleDot=0x02d8,
		kbShAlLessThan=0x02d9,kbShAlGreaterThan=0x02da,kbShAlQuestion=0x02db,
		kbShAlA_Roba=0x02dc,kbShAlOr=0x02dd,kbShAlUnderLine=0x02de,
		kbShAlOpenCurly=0x02df,kbShAlCloseCurly=0x02e0,kbShAlTilde=0x02e1,
		kbShAlMacro=0x02e2,kbShAlWinLeft=0x02e3,kbShAlWinRight=0x02e4,
		kbShAlWinSel=0x02e5,

		kbCtAlUnknown=0x0300,kbCtAlA=0x0301,kbCtAlB=0x0302,kbCtAlC=0x0303,
		kbCtAlD=0x0304,kbCtAlE=0x0305,kbCtAlF=0x0306,kbCtAlG=0x0307,
		kbCtAlH=0x0308,kbCtAlI=0x0309,kbCtAlJ=0x030a,kbCtAlK=0x030b,
		kbCtAlL=0x030c,kbCtAlM=0x030d,kbCtAlN=0x030e,kbCtAlO=0x030f,
		kbCtAlP=0x0310,kbCtAlQ=0x0311,kbCtAlR=0x0312,kbCtAlS=0x0313,
		kbCtAlT=0x0314,kbCtAlU=0x0315,kbCtAlV=0x0316,kbCtAlW=0x0317,
		kbCtAlX=0x0318,kbCtAlY=0x0319,kbCtAlZ=0x031a,kbCtAlOpenBrace=0x031b,
		kbCtAlBackSlash=0x031c,kbCtAlCloseBrace=0x031d,kbCtAlPause=0x031e,
		kbCtAlEsc=0x031f,kbCtAl0=0x0320,kbCtAl1=0x0321,kbCtAl2=0x0322,
		kbCtAl3=0x0323,kbCtAl4=0x0324,kbCtAl5=0x0325,kbCtAl6=0x0326,
		kbCtAl7=0x0327,kbCtAl8=0x0328,kbCtAl9=0x0329,kbCtAlBackSpace=0x032a,
		kbCtAlTab=0x032b,kbCtAlEnter=0x032c,kbCtAlColon=0x032d,
		kbCtAlQuote=0x032e,kbCtAlGrave=0x032f,kbCtAlComma=0x0330,
		kbCtAlStop=0x0331,kbCtAlSlash=0x0332,kbCtAlAsterisk=0x0333,
		kbCtAlSpace=0x0334,kbCtAlMinus=0x0335,kbCtAlPlus=0x0336,
		kbCtAlPrnScr=0x0337,kbCtAlEqual=0x0338,kbCtAlF1=0x0339,
		kbCtAlF2=0x033a,kbCtAlF3=0x033b,kbCtAlF4=0x033c,kbCtAlF5=0x033d,
		kbCtAlF6=0x033e,kbCtAlF7=0x033f,kbCtAlF8=0x0340,kbCtAlF9=0x0341,
		kbCtAlF10=0x0342,kbCtAlF11=0x0343,kbCtAlF12=0x0344,kbCtAlHome=0x0345,
		kbCtAlUp=0x0346,kbCtAlPgUp=0x0347,kbCtAlLeft=0x0348,kbCtAlRight=0x0349,
		kbCtAlEnd=0x034a,kbCtAlDown=0x034b,kbCtAlPgDn=0x034c,
		kbCtAlInsert=0x034d,kbCtAlDelete=0x034e,kbCtAlCaret=0x034f,
		kbCtAlAdmid=0x0350,kbCtAlDobleQuote=0x0351,kbCtAlNumeral=0x0352,
		kbCtAlDolar=0x0353,kbCtAlPercent=0x0354,kbCtAlAmper=0x0355,
		kbCtAlOpenPar=0x0356,kbCtAlClosePar=0x0357,kbCtAlDoubleDot=0x0358,
		kbCtAlLessThan=0x0359,kbCtAlGreaterThan=0x035a,kbCtAlQuestion=0x035b,
		kbCtAlA_Roba=0x035c,kbCtAlOr=0x035d,kbCtAlUnderLine=0x035e,
		kbCtAlOpenCurly=0x035f,kbCtAlCloseCurly=0x0360,kbCtAlTilde=0x0361,
		kbCtAlMacro=0x0362,kbCtAlWinLeft=0x0363,kbCtAlWinRight=0x0364,
		kbCtAlWinSel=0x0365,

		kbShCtAlUnknown=0x0380,kbShCtAlA=0x0381,kbShCtAlB=0x0382,
		kbShCtAlC=0x0383,kbShCtAlD=0x0384,kbShCtAlE=0x0385,kbShCtAlF=0x0386,
		kbShCtAlG=0x0387,kbShCtAlH=0x0388,kbShCtAlI=0x0389,kbShCtAlJ=0x038a,
		kbShCtAlK=0x038b,kbShCtAlL=0x038c,kbShCtAlM=0x038d,kbShCtAlN=0x038e,
		kbShCtAlO=0x038f,kbShCtAlP=0x0390,kbShCtAlQ=0x0391,kbShCtAlR=0x0392,
		kbShCtAlS=0x0393,kbShCtAlT=0x0394,kbShCtAlU=0x0395,kbShCtAlV=0x0396,
		kbShCtAlW=0x0397,kbShCtAlX=0x0398,kbShCtAlY=0x0399,kbShCtAlZ=0x039a,
		kbShCtAlOpenBrace=0x039b,kbShCtAlBackSlash=0x039c,
		kbShCtAlCloseBrace=0x039d,kbShCtAlPause=0x039e,kbShCtAlEsc=0x039f,
		kbShCtAl0=0x03a0,kbShCtAl1=0x03a1,kbShCtAl2=0x03a2,kbShCtAl3=0x03a3,
		kbShCtAl4=0x03a4,kbShCtAl5=0x03a5,kbShCtAl6=0x03a6,kbShCtAl7=0x03a7,
		kbShCtAl8=0x03a8,kbShCtAl9=0x03a9,kbShCtAlBackSpace=0x03aa,
		kbShCtAlTab=0x03ab,kbShCtAlEnter=0x03ac,kbShCtAlColon=0x03ad,
		kbShCtAlQuote=0x03ae,kbShCtAlGrave=0x03af,kbShCtAlComma=0x03b0,
		kbShCtAlStop=0x03b1,kbShCtAlSlash=0x03b2,kbShCtAlAsterisk=0x03b3,
		kbShCtAlSpace=0x03b4,kbShCtAlMinus=0x03b5,kbShCtAlPlus=0x03b6,
		kbShCtAlPrnScr=0x03b7,kbShCtAlEqual=0x03b8,kbShCtAlF1=0x03b9,
		kbShCtAlF2=0x03ba,kbShCtAlF3=0x03bb,kbShCtAlF4=0x03bc,kbShCtAlF5=0x03bd,
		kbShCtAlF6=0x03be,kbShCtAlF7=0x03bf,kbShCtAlF8=0x03c0,kbShCtAlF9=0x03c1,
		kbShCtAlF10=0x03c2,kbShCtAlF11=0x03c3,kbShCtAlF12=0x03c4,
		kbShCtAlHome=0x03c5,kbShCtAlUp=0x03c6,kbShCtAlPgUp=0x03c7,
		kbShCtAlLeft=0x03c8,kbShCtAlRight=0x03c9,kbShCtAlEnd=0x03ca,
		kbShCtAlDown=0x03cb,kbShCtAlPgDn=0x03cc,kbShCtAlInsert=0x03cd,
		kbShCtAlDelete=0x03ce,kbShCtAlCaret=0x03cf,kbShCtAlAdmid=0x03d0,
		kbShCtAlDobleQuote=0x03d1,kbShCtAlNumeral=0x03d2,kbShCtAlDolar=0x03d3,
		kbShCtAlPercent=0x03d4,kbShCtAlAmper=0x03d5,kbShCtAlOpenPar=0x03d6,
		kbShCtAlClosePar=0x03d7,kbShCtAlDoubleDot=0x03d8,
		kbShCtAlLessThan=0x03d9,kbShCtAlGreaterThan=0x03da,
		kbShCtAlQuestion=0x03db,kbShCtAlA_Roba=0x03dc,kbShCtAlOr=0x03dd,
		kbShCtAlUnderLine=0x03de,kbShCtAlOpenCurly=0x03df,
		kbShCtAlCloseCurly=0x03e0,kbShCtAlTilde=0x03e1,kbShCtAlMacro=0x03e2,
		kbShCtAlWinLeft=0x03e3,kbShCtAlWinRight=0x03e4,kbShCtAlWinSel=0x03e5,

		kbRightShift  = 0x0001,
		kbLeftShift   = 0x0002,
		kbShift       = kbLeftShift | kbRightShift,
		kbLeftCtrl    = 0x0004,
		kbRightCtrl   = 0x0004,
		kbCtrlShift   = kbLeftCtrl | kbRightCtrl,
		kbLeftAlt     = 0x0008,
		kbRightAlt    = 0x0008,
		kbAltShift    = kbLeftAlt | kbRightAlt,
		kbScrollState = 0x0010,
		kbNumState    = 0x0020,
		kbCapsState   = 0x0040,
		kbInsState    = 0x0080,

		kbShiftCode=0x080,
		kbCtrlCode =0x100,
		kbAltRCode =0x400,
		kbAltLCode =0x200,
		kbKeyMask  =0x07F

		}
}

/* IBM BIOS flags, not all implemented in most platforms */
/*
bit 15: SysReq key pressed;
bit 14: Caps lock key currently down;
bit 13: Num lock key currently down;
bit 12: Scroll lock key currently down;
bit 11: Right alt key is down;
bit 10: Right ctrl key is down;
bit 9: Left alt key is down;
bit 8: Left ctrl key is down;
bit 7: Insert toggle;
bit 6: Caps lock toggle;
bit 5: Num lock toggle;
bit 4: Scroll lock toggle;
bit 3: Either alt key is down (some machines, left only);
bit 2: Either ctrl key is down;
bit 1: Left shift key is down;
bit 0: Right shift key is down
*/
const uint
	kbSysReqPress     =0x8000,
		kbCapsLockDown    =0x4000,
		kbNumLockDown     =0x2000,
		kbScrollLockDown  =0x1000,
		kbRightAltDown    =0x0800,
		kbRightCtrlDown   =0x0400,
		kbLeftAltDown     =0x0200,
		kbLeftCtrlDown    =0x0100,
		kbInsertToggle    =0x0080,
		kbCapsLockToggle  =0x0040,
		kbNumLockToggle   =0x0020,
		kbScrollLockToggle=0x0010,
		kbAltDown         =0x0008,
		kbCtrlDown        =0x0004,
		kbLeftShiftDown   =0x0002,
		kbRightShiftDown  =0x0001;

extern ushort getshiftstate();
extern ushort __tv_getshiftstate();
extern ushort __tv_GetRaw();
extern int __tv_kbhit();
extern void __tv_clear();



class TGKey {
	this() {
		resume(); 
	}

	enum keyMode
	{
		// Linux styles
		linuxDisableKeyPatch=1,
		linuxEnableKeyPatch=2,
		// DOS
		// Should be incorporated to the remapping but I need volunteers
		//dosUS=0,
		//dosGreek737=20, No longer used
		dosUseBIOS=21,
		dosUseDirect=22,
		dosTranslateKeypad=23,
		dosNormalKeypad=24,
		// UNIX styles
		unixXterm=40,
		unixNoXterm=41,
		unixEterm=42
	};
	enum { codepage=0, unicode16=1 };

	static ushort   GetAltSettings() { return AltSet; }
	static void     SetAltSettings(long altSet) { AltSet = cast(ushort)altSet; }

	static int     getInputMode() { return inputMode; }

	/*****************************************************************************
  Data members initialization
*****************************************************************************/
	
	static char   suspended=1;
	// 0 => Left alt is used
	// 1 => Right alt is used
	// 2 => Both alts are the same
	static ushort AltSet=0;    // Default: Left and right key are different ones
	static int    Mode=0;
	static int    inputMode = codepage;
	static immutable string KeyNames[]=
	[
		"Unknown",
			"A","B","C","D","E","F","G","H","I","J","K",
				"L","M","N","O","P","Q","R","S","T","U","V",
				"W","X","Y","Z",
				"OpenBrace","BackSlash","CloseBrace","Pause","Esc",
				"0","1","2","3","4","5","6","7","8","9",
				"BackSpace","Tab","Enter","Colon","Quote","Grave",
				"Comma","Stop","Slash","Asterisk","Space","Minus",
				"Plus","PrnScr","Equal","F1","F2","F3","F4","F5",
				"F6","F7","F8","F9","F10","F11","F12","Home",
				"Up","PgUp","Left","Right","End","Down","PgDn",
				"Insert","Delete","Caret","Admid","DobleQuote",
				"Numeral","Dolar","Percent","Amper","OpenPar",
				"ClosePar","DoubleDot","LessThan","GreaterThan",
				"Question","A_Roba","Or","UnderLine","OpenCurly",
				"CloseCurly","Tilde","Macro","WinLeft","WinRight","WinSel",
				"Mouse"
	];
	const NumKeyNames =  KeyNames.length;

/*****************************************************************************
  Function pointer members initialization
*****************************************************************************/
	
	static int       function() kbhit                        =&defaultKbhit;
	static void      function() clear                        =&defaultClear;
	static ushort    function() gkey                             =&defaultGkey;
	static uint  function() getShiftState                    =&defaultGetShiftState;
	static void      function(ref TEvent e) fillTEvent              =&defaultFillTEvent;
	//static ubyte     function(ubyte val) NonASCII2ASCII          =&defaultNonASCII2ASCII;
	//static int       function(ubyte val, ubyte code) CompareASCII=&defaultCompareASCII;
	static void      function(int vers) SetKbdMapping         =&defaultSetKbdMapping;
	static int       function(int vers) GetKbdMapping         =&defaultGetKbdMapping;
	static void      function() Suspend                          =&defaultSuspend;
	static void      function() Resume                           =&defaultResume;
//	static int       function(int id) SetCodePage                =&defaultSetCodePage;
	//static int       function(ref TEvent event) AltInternat2ASCII   =&defaultAltInternat2ASCII;
	static void      function(ref TEvent e) fillCharCode            =&defaultFillCharCode;

/*****************************************************************************
  Default behaviors for the members
*****************************************************************************/
	
	static private int      defaultKbhit() { return 0; }
	static private uint defaultGetShiftState() { return 0; }
	static private ushort   defaultGkey() { return 0; }
	static private void     defaultClear() {}
	static private void     defaultSuspend() {}
	static private void     defaultResume() {}
	static private ubyte    defaultNonASCII2ASCII(ubyte val) { return val; }
	static private int      defaultCompareASCII(ubyte val, ubyte code) { return val==code; }
	static private void     defaultSetKbdMapping(int vers) { Mode=vers; }
	static private int      defaultGetKbdMapping(int /*version*/) { return Mode; }
	static private void     defaultFillTEvent(ref TEvent /*e*/) {};


/*****************************************************************************
  Real members
*****************************************************************************/
	
	static void suspend()
	{
		if (suspended) return;
		suspended=1;
		Suspend();
	}
	
	static void resume()
	{
		if (!suspended) return;
		suspended=0;
		Resume();
	}
	
	static string NumberToKeyName(uint val)
	{
		if (val<NumKeyNames)
			return KeyNames[val];
		return KeyNames[0];
	}
	
	const int CantDef = 0x39;
	// static string altCodes[CantDef+1]=
	static string altCodes =
		"\0ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]\0\0""0123456789\0\t\0;'`,./*\xf0-+\0=";
	
	static char GetAltChar(KeyCode keyCode, ubyte ascii) {
		// Only when ALT is present
		if ((keyCode & KeyCode.kbAltLCode)==0)
			return 0;
		keyCode &= KeyCode.kbKeyMask;
		// If the key is unknown but have an ASCII associated use it!
		if (keyCode == KeyCode.kbUnkNown && ascii) {
			return 0;
			//return NonASCII2ASCII(ascii);
		}
		if (keyCode > CantDef-1)
			return 0;
		return altCodes[keyCode];
	}
	
	static ushort GetAltCode(ubyte c)
	{
		//c = NonASCII2ASCII(c);
		c = (cast(ubyte[])toUpper(cast(string)[c]))[0];
		
		for (ushort i=0; i<CantDef; i++)
			if (altCodes[i]==c)
				return i | KeyCode.kbAltLCode; // Report the left one
		return 0;
	}
	
	static ushort KeyNameToNumber(string s)
	{
		for (ushort i=0; i<NumKeyNames; i++)
			if (icmp(KeyNames[i],s)==0)
				return i;
		return cast(ushort)-1;
	}
	
	/*****************************************************************************
  Here are some generic translation routines for known keyboards/code pages.
  They are shared by various drivers.
*****************************************************************************/
	
	/* This table maps the Unicode for greek letters with the latin letter for
 the key that generates it. Example: alpha (with any accent) is generated
 pressing the key with the latin A letter.

This note is what I wrote for the old DOS code
 Greek keyboards: That's for code page 737. This
keyboards have two modes. One mode makes them work just
as an US keyboard, pressing LShift+Alt enters in the
greek mode. In this mode a-z and A-Z generates greek
letters. They are reported without any scan code.
Additionally ;/: key is an accent key (q/Q holds ;/:).
*/
	struct stIntCodePairs
	{
		ushort unicode,code;
	};

	static immutable stIntCodePairs GreekKeyboard[]=
	[
		// With tonos
		{ 0x0386,'A' },/* 0x0387 */{ 0x0388,'E' },{ 0x0389,'H' },{ 0x038A,'I' },
		/* 0x038B */{ 0x038C,'O' },/* 0x038D */{ 0x038E,'Y' },{ 0x038F,'V' },
			// Dialytica and tonos
		{ 0x0390,'i' },
			// Capitals
		{ 0x0391,'A' },{ 0x0392,'B' },{ 0x0393,'G' },{ 0x0394,'D' },{ 0x0395,'E' },
		{ 0x0396,'Z' },{ 0x0397,'H' },{ 0x0398,'U' },{ 0x0399,'I' },{ 0x039A,'K' },
		{ 0x039B,'L' },{ 0x039C,'M' },{ 0x039D,'N' },{ 0x039E,'J' },{ 0x039F,'O' },
		{ 0x03A0,'P' },{ 0x03A1,'R' },{ 0x03A3,'S' },{ 0x03A4,'T' },{ 0x03A5,'Y' },
		{ 0x03A6,'F' },{ 0x03A7,'X' },{ 0x03A8,'C' },{ 0x03A9,'V' },
			// With dialytica
		{ 0x03AA,'I' },{ 0x03AB,'Y' },
			// With tonos
		{ 0x03AC,'a' },{ 0x03AD,'e' },{ 0x03AE,'h' },{ 0x03AF,'i' },
			// Dialytica and tonos
		{ 0x03B0,'y' },
			// Smalls
		{ 0x03B1,'a' },{ 0x03B2,'b' },{ 0x03B3,'g' },{ 0x03B4,'d' },{ 0x03B5,'e' },
		{ 0x03B6,'z' },{ 0x03B7,'h' },{ 0x03B8,'u' },{ 0x03B9,'i' },{ 0x03BA,'k' },
		{ 0x03BB,'l' },{ 0x03BC,'m' },{ 0x03BD,'n' },{ 0x03BE,'j' },{ 0x03BF,'o' },
		{ 0x03C0,'p' },{ 0x03C1,'r' },{ 0x03C3,'s' },{ 0x03C4,'t' },{ 0x03C5,'y' },
		{ 0x03C6,'f' },{ 0x03C7,'x' },{ 0x03C8,'c' },{ 0x03C9,'v' },
			// With dialytica
		{ 0x03CA,'i' },{ 0x03CB,'y' },
			// With tonos
		{ 0x03CC,'o' },{ 0x03CD,'y' },{ 0x03CE,'v' }
	];
	
	// Same for russian keyboards
	static immutable stIntCodePairs RussianKeyboard[]=
	[
		{ 0x0410,'F' },{ 0x0411,'<' },{ 0x0412,'D' },{ 0x0413,'U' },{ 0x0414,'l' },
		{ 0x0415,'T' },{ 0x0416,':' },{ 0x0417,'P' },{ 0x0418,'B' },{ 0x0419,'Q' },
		{ 0x041a,'R' },{ 0x041b,'k' },{ 0x041c,'V' },{ 0x041d,'Y' },{ 0x041e,'J' },
		{ 0x041f,'G' },{ 0x0420,'H' },{ 0x0421,'C' },{ 0x0422,'N' },{ 0x0423,'E' },
		{ 0x0424,'A' },{ 0x0425,'{' },{ 0x0426,'W' },{ 0x0427,'X' },{ 0x0428,'I' },
		{ 0x0429,'O' },{ 0x042a,']' },{ 0x042b,'S' },{ 0x042c,'M' },{ 0x042d,'"' },
		{ 0x042e,'>' },{ 0x042f,'Z' },{ 0x0430,'f' },{ 0x0431,',' },{ 0x0432,'d' },
		{ 0x0433,'u' },{ 0x0434,'L' },{ 0x0435,'t' },{ 0x0436,';' },{ 0x0437,'p' },
		{ 0x0438,'b' },{ 0x0439,'q' },{ 0x043a,'r' },{ 0x043b,'K' },{ 0x043c,'v' },
		{ 0x043d,'y' },{ 0x043e,'j' },{ 0x043f,'g' },{ 0x0440,'h' },{ 0x0441,'c' },
		{ 0x0442,'n' },{ 0x0443,'e' },{ 0x0444,'a' },{ 0x0445,'[' },{ 0x0446,'w' },
		{ 0x0447,'x' },{ 0x0448,'i' },{ 0x0449,'o' },{ 0x044a,'}' },{ 0x044b,'s' },
		{ 0x044c,'m' },{ 0x044d,'\'' },{ 0x044e,'.' },{ 0x044f,'z' }
	];
	
	/*
	static int defaultSetCodePage(int id)
	{
		switch (id)
		{
			case TVCodePage.PC855:
			case TVCodePage.PC866:
			case TVCodePage.ISORussian:
			case TVCodePage.KOI8r:
			case TVCodePage.KOI8_CRL_NMSU:
			case TVCodePage.CP1251:
			case TVCodePage.MacCyr:
			case TVCodePage.MacOSUkrainian:
				// Not sure about the rest of russian code pages.
				FillKeyMapForCP(id,RussianKeyboard);
				NonASCII2ASCII = &Generic_NonASCII2ASCII;
				CompareASCII = &Generic_CompareASCII;
				AltInternat2ASCII = &Generic_AltInternat2ASCII;
				break;
			case TVCodePage.PC737:
			case TVCodePage.PC869:
			case TVCodePage.CP1253:
			case TVCodePage.ISOGreek:
				FillKeyMapForCP(id, GreekKeyboard);
				NonASCII2ASCII = &Generic_NonASCII2ASCII;
				CompareASCII = &Generic_CompareASCII;
				AltInternat2ASCII = &Generic_AltInternat2ASCII;
				break;
			default:
				NonASCII2ASCII = &defaultNonASCII2ASCII;
				CompareASCII = &defaultCompareASCII;
				AltInternat2ASCII = &defaultAltInternat2ASCII;
				return 0;
		}
		return 1;
	}
	*/
	
	static ubyte KeyMap[128];
	
	static bool compare(in ref stIntCodePairs v1, in ref stIntCodePairs v2) {
		return ((v1.unicode > v2.unicode) - (v1.unicode < v2.unicode)) == 0;
	}
	
/**[txh]********************************************************************

  Description:
  Fills the KeyMap table using the provided keyboard layout.
  
***************************************************************************/
	/*
	static void FillKeyMapForCP(int id, in stIntCodePairs[] keyboard)
	{
		stIntCodePairs[256] cp;
		TVCodePage.GetUnicodesForCP(id, cp);
		ushort[] tr = TVCodePage.GetTranslate(id);
		for (ubyte i=128; i<256; i++) {
			stIntCodePairs s;
			s.unicode = TVCodePage.UnicodeForInternalCode(tr[i]);
			// void *res=bsearch(&s,keyboard,szKb,sizeof(stIntCodePairs),compare);
			auto founds = keyboard.find!compare(s);
			KeyMap[i-128] = cast(ubyte)(founds.length > 0 ? founds[0].code : i);
		}
	}*/
	
	static ubyte Generic_NonASCII2ASCII(ubyte ascii)
	{
		return ascii>=0x80 ? KeyMap[ascii-0x80] : ascii;
	}
	
	static int Generic_CompareASCII(ubyte val, ubyte code)
	{
		if (val >=0x80) val =KeyMap[val- 0x80];
		if (code>=0x80) code=KeyMap[code-0x80];
		return val==code;
	}
	
	static int defaultAltInternat2ASCII(ref TEvent)
	{
		return 0;
	}
	

	const SP1 = 0x80 | KeyCode.kbH;
	const SP2 = 0x80 | KeyCode.kbI;
	const SP3 = 0x80 | KeyCode.kbJ;
	const SP4 = 0x80 | KeyCode.kbM;
	const SP5 = 0x80 | KeyCode.kbOpenBrace;

	
	static const ubyte kbByASCII[128]=
	[
		0, KeyCode.kbA, KeyCode.kbB, KeyCode.kbC, KeyCode.kbD, KeyCode.kbE, KeyCode.kbF, KeyCode.kbG, SP1,
		 SP2, SP3, KeyCode.kbK, KeyCode.kbL, SP4, KeyCode.kbN, KeyCode.kbO, KeyCode.kbP,
		 KeyCode.kbQ, KeyCode.kbR, KeyCode.kbS, KeyCode.kbT, KeyCode.kbU, KeyCode.kbV, KeyCode.kbW, KeyCode.
				kbX, KeyCode.kbY, KeyCode.kbZ, SP5, KeyCode.kbBackSlash, KeyCode.kbCloseBrace, KeyCode.kb6, KeyCode.kbMinus, KeyCode.
				kbSpace, KeyCode.kbAdmid, KeyCode.kbDobleQuote, KeyCode.kbNumeral, KeyCode.kbDolar, KeyCode.kbPercent, KeyCode.kbAmper, KeyCode.kbQuote, KeyCode.
				kbOpenPar, KeyCode.kbClosePar, KeyCode.kbAsterisk, KeyCode.kbPlus, KeyCode.kbComma, KeyCode.kbMinus, KeyCode.kbStop, KeyCode.kbSlash, KeyCode.
				kb0, KeyCode.kb1, KeyCode.kb2, KeyCode.kb3, KeyCode.kb4, KeyCode.kb5, KeyCode.kb6, KeyCode.kb7, KeyCode.
				kb8, KeyCode.kb9, KeyCode.kbDoubleDot, KeyCode.kbColon, KeyCode.kbLessThan, KeyCode.kbEqual, KeyCode.kbGreaterThan, KeyCode.kbQuestion, KeyCode.
				kbA_Roba, KeyCode.kbA, KeyCode.kbB, KeyCode.kbC, KeyCode.kbD, KeyCode.kbE, KeyCode.kbF, KeyCode.kbG, KeyCode.
				kbH, KeyCode.kbI, KeyCode.kbJ, KeyCode.kbK, KeyCode.kbL, KeyCode.kbM, KeyCode.kbN, KeyCode.kbO, KeyCode.
				kbP, KeyCode.kbQ, KeyCode.kbR, KeyCode.kbS, KeyCode.kbT, KeyCode.kbU, KeyCode.kbV, KeyCode.kbW, KeyCode.
				kbX, KeyCode.kbY, KeyCode.kbZ, KeyCode.kbOpenBrace, KeyCode.kbBackSlash, KeyCode.kbCloseBrace, KeyCode.kbCaret, KeyCode.kbUnderLine, KeyCode.
				kbGrave, KeyCode.kbA, KeyCode.kbB, KeyCode.kbC, KeyCode.kbD, KeyCode.kbE, KeyCode.kbF, KeyCode.kbG, KeyCode.
				kbH, KeyCode.kbI, 
		 KeyCode.kbJ, KeyCode.kbK, KeyCode.kbL, KeyCode.kbM, KeyCode.kbN, 
		 KeyCode.kbO, KeyCode.kbP, KeyCode.kbQ, KeyCode.kbR, KeyCode.kbS, 
		 KeyCode.kbT, KeyCode.kbU, KeyCode.kbV, KeyCode.kbW, KeyCode.kbX, 
		 KeyCode.kbY, KeyCode.kbZ, KeyCode.kbOpenCurly, KeyCode.kbOr, 
		 KeyCode.kbCloseCurly, KeyCode.kbTilde, KeyCode.kbBackSpace
	];
	
/**[txh]********************************************************************

  Description:
  When using a "non-ASCII" keyboard the application gets Alt+Non-ASCII. This
routine tries to figure out which key was used and changes the event to
be Alt+ASCII. Example: A greek keyboard can generate Alt+Alfa, in this case
the routine will convert it into Alt+A (because Alfa is in the key that A
is located).
  
  Return: !=0 if the event was altered.
  
***************************************************************************/
	
	static int Generic_AltInternat2ASCII(ref TEvent e)
	{
		if (e.what==evKeyDown &&
		    e.keyDown.charScan.charCode>=0x80 &&
		    (e.keyDown.keyCode & (KeyCode.kbAltRCode | KeyCode.kbAltLCode)) &&
		    (e.keyDown.keyCode & KeyCode.kbKeyMask) == KeyCode.kbUnkNown)
		{
			ubyte key=KeyMap[e.keyDown.charScan.charCode-0x80];
			if (key<0x80)
			{
				e.keyDown.keyCode|=kbByASCII[key];
				return 1;
			}
		}
		return 0;
	}
	
/**[txh]********************************************************************

  Description:
  Used by objects that needs the TEvent.keyDown.charCode filled.
  
***************************************************************************/
	
	static void defaultFillCharCode(ref TEvent e) {
		if (e.keyDown.charCode!=0xFFFFFFFF && e.keyDown.charScan.charCode)
			e.keyDown.charCode = e.keyDown.charScan.charCode;
	}
	

}
