module osclipboard;

struct TVOSClipboard {

	static string name = "None";
	static int available;
	static int error;
	static int errors;
	static string[] nameErrors;
	static int function(int id, in char[] buffer) copy;
	static string function(int id) paste;
	static void  function() destroy;

	~this() { if (destroy) destroy(); };

	static string getName() { return name; };
	static int     isAvailable() { return available; };

	static void    clearError() { error=0; };
}

