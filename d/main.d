module main;

import core.time;
import std.stdio;
import std.array;
import std.conv;
import std.algorithm;
import std.string;
import std.datetime;
import std.stream;

import tvision;

static short winNumber = 0;          // initialize window number
const int maxLineLength = maxViewWidth+1;
const int maxLines      = 100;

import tasklist;

struct DialogData {
	int checkBoxData;
	int radioButtonData;
	string inputData;
}

DialogData demoData;


class MainMenu : TWindow {

	this(TRect bounds) {
		super(bounds, "Danki", ++winNumber);
		TRect rr = getClipRect();    // get exposed area
		rr.grow(-1, -1);             // make interior fit inside window frame

		TScrollBar vScrollBar =
			standardScrollBar( sbVertical | sbHandleKeyboard );
		TScrollBar hScrollBar =
			standardScrollBar( sbHorizontal |  sbHandleKeyboard );

	}

	override void handleEvent(ref TEvent event) {
		super.handleEvent(event); 
		bool itemSelected = event.what == evBroadcast && event.message.command == cm.ListItemSelected;
		// clearEvent( event );
	}

	override ref immutable(TPalette) getPalette() const {
	    return tdialog.palette1;
	}

}

class Demo : TApplication  {
	

	MainMenu window;

	this() {
		demoData.checkBoxData = 1;
		demoData.inputData = "Task name";
		demoData.radioButtonData = 2;

		window = new MainMenu (TRect(0, 0, 30, 20));
		deskTop.insert(window); // put window into desktop and draw it
	}

	override void idle() {
		super.idle();
		//timeSinceStart = cast(DateTime)std.datetime.Clock.currTime() - timeTaskStarted;
	}

	override TStatusLine createStatusLine(TRect r) const {
    	r.a.y = r.b.y - 1;
    	return new TStatusLine( r,
							   [TStatusDef( 0, 0xFFFF, [
								   TStatusItem( "~Alt-X~ Exit", KeyCode.kbAltX, cm.Quit ),
								   TStatusItem( "~Ctrl-N~ New", KeyCode.kbCtrlN, cm.NewTask ),
								TStatusItem( "~Ctrl-S~ New subtask", KeyCode.kbCtrlS, cm.NewSubTask ),
								   TStatusItem( "~Ctrl-S~ Start/Stop", KeyCode.kbCtrlS, cm.Start ),
							   ]
										   )]);
	}

	override TMenuBar createMenuBar( TRect r ) const {
		r.b.y = r.a.y + 1;    // set bottom line 1 line below top line
		TSubMenu file = new TSubMenu( "~F~ile", KeyCode.kbAltF );
		file.add(new TMenuItem( "~A~bout",  cm.About,   KeyCode.kbF1, hcNoContext, "F1" ));
		file.add(new TMenuItem( "~O~pen", cm.MyFileOpen, KeyCode.kbF3, hcNoContext, "F3" ));
		file.add(new TMenuItem( "~N~ew",  cm.MyNewWin,   KeyCode.kbF4, hcNoContext, "F4" ));
		file.add(TMenuItem.newLine());
		file.add(new TMenuItem( "E~x~it", cm.Quit, KeyCode.kbAltX, hcNoContext, "Alt-X" ));
	
		TSubMenu win = new TSubMenu( "~W~indow", KeyCode.kbAltW );
		win.add(new TMenuItem( "~N~ext", cm.Next,     KeyCode.kbF6, 0x1FFFF, "F6" ));
		win.add(new TMenuItem( "~Z~oom", cm.Zoom,     KeyCode.kbF5, hcNoContext, "F5" ));

		TSubMenu progrbar = new TSubMenu( "~P~rogressBar", KeyCode.kbAltW );
		win.add(new TMenuItem( "~N~ext", cm.Next,     KeyCode.kbF6, 0x1FFFF, "F6" ));
		win.add(new TMenuItem( "~Z~oom", cm.Zoom,     KeyCode.kbF5, hcNoContext, "F5" ));

		file.add(win);
		file.add(new TMenuItem("~P~rogress Bar", cm.StatusCmd, KeyCode.kbAltL, hcNoContext));
		return new TMenuBar(r, file);
	}

	override void handleEvent(ref TEvent event) {
		super.handleEvent(event); 
		if( event.what == evCommand ) {
			if (event.message.command == cm.NewTask) {
			} else if (event.message.command == cm.NewSubTask) {
			} else {
				return;
			}
			clearEvent( event );
        }
	}


	private void newFileDialog() {
			TFileDialog pd = new TFileDialog( "*","Open a File", "~N~ame", fdOpenButton, 100 );
			Command control = deskTop.execView( pd );
			if (control != cm.Cancel) {
				myNewWindow(pd.getFileName());
			}
			return;
	}

