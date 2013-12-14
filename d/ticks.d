module ticks;

/* Copyright (C) 1996-1998 Robert H”hne */
/* Modified by Salvador E. Tropea, Vadim Bolodorov and Anatoli Soltan */
import tvconfig;

version(TVCompf_djgpp) {
	//#include <sys/farptr.h>
	//#include <go32.h>

	ushort CLY_Ticks() {
		return _farpeekw(_dos_ds,0x46c);
	}
} else version (TVOS_Win32) {
	version = WIN32_LEAN_AND_MEAN;
	import core.sys.windows.windows;;
	
	ushort CLY_Ticks() {
		//  X ms * 1s/1000ms * 18.2 ticks/s = X/55 ticks, roughly.
		return cast(ushort)(GetTickCount() / 55);
	}
} else version (TVOS_UNIX) {
	//#include <sys/time.h>
	//#include <stdio.h> /* for NULL */
	
	ushort  CLY_Ticks() {
		timeval val;
		gettimeofday(&val,cast(timezone *)null);
		return (val.tv_sec*18 + (val.tv_usec*18)/1000000);
		//  return clock();
	}
}