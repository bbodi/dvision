module commands;

struct Command {
	private string name;

	bool someOfThem(in Command[] cmds...) {
		foreach(ref cmd; cmds) {
			if (cmd == this) {
				return true;
			}
		}
		return false;
	}

}

struct cm {

    template opDispatch(string name) {
		enum opDispatch = Command(name);
    }

}