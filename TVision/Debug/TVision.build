set PATH=D:\D\dmd\dmd2\windows\\bin;C:\Program Files\Microsoft SDKs\Windows\v7.1\\\bin;%PATH%

echo ..\d\win32\win32clip.d >Debug\TVision.build.rsp
echo ..\d\win32\win32key.d >>Debug\TVision.build.rsp
echo ..\d\win32\win32mouse.d >>Debug\TVision.build.rsp
echo ..\d\win32\win32scr.d >>Debug\TVision.build.rsp
echo ..\d\budget.d >>Debug\TVision.build.rsp
echo ..\d\codepage.d >>Debug\TVision.build.rsp
echo ..\d\commands.d >>Debug\TVision.build.rsp
echo ..\common.d >>Debug\TVision.build.rsp
echo ..\d\configfile.d >>Debug\TVision.build.rsp
echo ..\d\grid.d >>Debug\TVision.build.rsp
echo ..\d\main.d >>Debug\TVision.build.rsp
echo ..\msgbox.d >>Debug\TVision.build.rsp
echo ..\d\osclipboard.d >>Debug\TVision.build.rsp
echo ..\progressbar.d >>Debug\TVision.build.rsp
echo ..\d\tapplication.d >>Debug\TVision.build.rsp
echo ..\d\tasklist.d >>Debug\TVision.build.rsp
echo ..\d\tbackground.d >>Debug\TVision.build.rsp
echo ..\tbutton.d >>Debug\TVision.build.rsp
echo ..\tcheckboxes.d >>Debug\TVision.build.rsp
echo ..\tcluster.d >>Debug\TVision.build.rsp
echo ..\d\tcollection.d >>Debug\TVision.build.rsp
echo ..\d\tcommand.d >>Debug\TVision.build.rsp
echo ..\d\tdesktop.d >>Debug\TVision.build.rsp
echo ..\tdialog.d >>Debug\TVision.build.rsp
echo ..\d\tdisplay.d >>Debug\TVision.build.rsp
echo ..\d\tdrawbuffer.d >>Debug\TVision.build.rsp
echo ..\d\teditor.d >>Debug\TVision.build.rsp
echo ..\d\tevent.d >>Debug\TVision.build.rsp
echo ..\d\teventqueue.d >>Debug\TVision.build.rsp
echo ..\d\tfiledialog.d >>Debug\TVision.build.rsp
echo ..\d\tfileinfopane.d >>Debug\TVision.build.rsp
echo ..\d\tfilelist.d >>Debug\TVision.build.rsp
echo ..\tframe.d >>Debug\TVision.build.rsp
echo ..\d\tgkey.d >>Debug\TVision.build.rsp
echo ..\d\tgroup.d >>Debug\TVision.build.rsp
echo ..\d\thistory.d >>Debug\TVision.build.rsp
echo ..\d\thistoryviewer.d >>Debug\TVision.build.rsp
echo ..\d\thistorywindow.d >>Debug\TVision.build.rsp
echo ..\d\ticks.d >>Debug\TVision.build.rsp
echo ..\tinputline.d >>Debug\TVision.build.rsp
echo ..\tlabel.d >>Debug\TVision.build.rsp
echo ..\d\tlistbox.d >>Debug\TVision.build.rsp
echo ..\d\tlistviewer.d >>Debug\TVision.build.rsp
echo ..\d\tmenu.d >>Debug\TVision.build.rsp
echo ..\d\tobject.d >>Debug\TVision.build.rsp
echo ..\d\tpalette.d >>Debug\TVision.build.rsp
echo ..\d\tpartitiontree.d >>Debug\TVision.build.rsp
echo ..\d\tpoint.d >>Debug\TVision.build.rsp
echo ..\d\tprogram.d >>Debug\TVision.build.rsp
echo ..\tradiobuttons.d >>Debug\TVision.build.rsp
echo ..\d\trect.d >>Debug\TVision.build.rsp
echo ..\d\tscreen.d >>Debug\TVision.build.rsp
echo ..\tscrollbar.d >>Debug\TVision.build.rsp
echo tscroller.d >>Debug\TVision.build.rsp
echo ..\tsitem.d >>Debug\TVision.build.rsp
echo ..\d\tsortedcollection.d >>Debug\TVision.build.rsp
echo ..\d\tsortedlistbox.d >>Debug\TVision.build.rsp
echo ..\tstatictext.d >>Debug\TVision.build.rsp
echo tstatusline.d >>Debug\TVision.build.rsp
echo ..\d\tstreamable.d >>Debug\TVision.build.rsp
echo ..\d\tstringcollection.d >>Debug\TVision.build.rsp
echo ..\d\ttypes.d >>Debug\TVision.build.rsp
echo ..\tvalidator.d >>Debug\TVision.build.rsp
echo ..\d\tvconfig.d >>Debug\TVision.build.rsp
echo ..\d\tview.d >>Debug\TVision.build.rsp
echo ..\d\tvision.d >>Debug\TVision.build.rsp
echo ..\twindow.d >>Debug\TVision.build.rsp
echo ..\d\views.d >>Debug\TVision.build.rsp

dmd -g -de -unittest -debug -cov -X -Xf"Debug\TVision.json" -Id:\D\projects\tvision\d\ -version=TVOS_Win32 -deps="Debug\TVision.dep" -c -of"Debug\TVision.obj" @Debug\TVision.build.rsp
if errorlevel 1 goto reportError

set LIB=
echo. > Debug\TVision.build.lnkarg
echo "Debug\TVision.obj","Debug\TVision.exe_cv","Debug\TVision.map",user32.lib+ >> Debug\TVision.build.lnkarg
echo kernel32.lib/NOMAP/CO/NOI >> Debug\TVision.build.lnkarg

"d:\d\VisualD\pipedmd.exe" -deps Debug\TVision.lnkdep link.exe @Debug\TVision.build.lnkarg
if errorlevel 1 goto reportError
if not exist "Debug\TVision.exe_cv" (echo "Debug\TVision.exe_cv" not created! && goto reportError)
echo Converting debug information...
"d:\d\VisualD\cv2pdb\cv2pdb.exe" "Debug\TVision.exe_cv" "Debug\TVision.exe"
if errorlevel 1 goto reportError
if not exist "Debug\TVision.exe" (echo "Debug\TVision.exe" not created! && goto reportError)

goto noError

:reportError
echo Building Debug\TVision.exe failed!

:noError