	private void newTaskDialog() {
		TDialog pd = new TDialog( TRect( 20, 6, 120, 40), "New Task" );
		if( pd is null) 
			return;
		TView b = new TCheckBoxes( TRect( 3, 3, 16, 6),
									  new TSItem( "~H~varti",
												 new TSItem( "~T~ilset",
															new TSItem( "~J~arlsberg", null ))));
			pd.insert( b );

			pd.insert( new TLabel( TRect( 2, 2, 10, 3), "Cheeses", b ));

			//b = new TRadioButtons( TRect( 22, 3, 34, 6),
			//				  new TSItem( "~S~olid",
			//						 new TSItem( "~R~unny",
			//								new TSItem( "~M~elted", 0 )
			//								)));
			//pd.insert( b );

			pd.insert( new TLabel( TRect( 21, 2, 33, 3), "Consistency", b ));

			pd.insert( new TButton( TRect( 15, 10, 25, 12 ), "~O~K", cm.Ok,
								   bfDefault ));
			pd.insert( new TButton( TRect( 28, 10, 38, 12 ), "~C~ancel", cm.Cancel,
								   bfNormal ));

			b = new TRadioButtons( TRect( 22, 3, 34, 6),
								  new TSItem( "~S~olid",
											 new TSItem( "~R~unny",
														new TSItem( "~M~elted", null )
															)));
			pd.insert( b );

			TInputLine inp = new TInputLine( TRect( 3, 8, 37, 9 ), 128 );
			//inp.setValidator(data => data[data.length-1] == 'a');
			pd.insert( inp );
			pd.insert( new TLabel( TRect( 2, 7, 24, 8 ), "Task name:", b ));

			TScrollBar sb = new TScrollBar( TRect( 30, 13, 31, 20 ) );
			pd.insert( sb );
			pd.insert( new TLabel( TRect( 2, 12, 24, 13 ), "Parent:", b ));
		
			pd.setData(cast(void*)&demoData);
			inp.setState(sfFocused, true);
			Command control = deskTop.execView( pd );
			if (control != cm.Cancel) {
				pd.getData(cast(void*)&demoData);
			}
	}


	void myNewWindow(string fileName) {
		TRect r = TRect( 0, 0, 26, 7 );           // set initial size and position

		/* SS: micro change here */

		//r.move( random(53), random(16) ); // randomly move around screen
		//r.move( random() % 53, random() % 16 ); // randomly move around screen
		


		auto topMenuWin = new MenuWindow(TRect(0, 0, 19, 7));
		auto topMenuWinItems = new TRadioButtons( TRect( 1, 1, 18, 4),
							  new TSItem( "~B~udget",
								new TSItem( "~R~eports",
									new TSItem( "~A~ll accounts", null )
										)));
		topMenuWin.insert( topMenuWinItems );
		deskTop.insert(topMenuWin);


		import budget;
		Category cat = Category("TestCategory");
		Persely persely = Persely("Malac");
		User user = User([persely], [cat]);
		TSItem* createAccountMenuChain(int perselyIndex) {
			if (perselyIndex >= user.perselyek.length) {
				return null;
			}
			auto persely = user.perselyek[perselyIndex];
			return new TSItem(persely.name, createAccountMenuChain(perselyIndex + 1));
		}
		auto budgetAccountsWin = new MenuWindow(TRect(0, 9, 19, 19), "Budget accounts");
		int accountListHeight = 1 + user.perselyek.length;
		auto accountItems = new TRadioButtons(TRect( 1, 1, 18, accountListHeight), createAccountMenuChain(0));
		budgetAccountsWin.insert(accountItems);
		auto addAccountBtn = new TButton(1, accountListHeight, "+ Add account", cm.Null, bfDefault);
		budgetAccountsWin.insert(addAccountBtn);
		deskTop.insert(budgetAccountsWin);
	}
};

class MenuWindow : TWindow {

	this(in TRect bounds, string name = null) {
		super(bounds, name, 0);
		flags =  0;
		state = sfVisible;
	    options |= ofSelectable | ofTopSelect;
	    growMode = gfGrowAll | gfGrowRel;
	    eventMask |= evMouseUp;
	}

	override ref immutable(TPalette) getPalette() const {
	    return tdialog.palette1;
	}
}

void main() {
	Demo a = new Demo();
	a.run();
	std.stream.File file = new std.stream.File("tasks.db", FileMode.OutNew);
	auto data = new Elem("Tasks");
	//data.taskId.set(taskId);
	//tree.write(data);
	auto str = data.toString();
	file.write(str);
	file.close();
}