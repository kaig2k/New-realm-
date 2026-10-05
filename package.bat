@echo off
rem Package a standalone Windows app (captive runtime) into dist\NewRealm.
if "%AIR_SDK%"=="" ( echo Please set AIR_SDK to your AIR SDK folder, e.g.  set AIR_SDK=C:\AIRSDK & exit /b 1 )
cd /d "%~dp0"
if not exist cert.p12 call "%AIR_SDK%\bin\adt" -certificate -cn NewRealm 2048-RSA cert.p12 newrealm
if not exist dist mkdir dist
call "%AIR_SDK%\bin\adt" -package -storetype pkcs12 -keystore cert.p12 -storepass newrealm -target bundle dist\NewRealm NewRealm-app.xml -C bin NewRealm.swf || exit /b 1
echo Packaged into dist\NewRealm  (run dist\NewRealm\NewRealm.exe)
