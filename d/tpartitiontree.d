module tpartitiontree;

class TVPartitionTree556 {
	private ushort[][][] base;
	debug {
		private int    tables, blocks;
	}
	
	this() {
		base = new ushort[][][32];
		debug {
			tables=blocks=0;
		}
	}

	void add(uint unicode, ushort code) {
		int index1 = unicode>>11;
		int index2 = (unicode>>6) & 0x1F;
		ushort[][] t = base[index1];
		ushort[] l;
		if (t !is null) {
			l = t[index2];
			if (l is null) {
				l = t[index2] = new ushort[64];
				l[] = 0xFF; //memset(l,0xFF,128);
				blocks++;
			}
		} else {
			t = base[index1] = new ushort[][32];
			//memset(t,0,sizeof(ushort *)*32);
			l = t[index2] = new ushort[64];
			l[] = 0xFF; //memset(l,0xFF,128);
			tables++;
			blocks++;
		}
		l[unicode & 0x3F] = code;
	}
	
	ushort search(uint unicode) {
		ushort[][] t = base[unicode>>11];
		if (t is null) 
			return 0xFFFF;
		ushort[] l = t[(unicode>>6) & 0x1F];
		if (l is null)
			return 0xFFFF;
		return l[unicode & 0x3F];
	}
	

}

