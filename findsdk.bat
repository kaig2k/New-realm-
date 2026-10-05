@echo off
rem Finds the AIR SDK and sets AIR_SDK (used by run.bat, build.bat and package.bat).
rem Uses %AIR_SDK% if already set, then airsdk.txt, then common install folders.
if defined AIR_SDK if exist "%AIR_SDK%\bin\adl.exe" exit /b 0
set "AIR_SDK="

rem A path saved in airsdk.txt (one line, e.g. C:\AIRSDK) wins over the search.
if exist "%~dp0airsdk.txt" (
	set /p AIR_SDK=<"%~dp0airsdk.txt"
)
if defined AIR_SDK if exist "%AIR_SDK%\bin\adl.exe" exit /b 0
set "AIR_SDK="

for %%D in ("C:\AIRSDK" "%USERPROFILE%\AIRSDK" "%USERPROFILE%\Downloads\AIRSDK" "%~dp0AIRSDK" "%~dp0..\AIRSDK") do (
	if exist "%%~D\bin\adl.exe" set "AIR_SDK=%%~D"
)
if defined AIR_SDK exit /b 0
for /d %%D in ("C:\AIRSDK*" "%USERPROFILE%\AIRSDK*" "%USERPROFILE%\Downloads\AIRSDK*" "%USERPROFILE%\Downloads\AIRSDK*\AIRSDK*" "%USERPROFILE%\Desktop\AIRSDK*" "%ProgramFiles%\AIRSDK*" "%~dp0..\AIRSDK*") do (
	if exist "%%~D\bin\adl.exe" set "AIR_SDK=%%~D"
)
if defined AIR_SDK exit /b 0

echo Could not find the AIR SDK.
echo.
echo 1. Download the HARMAN AIR SDK for Windows from https://airsdk.harman.io/
echo 2. Unzip it to C:\AIRSDK  (so that C:\AIRSDK\bin\adl.exe exists)
echo    - or put the folder path in a file called airsdk.txt next to run.bat
echo 3. Double-click run.bat again.
exit /b 1

