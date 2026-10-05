@echo off
rem Compile src\ into bin\NewRealm.swf using the AIR SDK.
rem Usage: set AIR_SDK=C:\AIRSDK  then  build.bat
if "%AIR_SDK%"=="" ( echo Please set AIR_SDK to your AIR SDK folder, e.g.  set AIR_SDK=C:\AIRSDK & exit /b 1 )
cd /d "%~dp0"
if not exist bin mkdir bin
call "%AIR_SDK%\bin\amxmlc" -source-path=src -default-size=800,600 -output=bin\NewRealm.swf src\NewRealm.as || exit /b 1
echo Built bin\NewRealm.swf
