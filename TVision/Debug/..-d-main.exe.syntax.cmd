set PATH=D:\D\dmd\dmd2\windows\bin;C:\Program Files\Microsoft SDKs\Windows\v7.1\\bin;%PATH%
echo Compiling ..\d\main.d...
"C:\Program Files (x86)\VisualD\pipedmd.exe" rdmd -g -de -unittest -debug -X -Xf"Debug\..-d-main.json" -version=TVOS_Win32 -of"Debug\..-d-main.exe_cv" -map "Debug\TVision.map" -L/NOMAP -unittest -cov --main ..\d\main.d
:reportError
if errorlevel 1 echo Building Debug\..-d-main.exe failed!
if not errorlevel 1 echo Compilation successful.
