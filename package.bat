@echo off
rem Package a standalone Windows app (captive runtime) into dist\NewRealm.
setlocal
cd /d "%~dp0"
call "%~dp0findsdk.bat"
if errorlevel 1 goto fail
if not exist cert.p12 call "%AIR_SDK%\bin\adt" -certificate -cn NewRealm 2048-RSA cert.p12 newrealm
if not exist dist mkdir dist
rem adt won't overwrite an old bundle
if exist dist\NewRealm rmdir /s /q dist\NewRealm
rem the app description must be for at least the AIR version the game was compiled for
set SWFVER=
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('bin\NewRealm.swf'); [Math]::Max(32, [int]$b[3])"`) do set SWFVER=%%V
if "%SWFVER%"=="" set SWFVER=32
powershell -NoProfile -Command "(Get-Content 'NewRealm-app.xml') -replace 'application/32\.0', 'application/%SWFVER%.0' | Set-Content 'dist\NewRealm-app.xml'" || goto fail
call "%AIR_SDK%\bin\adt" -package -storetype pkcs12 -keystore cert.p12 -storepass newrealm -target bundle dist\NewRealm dist\NewRealm-app.xml -C bin NewRealm.swf || goto fail
echo Packaged into dist\NewRealm  (run dist\NewRealm\NewRealm.exe)
rem zip it up so it's easy to send to friends
if exist dist\NewRealm.zip del dist\NewRealm.zip
powershell -NoProfile -Command "Compress-Archive -Path 'dist\NewRealm' -DestinationPath 'dist\NewRealm.zip'" && echo Zipped into dist\NewRealm.zip - send this to your friends.
pause
exit /b 0

:fail
echo.
pause
exit /b 1
