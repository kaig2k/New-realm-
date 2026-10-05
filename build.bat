@echo off
setlocal
rem Compile src\ into bin\NewRealm.swf using the AIR SDK's amxmlc (needs Java).
cd /d "%~dp0"
call "%~dp0findsdk.bat"
if errorlevel 1 goto fail
if not exist bin mkdir bin
call "%AIR_SDK%\bin\amxmlc" -source-path=src -output=bin\NewRealm.swf src\NewRealm.as || goto fail
echo Built bin\NewRealm.swf
exit /b 0

:fail
echo.
pause
exit /b 1
