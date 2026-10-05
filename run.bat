@echo off
rem Launch the game with the AIR Debug Launcher.
if "%AIR_SDK%"=="" ( echo Please set AIR_SDK to your AIR SDK folder, e.g.  set AIR_SDK=C:\AIRSDK & exit /b 1 )
cd /d "%~dp0"
"%AIR_SDK%\bin\adl" NewRealm-app.xml bin
