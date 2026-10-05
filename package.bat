@echo off
rem Package a standalone Windows app (captive runtime) into dist\NewRealm.
setlocal
cd /d "%~dp0"
call "%~dp0findsdk.bat"
if errorlevel 1 goto fail
if not exist cert.p12 call "%AIR_SDK%\bin\adt" -certificate -cn NewRealm 2048-RSA cert.p12 newrealm
if not exist dist mkdir dist
call "%AIR_SDK%\bin\adt" -package -storetype pkcs12 -keystore cert.p12 -storepass newrealm -target bundle dist\NewRealm NewRealm-app.xml -C bin NewRealm.swf || goto fail
echo Packaged into dist\NewRealm  (run dist\NewRealm\NewRealm.exe)
pause
exit /b 0

:fail
echo.
pause
exit /b 1
