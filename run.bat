@echo off
setlocal
rem Launch New Realm with the AIR Debug Launcher (adl).
rem Double-click this file, or run it from a Command Prompt.
cd /d "%~dp0"

if not exist "bin\NewRealm.swf" (
	echo Could not find bin\NewRealm.swf next to this script.
	echo Make sure you unzipped the whole game folder and are running run.bat from inside it.
	goto fail
)
call "%~dp0findsdk.bat"
if errorlevel 1 goto fail

echo Using AIR SDK: %AIR_SDK%
echo Starting New Realm...
"%AIR_SDK%\bin\adl.exe" NewRealm-app.xml bin
if errorlevel 1 (
	echo.
	echo The AIR launcher exited with an error ^(code %errorlevel%^).
	echo Copy the message above if you need help.
	goto fail
)
exit /b 0

:fail
echo.
pause
exit /b 1
