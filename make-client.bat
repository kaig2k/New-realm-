@echo off
rem Double-click this to make the Eldmere desktop app for players (dist\Eldmere.zip).
rem It builds the launcher pointed at the Eldmere server, then packages it with its own AIR runtime.
rem Needs Java and the AIR SDK (see DEPLOY.md, "A desktop app").
rem Everything it prints is also saved in make-client-log.txt (send that file if something goes wrong).
cd /d "%~dp0"
set LOG=%~dp0make-client-log.txt
echo Making the Eldmere app... (this takes a minute)
echo Eldmere app build, %DATE% %TIME% > "%LOG%"
call findsdk.bat >> "%LOG%" 2>&1
echo AIR SDK: %AIR_SDK% >> "%LOG%"
java -version >> "%LOG%" 2>&1 || echo JAVA NOT FOUND: install it from https://adoptium.net >> "%LOG%"
echo. >> "%LOG%"
echo ---- build ---- >> "%LOG%"
call build.bat 37.27.146.35:2050 < nul >> "%LOG%" 2>&1
if not exist bin\EldmereLauncher.swf goto fail
echo. >> "%LOG%"
echo ---- package ---- >> "%LOG%"
call package-client.bat < nul >> "%LOG%" 2>&1
if not exist dist\Eldmere\Eldmere.exe goto fail
type "%LOG%"
echo.
echo Done! Your app is dist\Eldmere\Eldmere.exe, and dist\Eldmere.zip is the file to give players.
pause
exit /b 0

:fail
type "%LOG%"
echo.
echo Something went wrong. Send the file make-client-log.txt (in this folder), or a screenshot of this window.
pause
exit /b 1
