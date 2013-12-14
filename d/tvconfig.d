module tvconfig;

const int eventQSize = 16;
const int maxCollectionSize = uint.max/(void*).sizeof;

// May be I'll remove that sometimes
version(TVOS_DOS) {
	const int maxViewWidth = 132;
} else {
	const int maxViewWidth = 1024;
}

const int maxFindStrLen    = 80;
const int maxReplaceStrLen = 80;