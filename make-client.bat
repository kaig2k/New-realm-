@echo off
rem Double-click this to make the Eldmere desktop app for players (dist\Eldmere.zip).
rem It builds the launcher pointed at the Eldmere server, then packages it with its own AIR runtime.
rem Needs Java and the AIR SDK (see DEPLOY.md, "A desktop app").
cd /d "%~dp0"
call build.bat 37.27.146.35:2050
if errorlevel 1 goto fail
if not exist bin\EldmereLauncher.swf goto fail
call package-client.bat
exit /b 0

:fail
echo.
echo Something went wrong above. Take a screenshot of this window and send it over.
pause
exit /b 1
