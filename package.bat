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
call "%AIR_SDK%\bin\adt" -package -storetype pkcs12 -keystore cert.p12 -storepass newrealm -target bundle dist\NewRealm NewRealm-app.xml -C bin NewRealm.swf || goto fail
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
